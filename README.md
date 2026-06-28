# FinsOpsIQ Terraform Infrastructure

This Terraform codebase provisions the Azure infrastructure required by FinsOpsIQ.

No application code or Helm templates are deployed by Terraform.

## Folder Structure

```text
terraform/
├── modules/
│   ├── resource-group/
│   ├── network/
│   ├── aks/
│   ├── acr/
│   ├── keyvault/
│   ├── cosmosdb/
│   ├── servicebus/
│   ├── storage/
│   ├── monitor/
│   ├── application-insights/
│   ├── ai-search/
│   ├── openai/
│   ├── managed-identity/
│   ├── workload-identity/
│   └── role-assignments/
└── environments/
    ├── dev/
    │   ├── main.tf
    │   ├── variables.tf
    │   ├── terraform.tfvars
    │   └── backend.tf
    └── prod/
        ├── main.tf
        ├── variables.tf
        ├── terraform.tfvars
        └── backend.tf
```

Each module contains:

```text
main.tf
variables.tf
outputs.tf
```

## Module Dependency Diagram

```text
resource-group
  ├── network
  │     └── aks
  │           └── workload-identity
  ├── monitor
  │     ├── application-insights
  │     └── aks
  ├── acr
  │     └── role-assignments
  ├── keyvault
  │     └── role-assignments
  ├── cosmosdb
  ├── servicebus
  │     └── role-assignments
  ├── storage
  │     └── role-assignments
  ├── ai-search
  │     └── role-assignments
  ├── openai
  │     └── role-assignments
  └── managed-identity
        ├── aks
        ├── workload-identity
        └── role-assignments
```

## Module Input / Output Matrix

| Module | Key Inputs | Key Outputs |
|---|---|---|
| resource-group | name, location, tags | id, name, location, tags |
| network | vnet name, address space, subnets, tags | vnet id, subnet ids |
| acr | name, sku, tags | id, name, login server |
| keyvault | name, tenant, RBAC, purge protection, network access, tags | id, name, vault URI |
| cosmosdb | account, database, containers, consistency, network/local auth, tags | account id, endpoint, database, containers |
| servicebus | namespace, topic, sku, capacity, tags | namespace id/name, topic id/name |
| storage | account, container, replication, network access, tags | account id/name, blob endpoint, container |
| monitor | workspace name, sku, retention, tags | workspace id/name |
| application-insights | name, workspace id, app type, tags | id, name, connection string |
| ai-search | name, sku, replicas, partitions, local auth, tags | id, endpoint, identity principal |
| openai | name, subdomain, sku, deployments, local auth, tags | id, endpoint, deployment names, identity principal |
| managed-identity | identity names, tags | identity ids, client ids, principal ids |
| workload-identity | issuer, subject, identity id, audience | credential ids, subjects |
| role-assignments | scope, role name, principal id | role assignment ids |
| aks | version, subnet, identities, pools, RBAC, network, monitor | id, name, OIDC issuer, node resource group |

## Environment Strategy

Terraform workspaces are not used.

Environment isolation is implemented with separate root modules:

- `terraform/environments/dev`
- `terraform/environments/prod`

The dev and prod tfvars use separate:

- resource group names
- network CIDRs
- AKS names
- resource names
- Kubernetes namespaces

This prevents resource name collisions between environments.

## Remote State Strategy

Both environments use:

```hcl
backend "azurerm" {}
```

Use backend configuration during `terraform init`.

Dev example:

```powershell
terraform -chdir=terraform/environments/dev init `
  -backend-config="resource_group_name=<state-rg>" `
  -backend-config="storage_account_name=<state-storage-account>" `
  -backend-config="container_name=<state-container>" `
  -backend-config="key=dev/terraform.tfstate" `
  -backend-config="use_azuread_auth=true"
```

Prod example:

```powershell
terraform -chdir=terraform/environments/prod init `
  -backend-config="resource_group_name=<state-rg>" `
  -backend-config="storage_account_name=<state-storage-account>" `
  -backend-config="container_name=<state-container>" `
  -backend-config="key=prod/terraform.tfstate" `
  -backend-config="use_azuread_auth=true"
```

Azure Storage provides state locking through blob leases.

State file naming strategy:

```text
dev/terraform.tfstate
prod/terraform.tfstate
```

Concurrent Terraform deployments are prevented by:

- Azure Blob lease state locking in the AzureRM backend
- GitHub Actions pipeline concurrency group `terraform-dev` for the DEV pipeline

## AKS / Helm Integration Outputs

The root environments expose `helm_values`, including:

- `namespace`
- `acr_login_server`
- `key_vault_name`
- `cosmos_endpoint`
- `cosmos_database`
- `service_bus_namespace`
- `service_bus_topic`
- `storage_blob_endpoint`
- `storage_container`
- `applicationinsights_connection`
- `azure_search_endpoint`
- `azure_openai_endpoint`
- `azure_openai_deployment_names`
- `workload_identity_client_ids`
- `workload_identity_subjects`

The output is marked sensitive because it includes runtime configuration values.

## Microsoft Entra App Registrations

The dev root module creates and owns three Microsoft Entra App Registrations for FinOpsIQ:

- `finopsiq-login`: single-tenant web application used for user sign-in. Terraform creates its client secret; store the output value in Key Vault as `ENTRA-CLIENT-SECRET`.
- `finopsiq-internal-api`: single-tenant internal API audience exposed as `api://finopsiq-internal-api`. Terraform creates an `InternalService.Access` application role and assigns it to the API gateway managed identity.
- `finopsiq-collection`: multi-tenant collection application used for customer-tenant Azure API access. Terraform creates the AKS Workload Identity federated credential for `system:serviceaccount:finopsiq-dev:collection-service`.

The root `helm_values` output contains the generated `entra_login_client_id`, `entra_login_client_secret`, `internal_api_audience`, and `collection_entra_client_id` values required by the Helm chart and Key Vault. The old `azure-cost-advisor-dev-*` App Registrations are not required by the dev Terraform deployment.

The CI/CD identity that runs Terraform must be able to create and update App Registrations, Service Principals, app role assignments, and federated credentials. Use an Entra role such as `Cloud Application Administrator` or `Application Administrator`, and ensure the identity can also perform the Azure RBAC assignments in the subscription.

## Production Readiness Review

Implemented:

- Modular Terraform structure
- Environment-specific remote backend stubs
- Workspace/environment guard
- Common tag inheritance
- AKS with OIDC and Workload Identity
- Configurable system and user node pools
- Configurable autoscaling
- Azure CNI
- Managed identities
- Federated identity credentials
- Role assignment module
- Helm-facing outputs

Not performed:

- `terraform apply`
- AKS deployment
- Helm deployment
- Application code changes
