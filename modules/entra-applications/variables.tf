variable "environment" {
  description = "Deployment environment name."
  type        = string
}

variable "login_display_name" {
  description = "Display name for the Microsoft Entra login application."
  type        = string
}

variable "internal_api_display_name" {
  description = "Display name for the internal API application."
  type        = string
}

variable "collection_display_name" {
  description = "Display name for the cross-tenant collection application."
  type        = string
}

variable "application_hostname" {
  description = "Public application hostname."
  type        = string
}

variable "internal_api_identifier_uri" {
  description = "Application ID URI used as the internal service token audience."
  type        = string
}

variable "collection_federated_credential" {
  description = "Federated credential settings for the collection workload identity."
  type = object({
    issuer  = string
    subject = string
  })
}
