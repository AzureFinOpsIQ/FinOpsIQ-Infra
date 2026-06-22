output "namespace_id" {
  description = "Service Bus namespace resource ID."
  value       = azurerm_servicebus_namespace.this.id
}

output "namespace_name" {
  description = "Service Bus namespace name."
  value       = azurerm_servicebus_namespace.this.name
}

output "topic_id" {
  description = "Service Bus topic resource ID."
  value       = azurerm_servicebus_topic.this.id
}

output "topic_name" {
  description = "Service Bus topic name."
  value       = azurerm_servicebus_topic.this.name
}

output "subscription_ids" {
  description = "Service Bus subscription IDs keyed by subscription name."
  value       = { for key, subscription in azurerm_servicebus_subscription.this : key => subscription.id }
}

output "subscription_names" {
  description = "Service Bus subscription names."
  value       = keys(azurerm_servicebus_subscription.this)
}
