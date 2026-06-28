resource "azuread_application" "login" {
  display_name     = var.login_display_name
  sign_in_audience = "AzureADMyOrg"

  web {
    redirect_uris = [
      "https://${var.application_hostname}/api/auth/callback",
      "http://localhost:3000/api/auth/callback",
    ]

    implicit_grant {
      access_token_issuance_enabled = false
      id_token_issuance_enabled     = true
    }
  }

  required_resource_access {
    resource_app_id = "797f4846-ba00-4fd7-ba43-dac1f8f63013"

    resource_access {
      id   = "41094075-9dad-400e-a0bd-54e686782033"
      type = "Scope"
    }
  }
}

resource "azuread_service_principal" "login" {
  client_id = azuread_application.login.client_id
}

resource "azuread_application_password" "login" {
  application_id = azuread_application.login.id
  display_name   = "${var.environment}-login-client-secret"
}

resource "azuread_application" "internal_api" {
  display_name     = var.internal_api_display_name
  identifier_uris  = [var.internal_api_identifier_uri]
  sign_in_audience = "AzureADMyOrg"

  api {
    requested_access_token_version = 2
  }
}

resource "azuread_service_principal" "internal_api" {
  client_id = azuread_application.internal_api.client_id
}

resource "azuread_application" "collection" {
  display_name     = var.collection_display_name
  sign_in_audience = "AzureADMultipleOrgs"

  api {
    requested_access_token_version = 2
  }

  required_resource_access {
    resource_app_id = "797f4846-ba00-4fd7-ba43-dac1f8f63013"

    resource_access {
      id   = "41094075-9dad-400e-a0bd-54e686782033"
      type = "Scope"
    }
  }
}

resource "azuread_service_principal" "collection" {
  client_id = azuread_application.collection.client_id
}

resource "azuread_application_federated_identity_credential" "collection" {
  #checkov:skip=CKV_AZURE_249:This federated credential is for AKS Workload Identity using a system:serviceaccount subject, not GitHub Actions OIDC.
  application_id = azuread_application.collection.id
  display_name   = "${var.environment}-collection-workload-identity"
  audiences      = ["api://AzureADTokenExchange"]
  issuer         = var.collection_federated_credential.issuer
  subject        = var.collection_federated_credential.subject
}
