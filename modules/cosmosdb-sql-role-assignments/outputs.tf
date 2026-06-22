output "role_assignment_ids" {
  description = "Cosmos DB SQL role assignment IDs keyed by logical name."
  value       = { for key, assignment in azurerm_cosmosdb_sql_role_assignment.this : key => assignment.id }
}
