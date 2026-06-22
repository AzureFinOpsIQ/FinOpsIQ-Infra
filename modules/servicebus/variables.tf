variable "namespace_name" {
  description = "Service Bus namespace name."
  type        = string
}

variable "topic_name" {
  description = "Service Bus topic name."
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
  description = "Service Bus SKU."
  type        = string
}

variable "capacity" {
  description = "Service Bus Messaging Units for Premium SKU."
  type        = number
  default     = 0
}

variable "local_auth_enabled" {
  description = "Enable local SAS authentication."
  type        = bool
  default     = false
}

variable "public_network_access_enabled" {
  description = "Enable public network access for the Service Bus namespace."
  type        = bool
  default     = true
}

variable "minimum_tls_version" {
  description = "Minimum TLS version."
  type        = string
  default     = "1.2"
}

variable "subscriptions" {
  description = "Topic subscriptions keyed by subscription name."
  type = map(object({
    max_delivery_count                   = optional(number, 5)
    dead_lettering_on_message_expiration = optional(bool, true)
    default_message_ttl                  = optional(string, "P7D")
  }))
  default = {}
}

variable "tags" {
  description = "Common tags."
  type        = map(string)
}
