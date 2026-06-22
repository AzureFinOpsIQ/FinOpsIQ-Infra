resource "azurerm_container_registry" "this" {
  #checkov:skip=CKV_AZURE_139:DEV ACR remains publicly reachable for GitHub-hosted CI runners; restrict with private networking for production runners.
  #checkov:skip=CKV_AZURE_164:ACR content trust is deprecated by Azure; image signing should be implemented with a modern signing workflow such as Notation/SBOM policy.
  #checkov:skip=CKV_AZURE_165:DEV uses a single Azure region; geo-replication is a production DR decision and is not required for this DEV deployment.
  #checkov:skip=CKV_AZURE_166:ACR quarantine is not enabled for DEV; image verification will be handled by CI scanning/signing policy before production promotion.
  #checkov:skip=CKV_AZURE_167:Untagged manifest cleanup is handled outside the current DEV registry module; production lifecycle policy will be added when image retention policy is finalized.
  #checkov:skip=CKV_AZURE_233:Zone redundancy is not required for the DEV registry; production can enable this where region/SKU support and availability requirements justify it.
  #checkov:skip=CKV_AZURE_237:Dedicated data endpoints are not required for this DEV registry because private endpoint-based image pulls are not enabled yet.

  name                = var.name
  resource_group_name = var.resource_group_name
  location            = var.location
  sku                 = var.sku
  admin_enabled       = false
  tags                = var.tags
}
