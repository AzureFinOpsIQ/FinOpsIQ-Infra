output "resource_group_name" {
  description = "Terraform backend resource group name."
  value       = azurerm_resource_group.terraform_state.name
}

output "storage_account_name" {
  description = "Terraform backend storage account name."
  value       = azurerm_storage_account.terraform_state.name
}

output "container_name" {
  description = "Terraform backend blob container name."
  value       = azurerm_storage_container.terraform_state.name
}

output "dev_state_key" {
  description = "Recommended DEV Terraform state key."
  value       = "dev/terraform.tfstate"
}

output "prod_state_key" {
  description = "Recommended PROD Terraform state key."
  value       = "prod/terraform.tfstate"
}
