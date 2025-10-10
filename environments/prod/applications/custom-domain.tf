locals {
  custom_hostnames = {
    lcc     = azurerm_linux_web_app.ui_spa
    lcc-api = azurerm_windows_function_app.fa_main
  }
}

resource "azurerm_app_service_custom_hostname_binding" "hostname" {
  for_each            = local.custom_hostnames
  hostname            = "www.${each.key}.cps.gov.uk"
  app_service_name    = each.value.name
  resource_group_name = azurerm_resource_group.rg.name

  lifecycle {
    ignore_changes = [ssl_state, thumbprint]
  }
}

resource "azurerm_app_service_managed_certificate" "hostname" {
  for_each                   = local.custom_hostnames
  custom_hostname_binding_id = azurerm_app_service_custom_hostname_binding.hostname[each.key].id
}

resource "azurerm_app_service_certificate_binding" "hostname" {
  for_each            = local.custom_hostnames
  hostname_binding_id = azurerm_app_service_custom_hostname_binding.hostname[each.key].id
  certificate_id      = azurerm_app_service_managed_certificate.hostname[each.key].id
  ssl_state           = "SniEnabled"
}
