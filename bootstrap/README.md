# Terraform Remote Backend Bootstrap

This isolated bootstrap stack creates the Azure Storage backend used by the main FinsOpsIQ Terraform infrastructure.

It is intended to be run once.

It creates:

- Azure Resource Group
- Azure Storage Account with a globally unique generated name
- Private Blob Container for Terraform state

The bootstrap stack intentionally uses local Terraform state. Do not move this stack into the main infrastructure state.

## GitHub workflow

Workflow:

```text
.github/workflows/bootstrap-backend.yml
```

The workflow is manual only:

```yaml
workflow_dispatch
```

## Required GitHub secrets

```text
AZURE_CLIENT_ID
AZURE_TENANT_ID
AZURE_SUBSCRIPTION_ID
```

The workflow uses GitHub OIDC through `azure/login`. No Azure client secret is required.

The workflow also requires repository permission to update GitHub Actions variables. The workflow declares:

```yaml
permissions:
  contents: read
  id-token: write
  actions: write
```

Repository settings must allow GitHub Actions to read and write repository settings used by Actions variables.

## Optional workflow inputs

The workflow allows overriding:

- Azure region
- backend resource group name
- storage account prefix
- state container name

The storage account receives a random suffix to satisfy global uniqueness.

## Run the bootstrap workflow

1. Open GitHub Actions in the infra repository.
2. Select `Bootstrap Terraform Backend`.
3. Click `Run workflow`.
4. Review the generated Terraform outputs in the workflow logs.

The workflow prints:

```text
resource_group_name
storage_account_name
container_name
dev_state_key
prod_state_key
```

## Repository variables populated automatically

After bootstrap completes, the workflow creates or updates these GitHub repository variables automatically using `gh`:

```text
TF_STATE_RESOURCE_GROUP=<resource_group_name output>
TF_STATE_STORAGE_ACCOUNT=<storage_account_name output>
TF_STATE_CONTAINER=<container_name output>
```

The values are read directly from Terraform outputs:

- `resource_group_name`
- `storage_account_name`
- `container_name`

The workflow verifies the variables exist after creation/update and prints a confirmation message.

## Main Terraform backend consumption

The main DEV pipeline already uses:

```text
dev/terraform.tfstate
```

The PROD backend should use:

```text
prod/terraform.tfstate
```

## Local execution, if needed

```powershell
terraform -chdir=bootstrap init
terraform -chdir=bootstrap plan `
  -var="subscription_id=<subscription-id>" `
  -var="tenant_id=<tenant-id>"
terraform -chdir=bootstrap apply -auto-approve `
  -var="subscription_id=<subscription-id>" `
  -var="tenant_id=<tenant-id>"
terraform -chdir=bootstrap output
```

Do not run this stack repeatedly unless you intentionally want to create or reconcile the backend resources.
