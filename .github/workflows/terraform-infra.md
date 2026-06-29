# FinOpsIQ Terraform GitHub Actions Workflows

This document explains the Terraform workflows used to manage FinOpsIQ Azure infrastructure.

Terraform workflows manage infrastructure only. Application image builds, Helm chart changes, and Argo CD synchronization are handled outside this Terraform workflow set.

## Workflow Summary

| Workflow | File | Trigger | Environment | Purpose |
| --- | --- | --- | --- | --- |
| Bootstrap Terraform Backend | `bootstrap-backend.yml` | Manual `workflow_dispatch` | Backend/platform | Creates the Azure Storage backend used for Terraform remote state. |
| Terraform Infrastructure - DEV | `terraform-infra.yml` | Pull request or push to `main` for selected Terraform paths | DEV | Validates, scans, plans, approves, and applies DEV infrastructure. |
| Terraform Destroy - DEV | `terraform-destroy.yml` | Manual `workflow_dispatch` | DEV | Destroys DEV infrastructure using `compute-only` or `full` mode. |

## Shared Authentication Model

All Terraform workflows authenticate to Azure using GitHub OIDC.

Required workflow permissions:

```yaml
permissions:
  contents: read
  id-token: write
```

Required GitHub secrets:

```text
AZURE_CLIENT_ID
AZURE_TENANT_ID
AZURE_SUBSCRIPTION_ID
```

The infrastructure workflow also uses:

```text
SLACK_WEBHOOK_URL
```

Required GitHub repository variables:

```text
TF_STATE_RESOURCE_GROUP
TF_STATE_STORAGE_ACCOUNT
TF_STATE_CONTAINER
```

The Azure application or managed identity represented by `AZURE_CLIENT_ID` must have matching Federated Identity Credentials for the workflow subjects that run the jobs.

Common subjects:

```text
repo:<OWNER>/<REPO>:ref:refs/heads/main
repo:<OWNER>/<REPO>:pull_request
repo:<OWNER>/<REPO>:environment:dev
```

Use an additional tag subject when release workflows authenticate from tags:

```text
repo:<OWNER>/<REPO>:ref:refs/tags/<TAG>
```

## Bootstrap Terraform Backend

Workflow file:

```text
.github/workflows/bootstrap-backend.yml
```

Trigger:

```text
workflow_dispatch
```

Purpose:

- Create the Terraform backend resource group.
- Create the backend storage account.
- Create the blob container for Terraform state.
- Output values that must be copied into GitHub repository variables.

Manual inputs:

- Azure region.
- Backend resource group name.
- Storage account prefix.
- State container name.

Main flow:

```text
Manual run
  -> Azure login with OIDC
  -> Terraform init in bootstrap/
  -> Terraform validate
  -> Terraform plan
  -> Terraform apply
  -> Print backend outputs
  -> Upload bootstrap outputs artifact
```

The backend workflow should be run before the normal infrastructure pipeline if the remote state backend does not already exist.

## Terraform Infrastructure - DEV

Workflow file:

```text
.github/workflows/terraform-infra.yml
```

Scope:

- DEV infrastructure only.
- Terraform root module: `environments/dev`.
- Applies only from `main`.
- Pull requests run validation and planning only.

Trigger:

```yaml
on:
  pull_request:
    branches:
      - main
    paths:
      - "modules/**"
      - "environments/**"
  push:
    branches:
      - main
    paths:
      - "modules/**"
      - "environments/**"
```

Path behavior:

- Changes under `modules/**` trigger the workflow.
- Changes under `environments/**` trigger the workflow.
- Top-level docs such as `README.md` do not trigger the workflow.
- Workflow-only changes under `.github/workflows/**` do not trigger this workflow.
- Markdown files inside `modules/**` or `environments/**` still trigger because those directories are watched.

Concurrency:

```yaml
concurrency:
  group: terraform-dev
  cancel-in-progress: false
```

### Stage 1 - Security And Quality

Runs:

- Checkout.
- Checkov Terraform scan.
- Upload Checkov SARIF artifact.
- Terraform setup.
- Azure login with OIDC.
- Terraform init.
- Terraform validate.

Purpose:

- Fail early on security or Terraform validation issues.
- Ensure the DEV root can initialize against the remote backend.

### Stage 2 - Terraform Format, Plan, And Slack

Runs:

- Checkout.
- Terraform setup.
- Azure login with OIDC.
- `terraform fmt -check -recursive .`
- Ensure required Azure provider features are registered.
- Terraform init.
- Remove unmanaged Key Vault secret entries from Terraform state when needed.
- Import existing DEV resources into state when needed.
- Terraform plan with lock timeout.
- Generate plan summary.
- Upload reviewed plan artifact.
- Send Slack plan-ready notification for push to `main`.

Plan artifact:

```text
environments/dev/dev.tfplan
```

Plan summary:

```text
environments/dev/plan-summary.txt
```

### Stage 3 - Terraform Apply

Runs only when:

```text
github.event_name == 'push'
github.ref == 'refs/heads/main'
```

Uses GitHub Environment:

```yaml
environment: dev
```

Purpose:

- Require manual approval through the protected GitHub Environment.
- Download the reviewed Terraform plan artifact.
- Apply exactly the reviewed `dev.tfplan`.
- Wait for Azure RBAC propagation.
- Refresh AKS credentials.
- Capture Terraform outputs and state list.
- Upload post-apply artifacts.

Important behavior:

- The apply job runs `terraform init` again because each GitHub Actions job runs on a fresh runner.
- The apply job does not generate a new plan.
- The apply job applies the saved plan artifact created by Stage 2.

### Stage 4 - Slack Notification

Runs after the previous stages and reports:

- SUCCESS, FAILED, or SKIPPED.
- Resources created.
- Resources updated.
- Resources destroyed.
- Terraform state resource count.
- Deployment duration.
- Failed or skipped stage.
- Link to the workflow run.

## Terraform Destroy - DEV

Workflow file:

```text
.github/workflows/terraform-destroy.yml
```

Trigger:

```text
workflow_dispatch
```

Required confirmation:

```text
confirm_destroy = Yes
```

Destroy mode input:

```text
compute-only
full
```

Concurrency:

```yaml
concurrency:
  group: terraform-dev
  cancel-in-progress: false
```

This prevents the destroy workflow from running at the same time as DEV apply.

### Compute-Only Destroy

`compute-only` is the default. It targets short-lived and expensive resources that are safe to recreate.

Typical destroyed resources:

- AKS.
- Node pools.
- AKS private DNS resources.
- Application Gateway.
- Bastion.
- Management VM.
- Network resources that are safe to recreate.
- Private endpoints.
- Selected role assignments tied to recreated compute or networking.

Preserved resources:

- Azure Container Registry.
- Key Vault.
- User Assigned Managed Identities.
- Log Analytics.
- Terraform backend storage account.
- Resource group when preserved resources remain.
- Other long-lived shared platform resources.

### Full Destroy

`full` destroy plans and destroys everything managed in the Terraform state.

Use this only when the entire environment should be removed.

### Destroy Flow

```text
Manual run
  -> Confirm "Yes"
  -> Select destroy_mode
  -> Azure login with OIDC
  -> Terraform init
  -> Remove unmanaged Key Vault secret state entries
  -> Terraform validate
  -> Build destroy target arguments
  -> Terraform destroy plan
  -> Summarize resources to destroy and preserve
  -> Manual approval gate
  -> Apply reviewed destroy plan
  -> Upload destroy artifacts
```

## Workflow Responsibilities

| Responsibility | Workflow |
| --- | --- |
| Create Terraform state backend | `bootstrap-backend.yml` |
| Validate infrastructure code | `terraform-infra.yml` |
| Run Checkov security scan | `terraform-infra.yml` |
| Generate DEV plan | `terraform-infra.yml` |
| Apply DEV plan after approval | `terraform-infra.yml` |
| Destroy DEV compute-only resources | `terraform-destroy.yml` |
| Destroy full DEV stack | `terraform-destroy.yml` |
| Build application images | Not handled here |
| Push images to ACR | Not handled here |
| Update Helm image tags | Not handled here |
| Deploy application with Helm or Argo CD | Not handled here |

## Artifacts

Infrastructure workflow artifacts:

- Checkov SARIF report.
- Terraform plan file.
- Terraform plan summary.
- Terraform outputs summary.
- Terraform state list.

Destroy workflow artifacts:

- Destroy target selection summary.
- Destroy plan.
- Destroy summary.

Bootstrap workflow artifacts:

- Backend bootstrap output JSON.

## Failure Points To Check

If Azure login fails:

- Confirm the GitHub OIDC subject matches the Azure Federated Identity Credential.
- Confirm `AZURE_CLIENT_ID`, `AZURE_TENANT_ID`, and `AZURE_SUBSCRIPTION_ID` are correct.

If Terraform init fails:

- Confirm backend variables are set.
- Confirm the backend storage account and container exist.
- Confirm the deployment identity can access the state backend.

If Checkov fails:

- Review the failed check ID.
- Fix the Terraform resource where possible.
- Only skip a check when there is a clear architectural reason.

If apply fails after RBAC changes:

- Wait for Azure RBAC propagation.
- Re-run the workflow after permissions are visible.

If destroy mode looks unsafe:

- Stop before approval.
- Review the plan artifact.
- Use `compute-only` when preserving platform resources is required.

## Notes

- Pull requests do not apply infrastructure.
- Pushes to `main` can apply DEV infrastructure after the GitHub Environment approval gate.
- Destroy is always manual.
- Documentation-only changes outside `modules/**` and `environments/**` do not trigger the infrastructure workflow.
- This workflow set intentionally avoids application deployment responsibilities.
