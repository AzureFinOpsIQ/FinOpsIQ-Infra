resource "azurerm_dashboard_grafana" "this" {
  name                              = var.name
  resource_group_name               = var.resource_group_name
  location                          = var.location
  sku                               = var.sku
  grafana_major_version             = var.grafana_major_version
  api_key_enabled                   = var.api_key_enabled
  deterministic_outbound_ip_enabled = var.deterministic_outbound_ip_enabled
  public_network_access_enabled     = var.public_network_access_enabled
  tags                              = var.tags

  identity {
    type = "SystemAssigned"
  }

  azure_monitor_workspace_integrations {
    resource_id = var.azure_monitor_workspace_id
  }
}
