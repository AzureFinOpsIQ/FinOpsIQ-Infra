variable "subscription_id" {
  description = "Azure subscription ID."
  type        = string
}

variable "tenant_id" {
  description = "Microsoft Entra tenant ID."
  type        = string
}

variable "environment" {
  description = "Deployment environment represented by this root module."
  type        = string

  validation {
    condition     = contains(["dev", "prod"], var.environment)
    error_message = "environment must be dev or prod."
  }
}

variable "location" {
  description = "Azure region."
  type        = string
}

variable "resource_group_name" {
  description = "Resource group name."
  type        = string
}

variable "owner" {
  description = "Required Owner tag value."
  type        = string
}

variable "extra_tags" {
  description = "Optional Project, CostCenter, and other tags."
  type        = map(string)
  default     = {}
}

variable "helm_namespace" {
  description = "Kubernetes namespace used by the Helm release."
  type        = string
}

variable "workload_service_accounts" {
  description = "Workload Identity service accounts keyed by managed identity key."
  type        = map(string)
}

variable "platform_admin_object_id" {
  description = "Microsoft Entra object ID that receives Azure Kubernetes Service RBAC Cluster Admin on AKS. Leave empty to skip assignment until a platform admin is selected."
  type        = string
  default     = ""
}

variable "network" {
  description = "Virtual network configuration."
  type = object({
    name          = string
    address_space = list(string)
    subnets = map(object({
      name                              = string
      address_prefixes                  = list(string)
      service_endpoints                 = optional(list(string), [])
      private_endpoint_network_policies = optional(string, null)
      network_security_group_key        = optional(string, null)
      nat_gateway_key                   = optional(string, null)
    }))
    network_security_groups = optional(map(object({
      name = string
      security_rules = optional(list(object({
        name                       = string
        priority                   = number
        direction                  = string
        access                     = string
        protocol                   = string
        source_port_range          = string
        destination_port_range     = string
        source_address_prefix      = string
        destination_address_prefix = string
      })), [])
    })), {})
    nat_gateways = optional(map(object({
      name                    = string
      public_ip_name          = string
      idle_timeout_in_minutes = optional(number, 10)
      zones                   = optional(list(string), [])
    })), {})
    private_dns_zones = optional(map(string), {})
  })
}

variable "private_endpoints" {
  description = "Private endpoint configuration."
  type = object({
    enabled    = bool
    subnet_key = string
    endpoint_names = object({
      cosmos = string
      blob   = string
      vault  = string
      acr    = string
      search = string
      openai = string
    })
  })
}

variable "monitor" {
  description = "Log Analytics configuration."
  type = object({
    name              = string
    sku               = string
    retention_in_days = number
  })
}

variable "application_insights" {
  description = "Application Insights configuration."
  type = object({
    name             = string
    application_type = string
  })
}

variable "acr" {
  description = "Azure Container Registry configuration."
  type = object({
    name = string
    sku  = string
  })
}

variable "application_gateway" {
  description = "Application Gateway WAF configuration for public ingress."
  type = object({
    name                   = string
    public_ip_name         = string
    waf_policy_name        = string
    subnet_key             = string
    sku_name               = string
    sku_tier               = string
    autoscale_min_capacity = number
    autoscale_max_capacity = number
    frontend_port          = number
    waf_enabled            = bool
    waf_firewall_mode      = string
    waf_rule_set_type      = string
    waf_rule_set_version   = string
    zones                  = optional(list(string), [])
  })
}

variable "bastion" {
  description = "Azure Bastion configuration for private administration."
  type = object({
    name           = string
    public_ip_name = string
    subnet_key     = string
    sku            = optional(string, "Standard")
    scale_units    = optional(number, 2)
    zones          = optional(list(string), [])
  })
}

variable "management_vm" {
  description = "Private management VM configuration."
  type = object({
    name                         = string
    network_interface_name       = string
    network_security_group_name  = string
    subnet_key                   = string
    vm_size                      = optional(string, "Standard_D2s_v3")
    admin_username               = string
    admin_password_secret_name   = optional(string, "management-vm-admin-password")
    os_disk_size_gb              = optional(number, 64)
    os_disk_storage_account_type = optional(string, "Premium_LRS")
  })
  sensitive = true
}

variable "aks_private_dns" {
  description = "AKS private API DNS zone configuration."
  type = object({
    name                      = string
    virtual_network_link_name = string
  })
}

variable "keyvault" {
  description = "Key Vault configuration."
  type = object({
    name                          = string
    sku_name                      = string
    enable_rbac_authorization     = bool
    purge_protection_enabled      = bool
    soft_delete_retention_days    = number
    public_network_access_enabled = bool
  })
}

variable "cosmosdb" {
  description = "Cosmos DB configuration."
  type = object({
    account_name                  = string
    database_name                 = string
    consistency_level             = string
    database_throughput           = optional(number)
    public_network_access_enabled = bool
    local_authentication_disabled = bool
    free_tier_enabled             = bool
    containers = map(object({
      name                = string
      partition_key_paths = list(string)
      throughput          = optional(number)
    }))
  })
}

variable "servicebus" {
  description = "Service Bus configuration."
  type = object({
    namespace_name                = string
    topic_name                    = string
    sku                           = string
    capacity                      = optional(number, 0)
    local_auth_enabled            = optional(bool, false)
    public_network_access_enabled = optional(bool, true)
    minimum_tls_version           = optional(string, "1.2")
    subscriptions = optional(map(object({
      max_delivery_count                   = optional(number, 5)
      dead_lettering_on_message_expiration = optional(bool, true)
      default_message_ttl                  = optional(string, "P7D")
    })), {})
  })
}

variable "storage" {
  description = "Storage account configuration."
  type = object({
    account_name                  = string
    container_name                = string
    account_tier                  = string
    account_replication_type      = string
    public_network_access_enabled = bool
  })
}

variable "ai_search" {
  description = "Azure AI Search configuration."
  type = object({
    location                      = string
    name                          = string
    sku                           = string
    replica_count                 = number
    partition_count               = number
    public_network_access_enabled = bool
    local_authentication_enabled  = bool
  })
}

variable "openai" {
  description = "Azure OpenAI configuration."
  type = object({
    name                          = string
    sku_name                      = string
    custom_subdomain_name         = string
    public_network_access_enabled = bool
    local_auth_enabled            = bool
    deployments = map(object({
      name          = string
      model_format  = string
      model_name    = string
      model_version = string
      sku_name      = string
      capacity      = number
    }))
  })
}

variable "managed_identities" {
  description = "User-assigned managed identities keyed by workload name."
  type = map(object({
    name = string
  }))
}

variable "aks" {
  description = "AKS configuration."
  type = object({
    name                    = string
    dns_prefix              = string
    kubernetes_version      = string
    subnet_key              = string
    network_policy          = string
    network_plugin_mode     = optional(string)
    service_cidr            = string
    dns_service_ip          = string
    azure_rbac_enabled      = bool
    private_cluster_enabled = optional(bool, true)
    system_node_pool = object({
      name                = string
      vm_size             = string
      node_count          = number
      enable_auto_scaling = bool
      min_count           = number
      max_count           = number
      max_pods            = number
      os_disk_size_gb     = number
    })
    user_node_pools = map(object({
      name                = string
      vm_size             = string
      node_count          = number
      enable_auto_scaling = bool
      min_count           = number
      max_count           = number
      max_pods            = number
      os_disk_size_gb     = number
    }))
  })
}
