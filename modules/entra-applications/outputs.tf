output "login_client_id" {
  description = "Client ID for the Entra login application."
  value       = azuread_application.login.client_id
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

output "internal_api_identifier_uri" {
  description = "Application ID URI used as the internal API audience."
  value       = var.internal_api_identifier_uri
}

output "collection_client_id" {
  description = "Client ID for the cross-tenant collection application."
  value       = azuread_application.collection.client_id
}
