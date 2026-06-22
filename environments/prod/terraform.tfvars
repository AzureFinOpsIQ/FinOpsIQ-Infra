subscription_id     = "e54a7ca3-4b6b-4b0f-889d-2508c85f4f30"
tenant_id           = "22dc2419-3ab3-4f27-905a-945315d19d95"
environment         = "prod"
location            = "eastus2"
resource_group_name = "rg-finopsiq-prod"
owner               = "platform"
helm_namespace      = "finopsiq-prod"

extra_tags = {
  Project    = "FinsOpsIQ"
  CostCenter = "FinOps"
}

network = {
  name          = "vnet-finopsiq-prod"
  address_space = ["10.50.0.0/16"]
  subnets = {
    aks = {
      name              = "snet-aks"
      address_prefixes  = ["10.50.0.0/22"]
      service_endpoints = ["Microsoft.KeyVault", "Microsoft.Storage", "Microsoft.AzureCosmosDB"]
    }
  }
}

monitor = {
  name              = "log-finopsiq-prod"
  sku               = "PerGB2018"
  retention_in_days = 90
}

application_insights = {
  name             = "appi-finopsiq-prod"
  application_type = "web"
}

acr = {
  name = "acrfinopsiqprod"
  sku  = "Premium"
}

keyvault = {
  name                          = "kv-finopsiq-prod"
  sku_name                      = "standard"
  enable_rbac_authorization     = true
  purge_protection_enabled      = true
  soft_delete_retention_days    = 90
  public_network_access_enabled = false
}

cosmosdb = {
  account_name                  = "cosmos-finopsiq-prod"
  database_name                 = "finopsiq"
  consistency_level             = "Session"
  database_throughput           = null
  public_network_access_enabled = false
  local_authentication_disabled = true
  free_tier_enabled             = false
  containers = {
    tenants            = { name = "tenants", partition_key_paths = ["/tenantId"] }
    subscriptions      = { name = "subscriptions", partition_key_paths = ["/tenantId"] }
    tenantUsers        = { name = "tenantUsers", partition_key_paths = ["/tenantId"] }
    tenantHealth       = { name = "tenantHealth", partition_key_paths = ["/tenantId"] }
    costFacts          = { name = "costFacts", partition_key_paths = ["/tenantId"] }
    resources          = { name = "resources", partition_key_paths = ["/tenantId"] }
    recommendations    = { name = "recommendations", partition_key_paths = ["/tenantId"] }
    processingMetadata = { name = "processingMetadata", partition_key_paths = ["/tenantId"] }
    rawPayloads        = { name = "rawPayloads", partition_key_paths = ["/tenantId"] }
    authSessions       = { name = "authSessions", partition_key_paths = ["/tenantId"] }
    auditEvents        = { name = "auditEvents", partition_key_paths = ["/tenantId"] }
  }
}

servicebus = {
  namespace_name = "sb-finopsiq-prod"
  topic_name     = "finops-events"
  sku            = "Premium"
  capacity       = 1
}

storage = {
  account_name                  = "stfinopsiqprod"
  container_name                = "finops-raw"
  account_tier                  = "Standard"
  account_replication_type      = "ZRS"
  public_network_access_enabled = false
}

ai_search = {
  location                      = "eastus"
  name                          = "search-finopsiq-prod"
  sku                           = "standard"
  replica_count                 = 2
  partition_count               = 1
  public_network_access_enabled = false
  local_authentication_enabled  = false
}

openai = {
  name                          = "oai-finopsiq-prod"
  sku_name                      = "S0"
  custom_subdomain_name         = "oai-finopsiq-prod"
  public_network_access_enabled = false
  local_auth_enabled            = false
  deployments = {
    chat = {
      name          = "gpt-4.1-mini"
      model_format  = "OpenAI"
      model_name    = "gpt-4.1-mini"
      model_version = "2025-04-14"
      sku_name      = "GlobalStandard"
      capacity      = 20
    }
    embeddings = {
      name          = "text-embedding-3-small"
      model_format  = "OpenAI"
      model_name    = "text-embedding-3-small"
      model_version = "1"
      sku_name      = "Standard"
      capacity      = 20
    }
  }
}

managed_identities = {
  auth         = { name = "id-finopsiq-prod-auth" }
  collection   = { name = "id-finopsiq-prod-collection" }
  processing   = { name = "id-finopsiq-prod-processing" }
  ai           = { name = "id-finopsiq-prod-ai" }
  notification = { name = "id-finopsiq-prod-notification" }
}

workload_service_accounts = {
  auth         = "auth-service"
  collection   = "collection-service"
  processing   = "processing-service"
  ai           = "ai-service"
  notification = "notification-service"
}

aks = {
  name               = "aks-finopsiq-prod"
  dns_prefix         = "aks-finopsiq-prod"
  kubernetes_version = "1.34"
  subnet_key         = "aks"
  network_policy     = "azure"
  service_cidr       = "10.51.0.0/16"
  dns_service_ip     = "10.51.0.10"
  azure_rbac_enabled = true
  system_node_pool = {
    name                = "system"
    vm_size             = "Standard_D2s_v3"
    node_count          = 1
    enable_auto_scaling = true
    min_count           = 1
    max_count           = 5
    max_pods            = 50
    os_disk_size_gb     = 64
  }
  user_node_pools = {
    workload = {
      name                = "workload"
      vm_size             = "Standard_D2s_v3"
      node_count          = 1
      enable_auto_scaling = true
      min_count           = 1
      max_count           = 5
      max_pods            = 50
      os_disk_size_gb     = 128
    }
  }
}
