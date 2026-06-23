subscription_id          = "e54a7ca3-4b6b-4b0f-889d-2508c85f4f30"
tenant_id                = "22dc2419-3ab3-4f27-905a-945315d19d95"
environment              = "prod"
location                 = "eastus2"
resource_group_name      = "rg-finopsiq-prod"
owner                    = "platform"
helm_namespace           = "finopsiq-prod"
platform_admin_object_id = ""

extra_tags = {
  Project    = "FinsOpsIQ"
  CostCenter = "FinOps"
}

network = {
  name          = "vnet-finopsiq-prod"
  address_space = ["10.50.0.0/16"]
  subnets = {
    bastion = {
      name              = "AzureBastionSubnet"
      address_prefixes  = ["10.50.0.0/26"]
      service_endpoints = []
    }
    aks_nodes = {
      name                       = "snet-aks-nodes"
      address_prefixes           = ["10.50.4.0/22"]
      service_endpoints          = ["Microsoft.KeyVault", "Microsoft.Storage", "Microsoft.AzureCosmosDB"]
      network_security_group_key = "aks"
      nat_gateway_key            = "aks"
    }
    management = {
      name              = "snet-management"
      address_prefixes  = ["10.50.12.0/24"]
      service_endpoints = ["Microsoft.KeyVault", "Microsoft.Storage", "Microsoft.AzureCosmosDB"]
    }
    app_gateway = {
      name                       = "snet-appgw"
      address_prefixes           = ["10.50.8.0/24"]
      service_endpoints          = []
      network_security_group_key = "app_gateway"
    }
    private_endpoints = {
      name                              = "snet-private-endpoints"
      address_prefixes                  = ["10.50.9.0/24"]
      service_endpoints                 = []
      private_endpoint_network_policies = "Disabled"
    }
  }
  network_security_groups = {
    aks = {
      name           = "nsg-finopsiq-prod-aks"
      security_rules = []
    }
    app_gateway = {
      name = "nsg-finopsiq-prod-appgw"
      security_rules = [
        {
          name                       = "AllowHttpInternet"
          priority                   = 100
          direction                  = "Inbound"
          access                     = "Allow"
          protocol                   = "Tcp"
          source_port_range          = "*"
          destination_port_range     = "80"
          source_address_prefix      = "Internet"
          destination_address_prefix = "*"
        },
        {
          name                       = "AllowHttpsInternet"
          priority                   = 110
          direction                  = "Inbound"
          access                     = "Allow"
          protocol                   = "Tcp"
          source_port_range          = "*"
          destination_port_range     = "443"
          source_address_prefix      = "Internet"
          destination_address_prefix = "*"
        },
        {
          name                       = "AllowGatewayManager"
          priority                   = 120
          direction                  = "Inbound"
          access                     = "Allow"
          protocol                   = "Tcp"
          source_port_range          = "*"
          destination_port_range     = "65200-65535"
          source_address_prefix      = "GatewayManager"
          destination_address_prefix = "*"
        },
        {
          name                       = "AllowAzureLoadBalancer"
          priority                   = 130
          direction                  = "Inbound"
          access                     = "Allow"
          protocol                   = "*"
          source_port_range          = "*"
          destination_port_range     = "*"
          source_address_prefix      = "AzureLoadBalancer"
          destination_address_prefix = "*"
        }
      ]
    }
  }
  nat_gateways = {
    aks = {
      name                    = "nat-finopsiq-prod-aks"
      public_ip_name          = "pip-finopsiq-prod-nat"
      idle_timeout_in_minutes = 10
      zones                   = []
    }
  }
  private_dns_zones = {
    cosmos = "privatelink.documents.azure.com"
    blob   = "privatelink.blob.core.windows.net"
    vault  = "privatelink.vaultcore.azure.net"
    acr    = "privatelink.azurecr.io"
    search = "privatelink.search.windows.net"
    openai = "privatelink.openai.azure.com"
  }
}

private_endpoints = {
  enabled    = true
  subnet_key = "private_endpoints"
  endpoint_names = {
    cosmos = "pe-finopsiq-prod-cosmos"
    blob   = "pe-finopsiq-prod-blob"
    vault  = "pe-finopsiq-prod-vault"
    acr    = "pe-finopsiq-prod-acr"
    search = "pe-finopsiq-prod-search"
    openai = "pe-finopsiq-prod-openai"
  }
}

monitor = {
  name              = "log-finopsiq-prod"
  sku               = "PerGB2018"
  retention_in_days = 90
}

application_insights = {
  name             = "appi-finopsiq-prod"
  application_type = "web"
}

acr = {
  name = "acrfinopsiqprod"
  sku  = "Premium"
}

application_gateway = {
  name                   = "agw-finopsiq-prod"
  public_ip_name         = "pip-agw-finopsiq-prod"
  waf_policy_name        = "waf-finopsiq-prod"
  subnet_key             = "app_gateway"
  sku_name               = "WAF_v2"
  sku_tier               = "WAF_v2"
  autoscale_min_capacity = 2
  autoscale_max_capacity = 5
  frontend_port          = 80
  waf_enabled            = true
  waf_firewall_mode      = "Prevention"
  waf_rule_set_type      = "OWASP"
  waf_rule_set_version   = "3.2"
  zones                  = []
}

bastion = {
  name           = "bas-finopsiq-prod"
  public_ip_name = "pip-bas-finopsiq-prod"
  subnet_key     = "bastion"
  sku            = "Standard"
  scale_units    = 2
  zones          = []
}

management_vm = {
  name                         = "vm-finopsiq-prod-mgmt"
  network_interface_name       = "nic-finopsiq-prod-mgmt"
  network_security_group_name  = "nsg-finopsiq-prod-management"
  subnet_key                   = "management"
  vm_size                      = "Standard_D2s_v3"
  admin_username               = "finopsadmin"
  admin_password               = "CHANGE_ME_ManagementVmPassword_123!"
  os_disk_size_gb              = 64
  os_disk_storage_account_type = "Premium_LRS"
}

aks_private_dns = {
  name                      = "privatelink.eastus2.azmk8s.io"
  virtual_network_link_name = "aks-private-dns-vnet-finopsiq-prod-link"
}

keyvault = {
  name                          = "kv-finopsiq-prod"
  sku_name                      = "standard"
  enable_rbac_authorization     = true
  purge_protection_enabled      = true
  soft_delete_retention_days    = 90
  public_network_access_enabled = false
}

cosmosdb = {
  account_name                  = "cosmos-finopsiq-prod"
  database_name                 = "finopsiq"
  consistency_level             = "Session"
  database_throughput           = null
  public_network_access_enabled = false
  local_authentication_disabled = true
  free_tier_enabled             = false
  containers = {
    tenants            = { name = "tenants", partition_key_paths = ["/tenantId"] }
    subscriptions      = { name = "subscriptions", partition_key_paths = ["/tenantId"] }
    tenantUsers        = { name = "tenantUsers", partition_key_paths = ["/tenantId"] }
    tenantHealth       = { name = "tenantHealth", partition_key_paths = ["/tenantId"] }
    costFacts          = { name = "costFacts", partition_key_paths = ["/tenantId"] }
    resources          = { name = "resources", partition_key_paths = ["/tenantId"] }
    recommendations    = { name = "recommendations", partition_key_paths = ["/tenantId"] }
    processingMetadata = { name = "processingMetadata", partition_key_paths = ["/tenantId"] }
    rawPayloads        = { name = "rawPayloads", partition_key_paths = ["/tenantId"] }
    authSessions       = { name = "authSessions", partition_key_paths = ["/tenantId"] }
    auditEvents        = { name = "auditEvents", partition_key_paths = ["/tenantId"] }
  }
}

servicebus = {
  namespace_name                = "sb-finopsiq-prod"
  topic_name                    = "finops-events"
  sku                           = "Premium"
  capacity                      = 1
  local_auth_enabled            = false
  public_network_access_enabled = true
  minimum_tls_version           = "1.2"
  subscriptions = {
    processing-service   = {}
    ai-service           = {}
    notification-service = {}
  }
}

storage = {
  account_name                  = "stfinopsiqprod"
  container_name                = "finops-raw"
  account_tier                  = "Standard"
  account_replication_type      = "ZRS"
  public_network_access_enabled = false
}

ai_search = {
  location                      = "eastus"
  name                          = "search-finopsiq-prod"
  sku                           = "standard"
  replica_count                 = 2
  partition_count               = 1
  public_network_access_enabled = false
  local_authentication_enabled  = false
}

openai = {
  name                          = "oai-finopsiq-prod"
  sku_name                      = "S0"
  custom_subdomain_name         = "oai-finopsiq-prod"
  public_network_access_enabled = false
  local_auth_enabled            = false
  deployments = {
    chat = {
      name          = "gpt-4.1-mini"
      model_format  = "OpenAI"
      model_name    = "gpt-4.1-mini"
      model_version = "2025-04-14"
      sku_name      = "GlobalStandard"
      capacity      = 20
    }
    embeddings = {
      name          = "text-embedding-3-small"
      model_format  = "OpenAI"
      model_name    = "text-embedding-3-small"
      model_version = "1"
      sku_name      = "Standard"
      capacity      = 20
    }
  }
}

managed_identities = {
  auth         = { name = "id-finopsiq-prod-auth" }
  collection   = { name = "id-finopsiq-prod-collection" }
  processing   = { name = "id-finopsiq-prod-processing" }
  ai           = { name = "id-finopsiq-prod-ai" }
  notification = { name = "id-finopsiq-prod-notification" }
}

workload_service_accounts = {
  auth         = "auth-service"
  collection   = "collection-service"
  processing   = "processing-service"
  ai           = "ai-service"
  notification = "notification-service"
}

aks = {
  name                    = "aks-finopsiq-prod"
  dns_prefix              = "aks-finopsiq-prod"
  kubernetes_version      = "1.34"
  subnet_key              = "aks_nodes"
  network_policy          = "azure"
  service_cidr            = "10.51.0.0/16"
  dns_service_ip          = "10.51.0.10"
  azure_rbac_enabled      = true
  private_cluster_enabled = true
  system_node_pool = {
    name                        = "system"
    vm_size                     = "Standard_D2s_v3"
    node_count                  = 1
    enable_auto_scaling         = true
    min_count                   = 1
    max_count                   = 2
    max_pods                    = 50
    os_disk_size_gb             = 64
    temporary_name_for_rotation = "sysrot"
  }
  user_node_pools = {
    workload = {
      name                = "workload"
      vm_size             = "Standard_D2s_v3"
      node_count          = 1
      enable_auto_scaling = true
      min_count           = 1
      max_count           = 3
      max_pods            = 50
      os_disk_size_gb     = 128
    }
  }
}
