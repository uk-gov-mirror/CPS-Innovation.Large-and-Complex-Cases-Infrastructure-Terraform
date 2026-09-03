environment = "staging"
location    = "UK South"
vnet_rg     = "RG-LaCC-connectivity"
vnet_name   = "VNET-LaCC-WANNET"
ado_sc_name = "Azure Pipeline: LaCC-PreProd"

private_dns_zones = {
  blob  = "privatelink.blob.core.windows.net"
  table = "privatelink.table.core.windows.net"
  queue = "privatelink.queue.core.windows.net"
  sites = "privatelink.azurewebsites.net"
  vault = "privatelink.vaultcore.azure.net"
}

ui_spa_always_on     = true
app_asp_sku          = "P0v3"
app_asp_worker_count = 1

fa_asp_sku                      = "EP1"
fa_asp_max_elastic_worker_count = 6
fa_asp_worker_count             = 2
fa_elastic_instance_minimum     = 2
fa_scale_limit                  = 4

health_check_eviction_min = 10

kv_sku                        = "standard"
kv_purge_protection_enabled   = true
kv_soft_delete_retention_days = 90

sa_sku         = "Standard"
sa_replication = "ZRS"
blob_delete_retention = {
  days                     = 3
  permanent_delete_enabled = true
}
sa_key_access_enabled = false

sa_containers = ["lcc-reports-staging", "aspose-templates"]

alert_api_excluded_exceptions = {
  "ProblemId" = [
    "CPS.ComplexCases.API.Exceptions.CpsAuthenticationException at CPS.ComplexCases.API.Middleware.RequestValidationMiddleware+<Invoke>d__3.MoveNext",
    "Amazon.Runtime.Internal.HttpErrorResponseException at Amazon.Runtime.HttpWebRequestMessage.ProcessHttpResponseMessage",
    "CPS.ComplexCases.API.Exceptions.CpsAuthenticationException at CPS.ComplexCases.API.Context.RequestContext.get_CmsAuthValues"
  ]
}
