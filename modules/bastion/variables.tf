variable "name" {
  description = "Azure Bastion host name."
  type        = string
}

variable "public_ip_name" {
  description = "Azure Bastion public IP name."
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

variable "subnet_id" {
  description = "Dedicated AzureBastionSubnet resource ID."
  type        = string
}

variable "sku" {
  description = "Azure Bastion SKU."
  type        = string
  default     = "Standard"

  validation {
    condition     = contains(["Basic", "Standard", "Premium", "Developer"], var.sku)
    error_message = "Bastion SKU must be Basic, Standard, Premium, or Developer."
  }
}

variable "scale_units" {
  description = "Azure Bastion scale units."
  type        = number
  default     = 2
}

variable "zones" {
  description = "Availability zones for zone-redundant Bastion resources where supported."
  type        = list(string)
  default     = []
}

variable "tags" {
  description = "Common tags."
  type        = map(string)
}
