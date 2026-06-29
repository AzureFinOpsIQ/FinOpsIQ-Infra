# FinOpsIQ Terraform Infrastructure

This repository contains the Terraform infrastructure code for FinOpsIQ. It provisions the Azure platform used by the FinOpsIQ SaaS application.

Terraform manages Azure infrastructure only. It does not build application containers, deploy Helm charts, or sync Argo CD applications.

## What Terraform Provisions

- Resource groups and common tags.
- Virtual network, subnets, private DNS, and private endpoints.
- Private Azure Kubernetes Service cluster.
- AKS node pools, OIDC issuer, Azure RBAC, Azure Policy, and Workload Identity.
- Azure Container Registry.
- Azure Key Vault.
- User Assigned Managed Identities.
- Microsoft Entra application registrations used by the platform.
- Federated Identity Credentials for GitHub OIDC and AKS Workload Identity.
- Azure Cosmos DB.
- Azure Storage and Blob container.
- Azure Service Bus namespace, topic, and subscriptions.
- Azure OpenAI.
- Azure AI Search.
- Azure Monitor, Log Analytics, Application Insights, Azure Monitor Workspace, and Managed Grafana.
- Azure Bastion and management VM.
- Azure RBAC role assignments required by platform identities.

## Repository Layout

```text
terraform/
  bootstrap/                  Terraform backend bootstrap root module
  environments/
    dev/                      DEV root module
    prod/                     PROD root module
  modules/
    acr/
    ai-search/
    aks/
    application-gateway/
    azure-monitor-workspace/
    bastion/
    cosmosdb/
    cosmosdb-sql-role-assignments/
    entra-applications/
    keyvault/
    managed-grafana/
    management-vm/
    network/
    private-dns/
    private-endpoints/
    servicebus/
    storage/
    workload-identity/
  scripts/                    Import and helper scripts used by workflows
  .github/workflows/          Terraform GitHub Actions workflows
```

## Environment Strategy

Terraform workspaces are not used.

Environment isolation is implemented with separate root modules:

- `environments/dev`
- `environments/prod`

Each environment has its own variables, tfvars, naming convention, network ranges, Kubernetes namespace, and state key.

## Remote State

The AzureRM backend is configured during `terraform init` using GitHub repository variables:

```text
TF_STATE_RESOURCE_GROUP
TF_STATE_STORAGE_ACCOUNT
TF_STATE_CONTAINER
```

State keys:

```text
dev/terraform.tfstate
prod/terraform.tfstate
```

Azure Blob leases provide Terraform state locking. GitHub Actions also uses concurrency controls to prevent overlapping DEV apply/destroy runs.

## Main GitHub Actions Workflows

| Workflow | File | Trigger | Purpose |
| --- | --- | --- | --- |
| Bootstrap Terraform Backend | `.github/workflows/bootstrap-backend.yml` | Manual `workflow_dispatch` | Creates or validates the remote Terraform backend storage resources. |
| Terraform Infrastructure - DEV | `.github/workflows/terraform-infra.yml` | Pull request or push to `main` when `modules/**` or `environments/**` change | Runs Checkov, Terraform validate, Terraform fmt, plan, approval, apply, and Slack notification for DEV infrastructure. |
| Terraform Destroy - DEV | `.github/workflows/terraform-destroy.yml` | Manual `workflow_dispatch` | Creates and applies a destroy plan for DEV using `compute-only` or `full` mode. |

Detailed workflow documentation is available in [.github/workflows/terraform-infra.md](.github/workflows/terraform-infra.md).

## Terraform Infrastructure Workflow

The DEV infrastructure workflow runs in stages:

```text
Stage 1: Security and Quality
  - Checkout
  - Checkov scan
  - Terraform init
  - Terraform validate

Stage 2: Format and Plan
  - Terraform fmt check
  - Register required Azure provider features
  - Terraform init
  - Remove unmanaged Key Vault secret state entries
  - Import existing DEV resources when needed
  - Terraform plan
  - Generate plan summary
  - Upload plan artifact
  - Send Slack plan-ready notification

Stage 3: Apply
  - Requires GitHub Environment approval
  - Downloads reviewed plan artifact
  - Applies the saved Terraform plan
  - Waits for Azure RBAC propagation
  - Refreshes AKS credentials
  - Captures outputs and state list

Stage 4: Notification
  - Sends final Slack status summary
```

## Trigger Rules

The DEV infrastructure workflow runs only when these paths change:

```yaml
paths:
  - "modules/**"
  - "environments/**"
```

This means:

- Changes to `terraform/modules/**` trigger the workflow.
- Changes to `terraform/environments/**` trigger the workflow.
- Changes to top-level documentation such as `terraform/README.md` do not trigger the workflow.
- Changes to `.github/workflows/**` do not trigger the Terraform infrastructure workflow.
- A `README.md` added inside `modules/**` or `environments/**` will still trigger the workflow because those folders are watched as a whole.

## Destroy Modes

The destroy workflow is manual only.

`compute-only` mode targets short-lived or expensive resources such as:

- AKS and node pools.
- Application Gateway.
- Bastion.
- Management VM.
- Public IPs.
- NAT Gateway.
- Private endpoints and safe-to-recreate network resources.

`compute-only` preserves long-lived platform resources such as:

- Azure Container Registry.
- Key Vault.
- User Assigned Managed Identities.
- Log Analytics.
- Terraform backend storage.
- Resource group when preserved resources remain.

`full` mode destroys everything managed in the state.

## Identity And Permissions

GitHub Actions authenticates to Azure using OIDC. No Azure client secret is required for the Terraform workflows.

Required GitHub secrets:

```text
AZURE_CLIENT_ID
AZURE_TENANT_ID
AZURE_SUBSCRIPTION_ID
SLACK_WEBHOOK_URL
```

Required GitHub variables:

```text
TF_STATE_RESOURCE_GROUP
TF_STATE_STORAGE_ACCOUNT
TF_STATE_CONTAINER
```

The Azure identity used by GitHub Actions must have permission to:

- read and write Terraform-managed Azure resources;
- create and update Azure RBAC role assignments;
- access the Terraform state backend;
- create or update required Microsoft Entra application registrations, service principals, app role assignments, and federated credentials when those resources are enabled.

## AKS And Helm Integration

Terraform outputs Helm-facing configuration through sensitive outputs, including:

- ACR login server.
- Key Vault name and URI.
- Cosmos DB endpoint and database name.
- Storage endpoint and container name.
- Service Bus namespace and topic.
- Azure OpenAI endpoint and deployment names.
- Azure AI Search endpoint.
- Application Insights connection string.
- Workload Identity client IDs.
- Entra application client IDs and audiences.

The Helm repository consumes these values to deploy the FinOpsIQ application into AKS.

## Local Validation

Run validation from an environment root:

```bash
cd terraform/environments/dev
terraform fmt -recursive ../..
terraform init
terraform validate
terraform plan
```

Use the backend configuration values for remote state when running against the shared backend.

## What This Repository Does Not Do

- It does not build Docker images.
- It does not push images to Azure Container Registry.
- It does not update Helm image tags.
- It does not deploy Helm releases.
- It does not sync Argo CD applications.
- It does not contain SaaS application source code.
