variable "name" {
  description = "Management VM name."
  type        = string
}

variable "network_interface_name" {
  description = "Management VM network interface name."
  type        = string
}

variable "network_security_group_name" {
  description = "Management subnet NSG name."
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
  description = "Management subnet ID."
  type        = string
}

variable "bastion_subnet_address_prefix" {
  description = "AzureBastionSubnet address prefix allowed to SSH to the management VM."
  type        = string
}

variable "vm_size" {
  description = "Management VM size."
  type        = string
  default     = "Standard_D2s_v3"
}

variable "admin_username" {
  description = "Management VM administrator username."
  type        = string
}

variable "admin_password" {
  description = "Management VM administrator password."
  type        = string
  sensitive   = true
}

variable "custom_data_path" {
  description = "Path to cloud-init/custom data bootstrap script."
  type        = string
}

variable "os_disk_size_gb" {
  description = "Management VM OS disk size in GB."
  type        = number
  default     = 64
}

variable "os_disk_storage_account_type" {
  description = "Management VM OS disk storage type."
  type        = string
  default     = "Premium_LRS"
}

variable "source_image_reference" {
  description = "Linux source image reference."
  type = object({
    publisher = string
    offer     = string
    sku       = string
    version   = string
  })
  default = {
    publisher = "Canonical"
    offer     = "ubuntu-24_04-lts"
    sku       = "server"
    version   = "latest"
  }
}

variable "tags" {
  description = "Common tags."
  type        = map(string)
}
