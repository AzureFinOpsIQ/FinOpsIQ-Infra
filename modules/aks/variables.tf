variable "name" {
  description = "AKS cluster name."
  type        = string
}

variable "resource_group_name" {
  description = "Resource group name."
  type        = string
}

variable "location" {
  description = "Azure region."
  type        = string
}

variable "dns_prefix" {
  description = "AKS DNS prefix."
  type        = string
}

variable "kubernetes_version" {
  description = "AKS Kubernetes version. Must be v1.29 or newer."
  type        = string

  validation {
    condition     = can(regex("^1\\.(2[9-9]|[3-9][0-9])", var.kubernetes_version))
    error_message = "kubernetes_version must be 1.29 or newer."
  }
}

variable "tenant_id" {
  description = "Microsoft Entra tenant ID."
  type        = string
}

variable "aks_subnet_id" {
  description = "AKS subnet ID."
  type        = string
}

variable "ingress_application_gateway_id" {
  description = "Existing Application Gateway ID used by the AKS AGIC add-on."
  type        = string
  default     = null
}

variable "private_cluster_enabled" {
  description = "Enable private AKS API server endpoint."
  type        = bool
  default     = false
}

variable "private_dns_zone_id" {
  description = "Private DNS zone ID for the private AKS API server."
  type        = string
  default     = null
}

variable "system_node_pool" {
  description = "System node pool configuration."
  type = object({
    name                        = string
    vm_size                     = string
    node_count                  = number
    enable_auto_scaling         = bool
    min_count                   = number
    max_count                   = number
    max_pods                    = number
    os_disk_size_gb             = number
    temporary_name_for_rotation = optional(string, "sysrot")
  })
}

variable "user_node_pools" {
  description = "User node pools keyed by logical name."
  type = map(object({
    name                = string
    vm_size             = string
    node_count          = number
    enable_auto_scaling = bool
    min_count           = number
    max_count           = number
    max_pods            = number
    os_disk_size_gb     = number
  }))
}

variable "network_policy" {
  description = "AKS network policy."
  type        = string
}

variable "network_plugin_mode" {
  description = "AKS network plugin mode."
  type        = string
  default     = null
}

variable "service_cidr" {
  description = "AKS service CIDR."
  type        = string
}

variable "dns_service_ip" {
  description = "AKS DNS service IP."
  type        = string
}

variable "azure_rbac_enabled" {
  description = "Enable Azure RBAC for Kubernetes authorization."
  type        = bool
}

variable "log_analytics_workspace_id" {
  description = "Log Analytics workspace ID for Container Insights."
  type        = string
}

variable "tags" {
  description = "Common tags."
  type        = map(string)
}
