# Terraform Remote Backend Bootstrap

This isolated bootstrap stack creates the Azure Storage backend used by the main FinsOpsIQ Terraform infrastructure.

It is intended to be run once.

It creates:

- Azure Resource Group
- Azure Storage Account with a globally unique generated name
- Private Blob Container for Terraform state

The bootstrap stack intentionally uses local Terraform state. Do not move this stack into the main infrastructure state.

## Prerequisite: GitHub OIDC App Registration

Before running the bootstrap workflow, create a Microsoft Entra app registration that GitHub Actions can use to provision Azure infrastructure.

This uses GitHub OIDC federation. Do not create or store a client secret.

### 1. Create the app registration

1. Open the Azure portal.
2. Go to **Microsoft Entra ID**.
3. Go to **App registrations**.
4. Select **New registration**.
5. Use a name such as:

   ```text
   github-finopsiq-infra-dev
   ```

6. Supported account type:

   ```text
   Accounts in this organizational directory only
   ```

7. Redirect URI is not required.
8. Select **Register**.

After registration, copy these values:

```text
Application (client) ID  -> GitHub secret AZURE_CLIENT_ID
Directory (tenant) ID    -> GitHub secret AZURE_TENANT_ID
Azure subscription ID    -> GitHub secret AZURE_SUBSCRIPTION_ID
```

### 2. Create federated credentials for GitHub Actions

In the app registration:

1. Open **Certificates & secrets**.
2. Select **Federated credentials**.
3. Select **Add credential**.
4. Choose **GitHub Actions deploying Azure resources**.
5. Configure:

   ```text
   Organization: AzureFinOpsIQ
   Repository: FinOpsIQ-Infra
   Entity type: Branch
   Branch: main
   ```

6. Name the credential:

   ```text
   github-main
   ```

7. Save.

If pull request validation also needs Azure login, add a second federated credential:

```text
Organization: AzureFinOpsIQ
Repository: FinOpsIQ-Infra
Entity type: Pull request
Name: github-pull-request
```

The underlying OIDC subjects are:

```text
repo:AzureFinOpsIQ/FinOpsIQ-Infra:ref:refs/heads/main
repo:AzureFinOpsIQ/FinOpsIQ-Infra:pull_request
```

Audience:

```text
api://AzureADTokenExchange
```

### 3. Assign Azure permissions

Assign the app registration's service principal permissions at the correct Azure scope.

For initial bootstrap and DEV infrastructure deployment, the recommended minimum starting point is:

```text
Contributor
User Access Administrator
Storage Blob Data Contributor
```

Scope:

```text
DEV Azure subscription
```

`Contributor` allows Terraform to create Azure resources.

`User Access Administrator` is required because the infrastructure stack creates role assignments for managed identities and workload identity integrations.

`Storage Blob Data Contributor` is required because the backend bootstrap disables storage account key authentication and uses Microsoft Entra authentication for Blob container creation and Terraform state access.

For stricter production setups, replace broad subscription permissions with narrower resource-group-scoped permissions after the backend and base resource groups exist.

### 4. Add GitHub repository secrets

In GitHub:

1. Open the `AzureFinOpsIQ/FinOpsIQ-Infra` repository.
2. Go to **Settings**.
3. Go to **Secrets and variables**.
4. Open **Actions**.
5. Add these repository secrets:

```text
AZURE_CLIENT_ID
AZURE_TENANT_ID
AZURE_SUBSCRIPTION_ID
```

Do not add `AZURE_CLIENT_SECRET`.

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

The workflow only needs read access to the repository contents and OIDC token issuance for Azure login:

```yaml
permissions:
  contents: read
  id-token: write
```

Repository variables are intentionally not created automatically by this workflow. The backend values are printed in the workflow summary and should be copied manually into GitHub repository variables.

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

## Repository variables populated manually

After bootstrap completes, the workflow prints the backend values in the GitHub Actions job summary.

For security and operational control, copy these values manually into GitHub repository variables:

```text
TF_STATE_RESOURCE_GROUP=<resource_group_name output>
TF_STATE_STORAGE_ACCOUNT=<storage_account_name output>
TF_STATE_CONTAINER=<container_name output>
```

The values are read directly from Terraform outputs:

- `resource_group_name`
- `storage_account_name`
- `container_name`

To add them:

1. Open the `AzureFinOpsIQ/FinOpsIQ-Infra` repository.
2. Go to **Settings**.
3. Go to **Secrets and variables**.
4. Open **Actions**.
5. Select **Variables**.
6. Create or update:

   ```text
   TF_STATE_RESOURCE_GROUP
   TF_STATE_STORAGE_ACCOUNT
   TF_STATE_CONTAINER
   ```

The main Terraform pipeline consumes these variables during backend initialization.

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
