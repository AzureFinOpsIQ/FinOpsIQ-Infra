subscription_id     = "e54a7ca3-4b6b-4b0f-889d-2508c85f4f30"
tenant_id           = "22dc2419-3ab3-4f27-905a-945315d19d95"
environment         = "dev"
location            = "eastus2"
resource_group_name = "rg-finopsiq-dev"
owner               = "platform"
helm_namespace      = "finopsiq-dev"

extra_tags = {
  Project    = "FinsOpsIQ"
  CostCenter = "FinOps"
}

network = {
  name          = "vnet-finopsiq-dev"
  address_space = ["10.40.0.0/16"]
  subnets = {
    aks = {
      name              = "snet-aks"
      address_prefixes  = ["10.40.1.0/24"]
      service_endpoints = ["Microsoft.KeyVault", "Microsoft.Storage", "Microsoft.AzureCosmosDB"]
    }
  }
}

monitor = {
  name              = "log-finopsiq-dev"
  sku               = "PerGB2018"
  retention_in_days = 30
}

application_insights = {
  name             = "appi-finopsiq-dev"
  application_type = "web"
}

acr = {
  name = "acrfinopsiqdev"
  sku  = "Premium"
}

keyvault = {
  name                          = "kv-finopsiq-dev"
  sku_name                      = "standard"
  enable_rbac_authorization     = true
  purge_protection_enabled      = true
  soft_delete_retention_days    = 30
  public_network_access_enabled = true
}

cosmosdb = {
  account_name                  = "cosmos-finopsiq-dev"
  database_name                 = "finopsiq"
  consistency_level             = "Session"
  database_throughput           = null
  public_network_access_enabled = true
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
  namespace_name = "sb-finopsiq-dev"
  topic_name     = "finops-events"
  sku            = "Standard"
  capacity       = 0
}

storage = {
  account_name                  = "stfinopsiqdev"
  container_name                = "finops-raw"
  account_tier                  = "Standard"
  account_replication_type      = "LRS"
  public_network_access_enabled = true
}

ai_search = {
  location                      = "eastus"
  name                          = "search-finopsiq-dev"
  sku                           = "standard"
  replica_count                 = 1
  partition_count               = 1
  public_network_access_enabled = true
  local_authentication_enabled  = false
}

openai = {
  name                          = "oai-finopsiq-dev"
  sku_name                      = "S0"
  custom_subdomain_name         = "oai-finopsiq-dev"
  public_network_access_enabled = true
  local_auth_enabled            = false
  deployments = {
    chat = {
      name          = "gpt-4.1-mini"
      model_format  = "OpenAI"
      model_name    = "gpt-4.1-mini"
      model_version = "2025-04-14"
      sku_name      = "GlobalStandard"
      capacity      = 10
    }
    embeddings = {
      name          = "text-embedding-3-small"
      model_format  = "OpenAI"
      model_name    = "text-embedding-3-small"
      model_version = "1"
      sku_name      = "Standard"
      capacity      = 10
    }
  }
}

managed_identities = {
  auth         = { name = "id-finopsiq-dev-auth" }
  collection   = { name = "id-finopsiq-dev-collection" }
  processing   = { name = "id-finopsiq-dev-processing" }
  ai           = { name = "id-finopsiq-dev-ai" }
  notification = { name = "id-finopsiq-dev-notification" }
}

workload_service_accounts = {
  auth         = "auth-service"
  collection   = "collection-service"
  processing   = "processing-service"
  ai           = "ai-service"
  notification = "notification-service"
}

aks = {
  name               = "aks-finopsiq-dev"
  dns_prefix         = "aks-finopsiq-dev"
  kubernetes_version = "1.34"
  subnet_key         = "aks"
  network_policy     = "azure"
  service_cidr       = "10.41.0.0/16"
  dns_service_ip     = "10.41.0.10"
  azure_rbac_enabled = true
  system_node_pool = {
    name                = "system"
    vm_size             = "Standard_D2s_v3"
    node_count          = 1
    enable_auto_scaling = true
    min_count           = 1
    max_count           = 5
    max_pods            = 250
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
      max_pods            = 250
      os_disk_size_gb     = 128
    }
  }
}
