output "login_client_id" {
  description = "Client ID for the Entra login application."
  value       = azuread_application.login.client_id
}

output "login_service_principal_object_id" {
  description = "Object ID for the login application service principal."
  value       = azuread_service_principal.login.object_id
}

output "login_client_secret" {
  description = "Client secret for the Entra login application. Store this in Key Vault as ENTRA-CLIENT-SECRET."
  value       = azuread_application_password.login.value
  sensitive   = true
}

output "internal_api_client_id" {
  description = "Client ID for the internal API application."
  value       = azuread_application.internal_api.client_id
}

output "internal_api_service_principal_object_id" {
  description = "Object ID for the internal API application service principal."
  value       = azuread_service_principal.internal_api.object_id
}

output "internal_api_identifier_uri" {
  description = "Application ID URI used as the internal API audience."
  value       = var.internal_api_identifier_uri
}

output "internal_api_app_role_ids" {
  description = "App role IDs exposed by the internal API application."
  value       = azuread_application.internal_api.app_role_ids
}

output "collection_client_id" {
  description = "Client ID for the cross-tenant collection application."
  value       = azuread_application.collection.client_id
}

output "collection_service_principal_object_id" {
  description = "Object ID for the collection application service principal."
  value       = azuread_service_principal.collection.object_id
}
