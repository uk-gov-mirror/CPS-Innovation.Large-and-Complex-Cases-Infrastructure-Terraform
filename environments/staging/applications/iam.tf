resource "azurerm_role_assignment" "sa" {
  for_each = tomap({
    for role_assignment in local.sa_roles : "${role_assignment.principal_name}.${role_assignment.role}" => role_assignment
  })

  scope                = azurerm_storage_account.sa.id
  role_definition_name = each.value.role
  principal_id         = each.value.principal_id
}

resource "azurerm_role_assignment" "kv" {
  for_each = tomap({
    for role_assignment in local.kv_roles : "${role_assignment.principal_name}.${role_assignment.role}" => role_assignment
  })

  scope                = azurerm_key_vault.kv.id
  role_definition_name = each.value.role
  principal_id         = each.value.principal_id
}


locals {
  role_assignments = {
    sa = {
      ado_sc = {
        principal_id = data.azuread_service_principal.ado.object_id
        roles = [
          "Storage Blob Data Contributor",
          "Storage Queue Data Contributor",
          "Storage Table Data Contributor"
        ]
      }
      fa_main = {
        principal_id = azurerm_windows_function_app.fa_main.identity[0].principal_id
        roles = [
          "Storage Blob Data Owner",
          "Storage Table Data Contributor"
        ]
      }
      filetransfer = {
        principal_id = azurerm_windows_function_app.filetransfer.identity[0].principal_id
        roles = [
          "Storage Blob Data Owner",
          "Storage Blob Data Contributor",
          "Storage Queue Data Contributor",
          "Storage Table Data Contributor"
        ]
      }
    },
    kv = {
      fa_main = {
        principal_id = azurerm_windows_function_app.fa_main.identity[0].principal_id
        roles        = ["Key Vault Secrets User"]
      }
      filetransfer = {
        principal_id = azurerm_windows_function_app.filetransfer.identity[0].principal_id
        roles        = ["Key Vault Secrets User"]
      }
      ado_sc = {
        principal_id = data.azuread_service_principal.ado.object_id
        roles        = ["Key Vault Secrets Officer"]
      }
    }
  }

  sa_roles = flatten([
    for principal_name, principal in local.role_assignments.sa : [
      for role in principal.roles : {
        role           = role
        principal_id   = principal.principal_id
        principal_name = principal_name
      }
    ]
  ])

  kv_roles = flatten([
    for principal_name, principal in local.role_assignments.kv : [
      for role in principal.roles : {
        role           = role
        principal_id   = principal.principal_id
        principal_name = principal_name
      }
    ]
  ])
}
