environment = "prod"
location    = "UK South"
vnet_rg     = "RG-LaCC-Prod-connectivity"
vnet_name   = "VNET-LaCC-Prod-WANNET"
ado_sc_name = "Azure Pipeline: LaCC-Prod"

private_dns_zones = {
  blob  = "privatelink.blob.core.windows.net"
  table = "privatelink.table.core.windows.net"
  queue = "privatelink.queue.core.windows.net"
  sites = "privatelink.azurewebsites.net"
  vault = "privatelink.vaultcore.azure.net"
}

ui_spa_always_on                 = true
app_asp_sku                      = "P0v3"
app_asp_zone_balancing_enabled   = true
app_asp_auto_scale_enabled       = true
app_asp_worker_count             = 2
app_asp_max_elastic_worker_count = 4

fa_asp_sku                      = "EP1"
fa_asp_max_elastic_worker_count = 9
fa_asp_worker_count             = 3
fa_elastic_instance_minimum     = 3
fa_scale_limit                  = 0 # setting to 0 removes any limit on scaling

health_check_eviction_min = 2

kv_sku                        = "standard"
kv_purge_protection_enabled   = true
kv_soft_delete_retention_days = 90

sa_sku         = "Standard"
sa_replication = "ZRS"
blob_delete_retention = {
  days                     = 7
  permanent_delete_enabled = true
}
sa_key_access_enabled = false

sa_containers = ["lcc-reports-prod", "aspose-templates"]

log_retention_days = 90

alert_ui_5xx_rate_threshold = 1
alert_ui_latency_threshold  = 15

alert_api_excluded_exceptions = {
  "ProblemId" = [
    "Amazon.Runtime.Internal.HttpErrorResponseException at Amazon.Runtime.HttpWebRequestMessage.ProcessHttpResponseMessage",
    "CPS.ComplexCases.API.Exceptions.CpsAuthenticationException at CPS.ComplexCases.API.Context.RequestContext.get_CmsAuthValues"
  ]
}
