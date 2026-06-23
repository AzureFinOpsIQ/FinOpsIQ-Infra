terraform {
  required_version = ">= 1.6.0"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.0"
    }
  }
}

provider "azurerm" {
  subscription_id     = var.subscription_id
  tenant_id           = var.tenant_id
  storage_use_azuread = true

  features {}
}

locals {
  common_tags = merge(
    {
      Environment = var.environment
      Owner       = var.owner
    },
    var.extra_tags
  )

  workload_identity_subjects = {
    for key, service_account in var.workload_service_accounts :
    key => "system:serviceaccount:${var.helm_namespace}:${service_account}"
  }
}

module "resource_group" {
  source   = "../../modules/resource-group"
  name     = var.resource_group_name
  location = var.location
  tags     = local.common_tags
}

module "network" {
  source                  = "../../modules/network"
  name                    = var.network.name
  resource_group_name     = module.resource_group.name
  location                = module.resource_group.location
  address_space           = var.network.address_space
  subnets                 = var.network.subnets
  network_security_groups = var.network.network_security_groups
  nat_gateways            = var.network.nat_gateways
  private_dns_zones       = var.network.private_dns_zones
  tags                    = local.common_tags
}

module "monitor" {
  source              = "../../modules/monitor"
  name                = var.monitor.name
  resource_group_name = module.resource_group.name
  location            = module.resource_group.location
  sku                 = var.monitor.sku
  retention_in_days   = var.monitor.retention_in_days
  tags                = local.common_tags
}

module "application_insights" {
  source              = "../../modules/application-insights"
  name                = var.application_insights.name
  resource_group_name = module.resource_group.name
  location            = module.resource_group.location
  workspace_id        = module.monitor.id
  application_type    = var.application_insights.application_type
  tags                = local.common_tags
}

module "acr" {
  source              = "../../modules/acr"
  name                = var.acr.name
  resource_group_name = module.resource_group.name
  location            = module.resource_group.location
  sku                 = var.acr.sku
  tags                = local.common_tags
}

module "bastion" {
  source              = "../../modules/bastion"
  name                = var.bastion.name
  public_ip_name      = var.bastion.public_ip_name
  resource_group_name = module.resource_group.name
  location            = module.resource_group.location
  subnet_id           = module.network.subnet_ids[var.bastion.subnet_key]
  sku                 = var.bastion.sku
  scale_units         = var.bastion.scale_units
  zones               = var.bastion.zones
  tags                = local.common_tags
}

module "management_vm" {
  source                        = "../../modules/management-vm"
  name                          = var.management_vm.name
  network_interface_name        = var.management_vm.network_interface_name
  network_security_group_name   = var.management_vm.network_security_group_name
  resource_group_name           = module.resource_group.name
  location                      = module.resource_group.location
  subnet_id                     = module.network.subnet_ids[var.management_vm.subnet_key]
  bastion_subnet_address_prefix = var.network.subnets[var.bastion.subnet_key].address_prefixes[0]
  vm_size                       = var.management_vm.vm_size
  admin_username                = var.management_vm.admin_username
  admin_password                = var.management_vm.admin_password
  os_disk_size_gb               = var.management_vm.os_disk_size_gb
  os_disk_storage_account_type  = var.management_vm.os_disk_storage_account_type
  custom_data_path              = "${path.module}/../../scripts/bootstrap-management-vm.sh"
  tags                          = local.common_tags
}

module "application_gateway" {
  source                 = "../../modules/application-gateway"
  name                   = var.application_gateway.name
  public_ip_name         = var.application_gateway.public_ip_name
  waf_policy_name        = var.application_gateway.waf_policy_name
  resource_group_name    = module.resource_group.name
  location               = module.resource_group.location
  subnet_id              = "/subscriptions/${var.subscription_id}/resourceGroups/${module.resource_group.name}/providers/Microsoft.Network/virtualNetworks/${var.network.name}/subnets/${var.network.subnets[var.application_gateway.subnet_key].name}"
  sku_name               = var.application_gateway.sku_name
  sku_tier               = var.application_gateway.sku_tier
  autoscale_min_capacity = var.application_gateway.autoscale_min_capacity
  autoscale_max_capacity = var.application_gateway.autoscale_max_capacity
  frontend_port          = var.application_gateway.frontend_port
  waf_enabled            = var.application_gateway.waf_enabled
  waf_firewall_mode      = var.application_gateway.waf_firewall_mode
  waf_rule_set_type      = var.application_gateway.waf_rule_set_type
  waf_rule_set_version   = var.application_gateway.waf_rule_set_version
  zones                  = var.application_gateway.zones
  tags                   = local.common_tags

  depends_on = [module.network]
}

module "keyvault" {
  source                        = "../../modules/keyvault"
  name                          = var.keyvault.name
  resource_group_name           = module.resource_group.name
  location                      = module.resource_group.location
  tenant_id                     = var.tenant_id
  sku_name                      = var.keyvault.sku_name
  enable_rbac_authorization     = var.keyvault.enable_rbac_authorization
  purge_protection_enabled      = var.keyvault.purge_protection_enabled
  soft_delete_retention_days    = var.keyvault.soft_delete_retention_days
  public_network_access_enabled = var.keyvault.public_network_access_enabled
  tags                          = local.common_tags
}

module "cosmosdb" {
  source                        = "../../modules/cosmosdb"
  account_name                  = var.cosmosdb.account_name
  database_name                 = var.cosmosdb.database_name
  resource_group_name           = module.resource_group.name
  location                      = module.resource_group.location
  consistency_level             = var.cosmosdb.consistency_level
  database_throughput           = var.cosmosdb.database_throughput
  containers                    = var.cosmosdb.containers
  public_network_access_enabled = var.cosmosdb.public_network_access_enabled
  local_authentication_disabled = var.cosmosdb.local_authentication_disabled
  free_tier_enabled             = var.cosmosdb.free_tier_enabled
  tags                          = local.common_tags
}

module "servicebus" {
  source                        = "../../modules/servicebus"
  namespace_name                = var.servicebus.namespace_name
  topic_name                    = var.servicebus.topic_name
  resource_group_name           = module.resource_group.name
  location                      = module.resource_group.location
  sku                           = var.servicebus.sku
  capacity                      = var.servicebus.capacity
  local_auth_enabled            = var.servicebus.local_auth_enabled
  public_network_access_enabled = var.servicebus.public_network_access_enabled
  minimum_tls_version           = var.servicebus.minimum_tls_version
  subscriptions                 = var.servicebus.subscriptions
  tags                          = local.common_tags
}

module "storage" {
  source                        = "../../modules/storage"
  account_name                  = var.storage.account_name
  container_name                = var.storage.container_name
  resource_group_name           = module.resource_group.name
  location                      = module.resource_group.location
  account_tier                  = var.storage.account_tier
  account_replication_type      = var.storage.account_replication_type
  public_network_access_enabled = var.storage.public_network_access_enabled
  tags                          = local.common_tags
}

module "ai_search" {
  source                        = "../../modules/ai-search"
  name                          = var.ai_search.name
  resource_group_name           = module.resource_group.name
  location                      = var.ai_search.location
  sku                           = var.ai_search.sku
  replica_count                 = var.ai_search.replica_count
  partition_count               = var.ai_search.partition_count
  public_network_access_enabled = var.ai_search.public_network_access_enabled
  local_authentication_enabled  = var.ai_search.local_authentication_enabled
  tags                          = local.common_tags
}

module "openai" {
  source                        = "../../modules/openai"
  name                          = var.openai.name
  resource_group_name           = module.resource_group.name
  location                      = module.resource_group.location
  sku_name                      = var.openai.sku_name
  custom_subdomain_name         = var.openai.custom_subdomain_name
  public_network_access_enabled = var.openai.public_network_access_enabled
  local_auth_enabled            = var.openai.local_auth_enabled
  deployments                   = var.openai.deployments
  tags                          = local.common_tags
}

module "private_endpoints" {
  source               = "../../modules/private-endpoints"
  resource_group_name  = module.resource_group.name
  location             = module.resource_group.location
  subnet_id            = "/subscriptions/${var.subscription_id}/resourceGroups/${module.resource_group.name}/providers/Microsoft.Network/virtualNetworks/${var.network.name}/subnets/${var.network.subnets[var.private_endpoints.subnet_key].name}"
  private_dns_zone_ids = module.network.private_dns_zone_ids
  private_endpoints = var.private_endpoints.enabled ? {
    cosmos = {
      name                            = var.private_endpoints.endpoint_names.cosmos
      private_service_connection_name = "${var.environment}-cosmos"
      resource_id                     = module.cosmosdb.account_id
      subresource_name                = "Sql"
      private_dns_zone_key            = "cosmos"
    }
    blob = {
      name                            = var.private_endpoints.endpoint_names.blob
      private_service_connection_name = "${var.environment}-blob"
      resource_id                     = module.storage.account_id
      subresource_name                = "blob"
      private_dns_zone_key            = "blob"
    }
    vault = {
      name                            = var.private_endpoints.endpoint_names.vault
      private_service_connection_name = "${var.environment}-vault"
      resource_id                     = module.keyvault.id
      subresource_name                = "vault"
      private_dns_zone_key            = "vault"
    }
    acr = {
      name                            = var.private_endpoints.endpoint_names.acr
      private_service_connection_name = "${var.environment}-acr"
      resource_id                     = module.acr.id
      subresource_name                = "registry"
      private_dns_zone_key            = "acr"
    }
    search = {
      name                            = var.private_endpoints.endpoint_names.search
      private_service_connection_name = "${var.environment}-search"
      resource_id                     = module.ai_search.id
      subresource_name                = "searchService"
      private_dns_zone_key            = "search"
    }
    openai = {
      name                            = var.private_endpoints.endpoint_names.openai
      private_service_connection_name = "${var.environment}-openai"
      resource_id                     = module.openai.id
      subresource_name                = "account"
      private_dns_zone_key            = "openai"
    }
  } : {}
  tags = local.common_tags

  depends_on = [module.network]
}

module "managed_identity" {
  source              = "../../modules/managed-identity"
  resource_group_name = module.resource_group.name
  location            = module.resource_group.location
  identities          = var.managed_identities
  tags                = local.common_tags
}

module "aks_private_dns" {
  source                    = "../../modules/private-dns"
  name                      = var.aks_private_dns.name
  resource_group_name       = module.resource_group.name
  virtual_network_id        = module.network.vnet_id
  virtual_network_link_name = var.aks_private_dns.virtual_network_link_name
  tags                      = local.common_tags
}

module "aks" {
  source                         = "../../modules/aks"
  name                           = var.aks.name
  resource_group_name            = module.resource_group.name
  location                       = module.resource_group.location
  dns_prefix                     = var.aks.dns_prefix
  kubernetes_version             = var.aks.kubernetes_version
  tenant_id                      = var.tenant_id
  aks_subnet_id                  = "/subscriptions/${var.subscription_id}/resourceGroups/${module.resource_group.name}/providers/Microsoft.Network/virtualNetworks/${var.network.name}/subnets/${var.network.subnets[var.aks.subnet_key].name}"
  system_node_pool               = var.aks.system_node_pool
  user_node_pools                = var.aks.user_node_pools
  private_cluster_enabled        = var.aks.private_cluster_enabled
  private_dns_zone_id            = module.aks_private_dns.private_dns_zone_id
  network_policy                 = var.aks.network_policy
  network_plugin_mode            = var.aks.network_plugin_mode
  service_cidr                   = var.aks.service_cidr
  dns_service_ip                 = var.aks.dns_service_ip
  azure_rbac_enabled             = var.aks.azure_rbac_enabled
  log_analytics_workspace_id     = module.monitor.id
  ingress_application_gateway_id = module.application_gateway.id
  tags                           = local.common_tags

  depends_on = [module.network, module.application_gateway, module.aks_private_dns]
}

module "workload_identity" {
  source = "../../modules/workload-identity"
  federated_credentials = {
    for key, subject in local.workload_identity_subjects :
    key => {
      name        = "${var.environment}-${key}-fic"
      identity_id = module.managed_identity.identity_ids[key]
      issuer      = module.aks.oidc_issuer_url
      subject     = subject
      audience    = ["api://AzureADTokenExchange"]
    }
  }
}

module "role_assignments" {
  source = "../../modules/role-assignments"
  role_assignments = merge(
    {
      acr_pull_kubelet = {
        scope                = module.acr.id
        role_definition_name = "AcrPull"
        principal_id         = module.aks.kubelet_identity_object_id
      }
      agic_appgw_contributor = {
        scope                = module.application_gateway.id
        role_definition_name = "Contributor"
        principal_id         = module.aks.ingress_application_gateway_identity_object_id
      }
      agic_resource_group_reader = {
        scope                = module.resource_group.id
        role_definition_name = "Reader"
        principal_id         = module.aks.ingress_application_gateway_identity_object_id
      }
    },
    var.platform_admin_object_id == "" ? {} : {
      aks_platform_admin = {
        scope                = module.aks.id
        role_definition_name = "Azure Kubernetes Service RBAC Cluster Admin"
        principal_id         = var.platform_admin_object_id
      }
    },
    {
      for key, principal_id in module.managed_identity.principal_ids :
      "keyvault_${key}" => {
        scope                = module.keyvault.id
        role_definition_name = "Key Vault Secrets User"
        principal_id         = principal_id
      }
      if contains(keys(var.workload_service_accounts), key)
    },
    {
      for key, principal_id in module.managed_identity.principal_ids :
      "storage_${key}" => {
        scope                = module.storage.account_id
        role_definition_name = "Storage Blob Data Contributor"
        principal_id         = principal_id
      }
      if contains(keys(var.workload_service_accounts), key)
    },
    {
      for key, principal_id in module.managed_identity.principal_ids :
      "servicebus_sender_${key}" => {
        scope                = module.servicebus.namespace_id
        role_definition_name = "Azure Service Bus Data Sender"
        principal_id         = principal_id
      }
      if contains(["auth", "collection", "processing", "ai"], key)
    },
    {
      for key, principal_id in module.managed_identity.principal_ids :
      "servicebus_receiver_${key}" => {
        scope                = module.servicebus.namespace_id
        role_definition_name = "Azure Service Bus Data Receiver"
        principal_id         = principal_id
      }
      if contains(["processing", "ai", "notification"], key)
    },
    {
      for key, principal_id in module.managed_identity.principal_ids :
      "search_${key}" => {
        scope                = module.ai_search.id
        role_definition_name = "Search Index Data Contributor"
        principal_id         = principal_id
      }
      if contains(keys(var.workload_service_accounts), key)
    },
    {
      for key, principal_id in module.managed_identity.principal_ids :
      "openai_${key}" => {
        scope                = module.openai.id
        role_definition_name = "Cognitive Services OpenAI User"
        principal_id         = principal_id
      }
      if contains(keys(var.workload_service_accounts), key)
    }
  )
}

module "cosmosdb_sql_role_assignments" {
  source              = "../../modules/cosmosdb-sql-role-assignments"
  resource_group_name = module.resource_group.name
  account_name        = module.cosmosdb.account_name
  account_id          = module.cosmosdb.account_id
  database_scope      = module.cosmosdb.account_id
  role_assignments = {
    for key, principal_id in module.managed_identity.principal_ids :
    key => {
      principal_id = principal_id
    }
    if contains(keys(var.workload_service_accounts), key)
  }
}

output "helm_values" {
  description = "AKS integration values required by the FinsOpsIQ Helm chart."
  value = {
    namespace                      = var.helm_namespace
    acr_login_server               = module.acr.login_server
    key_vault_name                 = module.keyvault.name
    cosmos_endpoint                = module.cosmosdb.endpoint
    cosmos_database                = module.cosmosdb.database_name
    service_bus_namespace          = module.servicebus.namespace_name
    service_bus_topic              = module.servicebus.topic_name
    service_bus_subscriptions      = module.servicebus.subscription_names
    storage_blob_endpoint          = module.storage.primary_blob_endpoint
    storage_container              = module.storage.container_name
    applicationinsights_connection = module.application_insights.connection_string
    azure_search_endpoint          = module.ai_search.endpoint
    azure_openai_endpoint          = module.openai.endpoint
    azure_openai_deployment_names  = module.openai.deployment_names
    application_gateway_id         = module.application_gateway.id
    application_gateway_name       = module.application_gateway.name
    application_gateway_public_ip  = module.application_gateway.public_ip_address
    application_gateway_waf_policy = module.application_gateway.waf_policy_name
    aks_private_fqdn               = module.aks.aks_private_fqdn
    bastion_name                   = module.bastion.bastion_name
    management_vm_private_ip       = module.management_vm.vm_private_ip
    workload_identity_client_ids   = module.managed_identity.client_ids
    workload_identity_subjects     = module.workload_identity.subjects
  }
  sensitive = true
}

output "aks" {
  description = "AKS deployment outputs."
  value = {
    name                = module.aks.name
    id                  = module.aks.id
    aks_id              = module.aks.aks_id
    aks_private_fqdn    = module.aks.aks_private_fqdn
    oidc_issuer_url     = module.aks.oidc_issuer_url
    node_resource_group = module.aks.node_resource_group
  }
}

output "application_gateway" {
  description = "Public Application Gateway WAF outputs."
  value = {
    name              = module.application_gateway.name
    id                = module.application_gateway.id
    public_ip_address = module.application_gateway.public_ip_address
    public_ip_fqdn    = module.application_gateway.public_ip_fqdn
    waf_policy_name   = module.application_gateway.waf_policy_name
  }
}

output "secure_admin" {
  description = "Private administration path outputs."
  sensitive   = true
  value = {
    bastion_id         = module.bastion.bastion_id
    bastion_name       = module.bastion.bastion_name
    bastion_host       = module.bastion.bastion_host
    management_vm_id   = module.management_vm.vm_id
    management_vm_name = module.management_vm.vm_name
    management_vm_ip   = module.management_vm.vm_private_ip
    aks_private_dns_id = module.aks_private_dns.private_dns_zone_id
    aks_private_fqdn   = module.aks.aks_private_fqdn
    management_nsg_id  = module.management_vm.network_security_group_id
  }
}

output "private_networking" {
  description = "Private networking outputs."
  value = {
    private_dns_zone_ids    = module.network.private_dns_zone_ids
    private_endpoint_ids    = module.private_endpoints.private_endpoint_ids
    nat_gateway_ids         = module.network.nat_gateway_ids
    network_security_groups = module.network.network_security_group_ids
    aks_private_dns_zone_id = module.aks_private_dns.private_dns_zone_id
  }
}
