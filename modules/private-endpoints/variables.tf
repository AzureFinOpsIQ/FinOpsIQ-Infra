variable "resource_group_name" {
  description = "Resource group name."
  type        = string
}

variable "location" {
  description = "Azure region."
  type        = string
}

variable "subnet_id" {
  description = "Private endpoint subnet ID."
  type        = string
}

variable "private_dns_zone_ids" {
  description = "Private DNS zone IDs keyed by service name."
  type        = map(string)
}

variable "private_endpoints" {
  description = "Private endpoints keyed by logical service name."
  type = map(object({
    name                            = string
    private_service_connection_name = string
    resource_id                     = string
    subresource_name                = string
    private_dns_zone_key            = string
  }))
}

variable "tags" {
  description = "Common tags."
  type        = map(string)
}
