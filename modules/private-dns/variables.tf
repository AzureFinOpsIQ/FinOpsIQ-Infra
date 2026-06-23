variable "name" {
  description = "Private DNS zone name."
  type        = string
}

variable "resource_group_name" {
  description = "Resource group name."
  type        = string
}

variable "virtual_network_id" {
  description = "Virtual network ID to link to the private DNS zone."
  type        = string
}

variable "virtual_network_link_name" {
  description = "Private DNS zone virtual network link name."
  type        = string
}

variable "tags" {
  description = "Common tags."
  type        = map(string)
}
