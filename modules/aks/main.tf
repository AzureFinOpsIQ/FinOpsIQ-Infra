resource "azurerm_kubernetes_cluster" "this" {
  name                      = var.name
  resource_group_name       = var.resource_group_name
  location                  = var.location
  dns_prefix                = var.dns_prefix
  kubernetes_version        = var.kubernetes_version
  automatic_upgrade_channel = "stable"
  sku_tier                  = "Standard"
  private_cluster_enabled   = var.private_cluster_enabled
  private_dns_zone_id       = var.private_dns_zone_id
  oidc_issuer_enabled       = true
  workload_identity_enabled = true
  azure_policy_enabled      = true
  local_account_disabled    = true
  disk_encryption_set_id    = var.disk_encryption_set_id
  tags                      = var.tags

  default_node_pool {
    name                         = var.system_node_pool.name
    vm_size                      = var.system_node_pool.vm_size
    vnet_subnet_id               = var.aks_subnet_id
    auto_scaling_enabled         = var.system_node_pool.enable_auto_scaling
    node_count                   = var.system_node_pool.node_count
    min_count                    = var.system_node_pool.min_count
    max_count                    = var.system_node_pool.max_count
    max_pods                     = 50
    os_disk_type                 = "Ephemeral"
    os_disk_size_gb              = var.system_node_pool.os_disk_size_gb
    host_encryption_enabled      = true
    only_critical_addons_enabled = true
    temporary_name_for_rotation  = var.system_node_pool.temporary_name_for_rotation
  }

  identity {
    type = "SystemAssigned"
  }

  network_profile {
    network_plugin      = "azure"
    network_plugin_mode = var.network_plugin_mode
    network_policy      = var.network_policy
    service_cidr        = var.service_cidr
    dns_service_ip      = var.dns_service_ip
  }

  azure_active_directory_role_based_access_control {
    azure_rbac_enabled = var.azure_rbac_enabled
    tenant_id          = var.tenant_id
  }

  oms_agent {
    log_analytics_workspace_id = var.log_analytics_workspace_id
  }

  dynamic "monitor_metrics" {
    for_each = var.managed_prometheus_enabled ? [1] : []

    content {
      annotations_allowed = var.monitor_metrics_annotations_allowed
      labels_allowed      = var.monitor_metrics_labels_allowed
    }
  }

  dynamic "key_vault_secrets_provider" {
    for_each = var.key_vault_secrets_provider_enabled ? [1] : []

    content {
      secret_rotation_enabled  = var.key_vault_secret_rotation_enabled
      secret_rotation_interval = var.key_vault_secret_rotation_interval
    }
  }

  dynamic "ingress_application_gateway" {
    for_each = var.ingress_application_gateway_id == null ? [] : [var.ingress_application_gateway_id]

    content {
      gateway_id = ingress_application_gateway.value
    }
  }
}

resource "azurerm_kubernetes_cluster_node_pool" "user" {
  for_each = var.user_node_pools

  name                    = each.value.name
  kubernetes_cluster_id   = azurerm_kubernetes_cluster.this.id
  vm_size                 = each.value.vm_size
  vnet_subnet_id          = var.aks_subnet_id
  mode                    = "User"
  auto_scaling_enabled    = each.value.enable_auto_scaling
  node_count              = each.value.node_count
  min_count               = each.value.min_count
  max_count               = each.value.max_count
  max_pods                = 50
  os_disk_type            = "Ephemeral"
  os_disk_size_gb         = each.value.os_disk_size_gb
  host_encryption_enabled = true
  tags                    = var.tags
}
