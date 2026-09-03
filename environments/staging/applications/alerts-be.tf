resource "azurerm_monitor_metric_alert" "kv_throttling" {
  name                = "alert-lacc-kv-throttling-${var.environment}"
  resource_group_name = azurerm_resource_group.rg.name
  description         = "A 429 response was received from the Key Vault service API, indicating that the service is throttling requests."
  scopes              = [azurerm_key_vault.kv_api.id]
  severity            = 2
  auto_mitigate       = true

  criteria {
    metric_namespace = "Microsoft.KeyVault/vaults"
    metric_name      = "ServiceApiResult"
    aggregation      = "Count"
    operator         = "GreaterThan"
    threshold        = 0

    dimension {
      name     = "StatusCode"
      operator = "Include"
      values   = ["429"]
    }
  }

  frequency   = "PT1M"
  window_size = "PT5M"

  action {
    action_group_id = azurerm_monitor_action_group.api_alerts.id
  }

  tags = local.tags
}

resource "azurerm_monitor_scheduled_query_rules_alert_v2" "blob_service_delete_ops" {
  name                = "alert-lacc-blob-delete-ops-${var.environment}"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location

  display_name         = "Blob Service Delete Operation in ${var.environment}"
  description          = "A blob or container was deleted from storage account salacc${var.environment}."
  evaluation_frequency = "PT1M"
  window_duration      = "PT5M"
  scopes               = [azurerm_log_analytics_workspace.law.id]
  severity             = 2

  criteria {
    /*
    For Storage Resource Provider (SRP) mediated operations,
    StorageBlobLogs may not contain the originating requester's object ID.
    The Azure Activity Log can be used to determine the initiating identity.
    */
    query = <<-KQL
      StorageBlobLogs
      | where Category has "StorageDelete"
      | extend IsTrustedAccessOperation =
          AuthenticationType == "TrustedAccess"
          and
          tostring(UserAgentHeader) startswith "SRP"
      | extend
          Caller_Identity = case(
            isnotempty(RequesterObjectId), RequesterObjectId,
            IsTrustedAccessOperation, "Check Activity Log (TrustedAccess/SRP)",
            "Unknown"
          )
      | project
          Time_Generated = TimeGenerated,
          Operation_Name = OperationName,
          Object_Key = ObjectKey,
          Response_Status = StatusText,
          Caller_Identity,
          Caller_IP = CallerIpAddress,
          Auth_Type = AuthenticationType
    KQL

    dynamic "dimension" {
      for_each = [
        "Time_Generated",
        "Operation_Name",
        "Object_Key",
        "Response_Status",
        "Caller_Identity",
        "Caller_IP",
        "Auth_Type"
      ]
      content {
        name     = dimension.value
        operator = "Include"
        values   = ["*"]
      }
    }

    time_aggregation_method = "Count"
    operator                = "GreaterThan"
    threshold               = 0

    failing_periods {
      minimum_failing_periods_to_trigger_alert = 1
      number_of_evaluation_periods             = 1
    }
  }

  auto_mitigation_enabled          = true
  workspace_alerts_storage_enabled = false
  enabled                          = false

  action {
    action_groups = [azurerm_monitor_action_group.api_alerts.id]
  }

  identity {
    type = "SystemAssigned"
  }

  tags = local.tags
}
