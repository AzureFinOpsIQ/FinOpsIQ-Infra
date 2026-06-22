resource "azurerm_cosmosdb_sql_role_assignment" "this" {
  for_each = var.role_assignments

  resource_group_name = var.resource_group_name
  account_name        = var.account_name
  role_definition_id  = each.value.role_definition_id == null ? "${var.account_id}/sqlRoleDefinitions/00000000-0000-0000-0000-000000000002" : each.value.role_definition_id
  principal_id        = each.value.principal_id
  scope               = each.value.scope == null ? var.database_scope : each.value.scope
}
