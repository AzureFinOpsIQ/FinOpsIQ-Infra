variable "subscription_id" {
  description = "Azure subscription ID where the Terraform state backend will be created."
  type        = string
}

variable "tenant_id" {
  description = "Microsoft Entra tenant ID."
  type        = string
}

variable "location" {
  description = "Azure region for the backend resources."
  type        = string
  default     = "eastus2"
}

variable "resource_group_name" {
  description = "Resource group name for Terraform remote state backend resources."
  type        = string
  default     = "rg-finopsiq-tfstate"
}

variable "storage_account_prefix" {
  description = "Prefix for the globally unique Terraform state storage account name. A random suffix is appended."
  type        = string
  default     = "stfinopsiqtfstate"

  validation {
    condition     = can(regex("^[a-zA-Z0-9]+$", var.storage_account_prefix))
    error_message = "storage_account_prefix must contain only letters and numbers."
  }
}

variable "storage_account_random_suffix_length" {
  description = "Length of the random lowercase alphanumeric storage account suffix."
  type        = number
  default     = 6

  validation {
    condition     = var.storage_account_random_suffix_length >= 4 && var.storage_account_random_suffix_length <= 12
    error_message = "storage_account_random_suffix_length must be between 4 and 12."
  }
}

variable "storage_account_tier" {
  description = "Storage account tier."
  type        = string
  default     = "Standard"
}

variable "storage_account_replication_type" {
  description = "Storage replication type."
  type        = string
  default     = "LRS"
}

variable "container_name" {
  description = "Blob container name for Terraform state files."
  type        = string
  default     = "tfstate"
}

variable "public_network_access_enabled" {
  description = "Whether public network access is enabled for the state storage account."
  type        = bool
  default     = true
}

variable "blob_delete_retention_days" {
  description = "Blob soft delete retention in days."
  type        = number
  default     = 30
}

variable "container_delete_retention_days" {
  description = "Container soft delete retention in days."
  type        = number
  default     = 30
}

variable "tags" {
  description = "Tags applied to bootstrap backend resources."
  type        = map(string)
  default = {
    Environment = "bootstrap"
    Owner       = "platform"
    Project     = "FinsOpsIQ"
  }
}
