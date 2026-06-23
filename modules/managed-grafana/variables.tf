variable "name" {
  description = "Azure Managed Grafana name."
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

variable "sku" {
  description = "Azure Managed Grafana SKU."
  type        = string
  default     = "Standard"
}

variable "grafana_major_version" {
  description = "Grafana major version."
  type        = string
  default     = "12"
}

variable "api_key_enabled" {
  description = "Enable Grafana API keys."
  type        = bool
  default     = false
}

variable "deterministic_outbound_ip_enabled" {
  description = "Enable deterministic outbound IP for Azure Managed Grafana."
  type        = bool
  default     = false
}

variable "public_network_access_enabled" {
  description = "Enable public network access for Azure Managed Grafana."
  type        = bool
  default     = true
}

variable "azure_monitor_workspace_id" {
  description = "Azure Monitor Workspace resource ID integrated with Grafana."
  type        = string
}

variable "tags" {
  description = "Common tags."
  type        = map(string)
}
