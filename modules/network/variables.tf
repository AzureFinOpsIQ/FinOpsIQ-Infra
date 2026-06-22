variable "name" {
  description = "Virtual network name."
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

variable "address_space" {
  description = "Virtual network address spaces."
  type        = list(string)
}

variable "subnets" {
  description = "Subnets keyed by logical name."
  type = map(object({
    name                              = string
    address_prefixes                  = list(string)
    service_endpoints                 = optional(list(string), [])
    private_endpoint_network_policies = optional(string, null)
    network_security_group_key        = optional(string, null)
    nat_gateway_key                   = optional(string, null)
  }))
}

variable "network_security_groups" {
  description = "Network Security Groups keyed by logical name."
  type = map(object({
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
  }))
  default = {}
}

variable "nat_gateways" {
  description = "NAT Gateways keyed by logical name."
  type = map(object({
    name                    = string
    public_ip_name          = string
    idle_timeout_in_minutes = optional(number, 10)
    zones                   = optional(list(string), [])
  }))
  default = {}
}

variable "private_dns_zones" {
  description = "Private DNS zones keyed by service name."
  type        = map(string)
  default     = {}
}

variable "tags" {
  description = "Common tags."
  type        = map(string)
}
