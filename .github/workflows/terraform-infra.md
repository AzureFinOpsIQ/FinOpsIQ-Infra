# Terraform Infrastructure Pipeline - DEV

Workflow:

```text
.github/workflows/terraform-infra.yml
```

This repository workflow is a thin caller. The implementation is centralized in:

```text
AzureFinOpsIQ/FinOPsIQ-Workflows/.github/workflows/terraform-infra-dev.yml@main
```

Secrets are passed explicitly by name. The caller does not use `secrets: inherit`.

Scope:

- DEV only
- `main` branch only for apply
- Terraform root: `environments/dev`
- Infrastructure only
- No Docker image build
- No Helm deployment
- No application deployment

## Trigger Rules

The workflow runs on:

- pull requests targeting `main`
- pushes to `main`
- daily schedule at `06:00 UTC`

Only changes under these paths trigger push and pull request runs:

```text
modules/**
environments/**
.github/workflows/terraform-infra.yml
```

## Required GitHub Secrets

```text
AZURE_CLIENT_ID
AZURE_TENANT_ID
AZURE_SUBSCRIPTION_ID
SLACK_WEBHOOK_URL
```

No `AZURE_CLIENT_SECRET` is used.

## Required GitHub Variables

```text
TF_STATE_RESOURCE_GROUP
TF_STATE_STORAGE_ACCOUNT
TF_STATE_CONTAINER
```

The DEV state key is fixed:

```text
dev/terraform.tfstate
```

## Required GitHub Environment

Create a GitHub Environment named:

```text
dev
```

Required protection:

- Enable required reviewers.
- Restrict deployment branches to `main`.

The `terraform_apply` job uses:

```yaml
environment: dev
```

This provides the native GitHub manual approval gate before apply.

## Required Azure Federated Credentials

Create federated identity credentials on the Azure application represented by `AZURE_CLIENT_ID`.

Issuer:

```text
https://token.actions.githubusercontent.com
```

Audience:

```text
api://AzureADTokenExchange
```

Subjects:

```text
repo:<OWNER>/<REPO>:ref:refs/heads/main
repo:<OWNER>/<REPO>:pull_request
repo:<OWNER>/<REPO>:environment:dev
```

The `environment:dev` subject is required because the apply job uses the protected GitHub Environment named `dev`.

## Remote Backend

Backend configuration is declared in:

```text
environments/dev/backend.tf
```

The workflow initializes the backend with:

```bash
terraform init \
  -backend-config="resource_group_name=${TF_STATE_RESOURCE_GROUP}" \
  -backend-config="storage_account_name=${TF_STATE_STORAGE_ACCOUNT}" \
  -backend-config="container_name=${TF_STATE_CONTAINER}" \
  -backend-config="key=dev/terraform.tfstate" \
  -backend-config="use_azuread_auth=true"
```

Terraform uses Azure Blob leases for state locking. The workflow also uses:

```yaml
concurrency:
  group: terraform-dev
  cancel-in-progress: false
```

## Deployment Flow

```text
Infrastructure change
  |
  v
Stage 1: Security and Quality
  - Checkov scan, fail HIGH/CRITICAL
  - terraform init
  - terraform validate
  |
  v
Stage 2: Terraform Format, Plan and Slack
  - terraform fmt -check -recursive
  - terraform init
  - import existing DEV resources into state
  - terraform plan -out=dev.tfplan
  - generate add/modify/destroy summary
  - upload saved plan artifact
  - Slack PLAN READY notification with View workflow button
  |
  v
Stage 3: Terraform Apply
  - waits for GitHub Environment approval: dev
  - terraform init on the fresh runner
  - downloads the reviewed dev.tfplan artifact
  - terraform apply -auto-approve dev.tfplan
  - captures terraform output and state list
  |
  v
Stage 4: Slack Notification
  - sends SUCCESS, FAILED, or SKIPPED summary
  - includes View workflow button
```

## Why `terraform init` still runs in apply

GitHub Actions jobs run on fresh runners. The apply job does not inherit the `.terraform` directory, backend configuration, provider plugins, or authentication context from the plan job.

The apply job must run `terraform init` so it can connect to the remote AzureRM backend and acquire the state lock.

It does not regenerate the plan. It downloads and applies the reviewed artifact:

```text
dev.tfplan
```

This preserves the reviewed-plan promotion flow.

## Slack Messages

### Plan Ready

Includes:

- Environment
- Repository
- Commit
- Author
- Plan summary
- Cost-estimation placeholder
- View workflow button

### Final Notification

Includes:

- SUCCESS, FAILED, or SKIPPED
- Resources created
- Resources updated
- Resources destroyed
- State resource count
- Deployment duration
- Failed/skipped stage if applicable
- View workflow button

## Drift Detection

Scheduled drift detection runs daily:

```bash
terraform plan -detailed-exitcode
```

Behavior:

| Exit Code | Meaning | Pipeline Behavior |
|---:|---|---|
| 0 | No drift | Publish no-drift summary |
| 2 | Drift detected | Send Slack alert; do not apply |
| 1 | Failure | Send Slack failure alert |

Scheduled drift detection never applies changes.

## Notes

- Pull requests run security, quality, format, and plan only.
- Apply only runs for push events on `main` after the protected GitHub Environment `dev` is manually reviewed and approved.
- The saved plan artifact is retained for one day.
- Output summaries do not print sensitive output values.
- This workflow does not build Docker images, push containers, run Helm, or deploy Kubernetes workloads.
