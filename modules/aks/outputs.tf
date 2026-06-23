output "id" {
  description = "AKS cluster resource ID."
  value       = azurerm_kubernetes_cluster.this.id
}

output "aks_id" {
  description = "AKS cluster resource ID."
  value       = azurerm_kubernetes_cluster.this.id
}

output "name" {
  description = "AKS cluster name."
  value       = azurerm_kubernetes_cluster.this.name
}

output "oidc_issuer_url" {
  description = "AKS OIDC issuer URL for Workload Identity."
  value       = azurerm_kubernetes_cluster.this.oidc_issuer_url
}

output "kubelet_identity_object_id" {
  description = "AKS kubelet identity object ID."
  value       = azurerm_kubernetes_cluster.this.kubelet_identity[0].object_id
}

output "node_resource_group" {
  description = "AKS node resource group."
  value       = azurerm_kubernetes_cluster.this.node_resource_group
}

output "aks_private_fqdn" {
  description = "Private FQDN for the AKS API server."
  value       = azurerm_kubernetes_cluster.this.private_fqdn
}

output "user_node_pool_ids" {
  description = "User node pool IDs keyed by logical name."
  value       = { for key, pool in azurerm_kubernetes_cluster_node_pool.user : key => pool.id }
}

output "ingress_application_gateway_identity_object_id" {
  description = "Object ID for the AGIC managed identity created by the AKS ingress application gateway add-on."
  value       = try(azurerm_kubernetes_cluster.this.ingress_application_gateway[0].ingress_application_gateway_identity[0].object_id, null)
}
