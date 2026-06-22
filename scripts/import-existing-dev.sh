#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
TF_WORKING_DIR="${TF_WORKING_DIR:-environments/dev}"
TF_DIR="${REPO_ROOT}/${TF_WORKING_DIR}"
TFVARS_FILE="${TFVARS_FILE:-terraform.tfvars}"

if ! command -v az >/dev/null 2>&1; then
  echo "Azure CLI is required for import discovery." >&2
  exit 1
fi

if ! command -v jq >/dev/null 2>&1; then
  echo "jq is required for parsing Terraform variable values." >&2
  exit 1
fi

tf_expr() {
  terraform -chdir="${TF_DIR}" console -var-file="${TFVARS_FILE}" <<< "$1" | jq -r .
}

state_has() {
  terraform -chdir="${TF_DIR}" state show "$1" >/dev/null 2>&1
}

import_if_arm_exists() {
  local address="$1"
  local resource_id="$2"

  if state_has "${address}"; then
    echo "STATE OK: ${address}"
    return 0
  fi

  if az resource show --ids "${resource_id}" >/dev/null 2>&1; then
    echo "IMPORT: ${address}"
    terraform -chdir="${TF_DIR}" import -input=false "${address}" "${resource_id}"
  else
    echo "MISSING: ${address}"
  fi
}

import_if_group_exists() {
  local address="$1"
  local subscription_id="$2"
  local resource_group_name="$3"
  local resource_id="/subscriptions/${subscription_id}/resourceGroups/${resource_group_name}"

  if state_has "${address}"; then
    echo "STATE OK: ${address}"
    return 0
  fi

  if az group show --name "${resource_group_name}" >/dev/null 2>&1; then
    echo "IMPORT: ${address}"
    terraform -chdir="${TF_DIR}" import -input=false "${address}" "${resource_id}"
  else
    echo "MISSING: ${address}"
  fi
}

import_if_storage_container_exists() {
  local address="$1"
  local storage_account_name="$2"
  local container_name="$3"
  local import_id="https://${storage_account_name}.blob.core.windows.net/${container_name}"

  if state_has "${address}"; then
    echo "STATE OK: ${address}"
    return 0
  fi

  if az storage container show \
    --account-name "${storage_account_name}" \
    --name "${container_name}" \
    --auth-mode login >/dev/null 2>&1; then
    echo "IMPORT: ${address}"
    terraform -chdir="${TF_DIR}" import -input=false "${address}" "${import_id}"
  else
    echo "MISSING: ${address}"
  fi
}

subscription_id="$(tf_expr 'var.subscription_id')"
resource_group_name="$(tf_expr 'var.resource_group_name')"

network_json="$(tf_expr 'jsonencode(var.network)' | jq -r .)"
monitor_json="$(tf_expr 'jsonencode(var.monitor)' | jq -r .)"
application_insights_json="$(tf_expr 'jsonencode(var.application_insights)' | jq -r .)"
acr_json="$(tf_expr 'jsonencode(var.acr)' | jq -r .)"
keyvault_json="$(tf_expr 'jsonencode(var.keyvault)' | jq -r .)"
cosmosdb_json="$(tf_expr 'jsonencode(var.cosmosdb)' | jq -r .)"
servicebus_json="$(tf_expr 'jsonencode(var.servicebus)' | jq -r .)"
storage_json="$(tf_expr 'jsonencode(var.storage)' | jq -r .)"
ai_search_json="$(tf_expr 'jsonencode(var.ai_search)' | jq -r .)"
openai_json="$(tf_expr 'jsonencode(var.openai)' | jq -r .)"
managed_identities_json="$(tf_expr 'jsonencode(var.managed_identities)' | jq -r .)"
workload_service_accounts_json="$(tf_expr 'jsonencode(var.workload_service_accounts)' | jq -r .)"
aks_json="$(tf_expr 'jsonencode(var.aks)' | jq -r .)"
environment="$(tf_expr 'var.environment')"

base_id="/subscriptions/${subscription_id}/resourceGroups/${resource_group_name}/providers"

vnet_name="$(jq -r '.name' <<< "${network_json}")"
monitor_name="$(jq -r '.name' <<< "${monitor_json}")"
application_insights_name="$(jq -r '.name' <<< "${application_insights_json}")"
acr_name="$(jq -r '.name' <<< "${acr_json}")"
keyvault_name="$(jq -r '.name' <<< "${keyvault_json}")"
cosmos_account_name="$(jq -r '.account_name' <<< "${cosmosdb_json}")"
cosmos_database_name="$(jq -r '.database_name' <<< "${cosmosdb_json}")"
servicebus_namespace_name="$(jq -r '.namespace_name' <<< "${servicebus_json}")"
servicebus_topic_name="$(jq -r '.topic_name' <<< "${servicebus_json}")"
storage_account_name="$(jq -r '.account_name' <<< "${storage_json}")"
storage_container_name="$(jq -r '.container_name' <<< "${storage_json}")"
search_name="$(jq -r '.name' <<< "${ai_search_json}")"
openai_name="$(jq -r '.name' <<< "${openai_json}")"
aks_name="$(jq -r '.name' <<< "${aks_json}")"

import_if_group_exists \
  'module.resource_group.azurerm_resource_group.this' \
  "${subscription_id}" \
  "${resource_group_name}"

import_if_arm_exists \
  'module.network.azurerm_virtual_network.this' \
  "${base_id}/Microsoft.Network/virtualNetworks/${vnet_name}"

jq -r '.subnets | keys[]' <<< "${network_json}" | while read -r subnet_key; do
  subnet_name="$(jq -r --arg key "${subnet_key}" '.subnets[$key].name' <<< "${network_json}")"
  import_if_arm_exists \
    "module.network.azurerm_subnet.this[\"${subnet_key}\"]" \
    "${base_id}/Microsoft.Network/virtualNetworks/${vnet_name}/subnets/${subnet_name}"
done

import_if_arm_exists \
  'module.monitor.azurerm_log_analytics_workspace.this' \
  "${base_id}/Microsoft.OperationalInsights/workspaces/${monitor_name}"

import_if_arm_exists \
  'module.application_insights.azurerm_application_insights.this' \
  "${base_id}/Microsoft.Insights/components/${application_insights_name}"

import_if_arm_exists \
  'module.acr.azurerm_container_registry.this' \
  "${base_id}/Microsoft.ContainerRegistry/registries/${acr_name}"

import_if_arm_exists \
  'module.keyvault.azurerm_key_vault.this' \
  "${base_id}/Microsoft.KeyVault/vaults/${keyvault_name}"

import_if_arm_exists \
  'module.cosmosdb.azurerm_cosmosdb_account.this' \
  "${base_id}/Microsoft.DocumentDB/databaseAccounts/${cosmos_account_name}"

import_if_arm_exists \
  'module.cosmosdb.azurerm_cosmosdb_sql_database.this' \
  "${base_id}/Microsoft.DocumentDB/databaseAccounts/${cosmos_account_name}/sqlDatabases/${cosmos_database_name}"

jq -r '.containers | keys[]' <<< "${cosmosdb_json}" | while read -r container_key; do
  container_name="$(jq -r --arg key "${container_key}" '.containers[$key].name' <<< "${cosmosdb_json}")"
  import_if_arm_exists \
    "module.cosmosdb.azurerm_cosmosdb_sql_container.this[\"${container_key}\"]" \
    "${base_id}/Microsoft.DocumentDB/databaseAccounts/${cosmos_account_name}/sqlDatabases/${cosmos_database_name}/containers/${container_name}"
done

import_if_arm_exists \
  'module.servicebus.azurerm_servicebus_namespace.this' \
  "${base_id}/Microsoft.ServiceBus/namespaces/${servicebus_namespace_name}"

import_if_arm_exists \
  'module.servicebus.azurerm_servicebus_topic.this' \
  "${base_id}/Microsoft.ServiceBus/namespaces/${servicebus_namespace_name}/topics/${servicebus_topic_name}"

import_if_arm_exists \
  'module.storage.azurerm_storage_account.this' \
  "${base_id}/Microsoft.Storage/storageAccounts/${storage_account_name}"

import_if_storage_container_exists \
  'module.storage.azurerm_storage_container.this' \
  "${storage_account_name}" \
  "${storage_container_name}"

import_if_arm_exists \
  'module.ai_search.azurerm_search_service.this' \
  "${base_id}/Microsoft.Search/searchServices/${search_name}"

import_if_arm_exists \
  'module.openai.azurerm_cognitive_account.this' \
  "${base_id}/Microsoft.CognitiveServices/accounts/${openai_name}"

jq -r '.deployments | keys[]' <<< "${openai_json}" | while read -r deployment_key; do
  deployment_name="$(jq -r --arg key "${deployment_key}" '.deployments[$key].name' <<< "${openai_json}")"
  import_if_arm_exists \
    "module.openai.azurerm_cognitive_deployment.this[\"${deployment_key}\"]" \
    "${base_id}/Microsoft.CognitiveServices/accounts/${openai_name}/deployments/${deployment_name}"
done

jq -r 'keys[]' <<< "${managed_identities_json}" | while read -r identity_key; do
  identity_name="$(jq -r --arg key "${identity_key}" '.[$key].name' <<< "${managed_identities_json}")"
  import_if_arm_exists \
    "module.managed_identity.azurerm_user_assigned_identity.this[\"${identity_key}\"]" \
    "${base_id}/Microsoft.ManagedIdentity/userAssignedIdentities/${identity_name}"
done

import_if_arm_exists \
  'module.aks.azurerm_kubernetes_cluster.this' \
  "${base_id}/Microsoft.ContainerService/managedClusters/${aks_name}"

jq -r '.user_node_pools | keys[]' <<< "${aks_json}" | while read -r pool_key; do
  pool_name="$(jq -r --arg key "${pool_key}" '.user_node_pools[$key].name' <<< "${aks_json}")"
  import_if_arm_exists \
    "module.aks.azurerm_kubernetes_cluster_node_pool.user[\"${pool_key}\"]" \
    "${base_id}/Microsoft.ContainerService/managedClusters/${aks_name}/agentPools/${pool_name}"
done

jq -r 'keys[]' <<< "${workload_service_accounts_json}" | while read -r identity_key; do
  identity_name="$(jq -r --arg key "${identity_key}" '.[$key].name' <<< "${managed_identities_json}")"
  fic_name="${environment}-${identity_key}-fic"
  import_if_arm_exists \
    "module.workload_identity.azurerm_federated_identity_credential.this[\"${identity_key}\"]" \
    "${base_id}/Microsoft.ManagedIdentity/userAssignedIdentities/${identity_name}/federatedIdentityCredentials/${fic_name}"
done

echo "Existing DEV resource import discovery completed."
