variable "resource_group_name" {
  description = "Cosmos DB account resource group name."
  type        = string
}

variable "account_name" {
  description = "Cosmos DB account name."
  type        = string
}

variable "account_id" {
  description = "Cosmos DB account resource ID."
  type        = string
}

variable "database_scope" {
  description = "Default Cosmos DB SQL database scope for data-plane role assignments."
  type        = string
}

variable "role_assignments" {
  description = "Cosmos DB SQL role assignments keyed by logical name."
  type = map(object({
    principal_id       = string
    role_definition_id = optional(string)
    scope              = optional(string)
  }))
}
