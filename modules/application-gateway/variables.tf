variable "name" {
  description = "Application Gateway name."
  type        = string
}

variable "public_ip_name" {
  description = "Public IP name for Application Gateway."
  type        = string
}

variable "public_frontend_enabled" {
  description = "Create a public frontend IP configuration for Application Gateway."
  type        = bool
  default     = true
}

variable "private_frontend_enabled" {
  description = "Create a private frontend IP configuration for Application Gateway."
  type        = bool
  default     = false
}

variable "private_ip_address" {
  description = "Optional static private frontend IP address. Leave null for dynamic allocation."
  type        = string
  default     = null
}

variable "waf_policy_name" {
  description = "Web Application Firewall policy name."
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
  description = "Dedicated Application Gateway subnet ID."
  type        = string
}

variable "sku_name" {
  description = "Application Gateway SKU name."
  type        = string
}

variable "sku_tier" {
  description = "Application Gateway SKU tier."
  type        = string
}

variable "autoscale_min_capacity" {
  description = "Application Gateway autoscale minimum capacity."
  type        = number
}

variable "autoscale_max_capacity" {
  description = "Application Gateway autoscale maximum capacity."
  type        = number
}

variable "frontend_port" {
  description = "Frontend listener port."
  type        = number
}

variable "waf_enabled" {
  description = "Enable Web Application Firewall."
  type        = bool
}

variable "waf_firewall_mode" {
  description = "WAF firewall mode."
  type        = string

  validation {
    condition     = contains(["Detection", "Prevention"], var.waf_firewall_mode)
    error_message = "waf_firewall_mode must be Detection or Prevention."
  }
}

variable "waf_rule_set_type" {
  description = "WAF rule set type."
  type        = string
}

variable "waf_rule_set_version" {
  description = "WAF rule set version."
  type        = string
}

variable "zones" {
  description = "Optional availability zones."
  type        = list(string)
  default     = []
}

variable "tags" {
  description = "Common tags."
  type        = map(string)
}
