resource "azurerm_monitor_metric_alert" "api_outage" {
  for_each = {
    main-api         = azurerm_windows_function_app.fa_main
    filetransfer-api = azurerm_windows_function_app.filetransfer
  }

  name                = "alert-lacc-${each.key}-outage-${var.environment}"
  resource_group_name = azurerm_resource_group.rg.name
  description         = "No 2xx responses received from ${each.value.name} in 5 minutes. This indicates the service may be down."
  scopes              = [each.value.id]
  severity            = 0

  criteria {
    metric_namespace = "Microsoft.Web/sites"
    metric_name      = "Http2xx"
    aggregation      = "Minimum"
    operator         = "LessThan"
    threshold        = 1
  }

  frequency   = "PT1M"
  window_size = "PT5M"

  action {
    action_group_id = azurerm_monitor_action_group.api_alerts.id
  }

  tags = local.tags
}


resource "azurerm_monitor_scheduled_query_rules_alert_v2" "api_exceptions" {
  name                = "alert-lacc-api-exceptions-${var.environment}"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location

  display_name         = "LACC API ${var.environment} exception"
  description          = "Alerts on an exception in LCC API, excluding specified accepted recurring issues."
  evaluation_frequency = "PT5M"
  window_duration      = "PT5M"
  scopes               = [azurerm_application_insights.app_insights.id]
  severity             = 2

  criteria {
    query = <<-KQL
      let ExcludedExceptions = dynamic(${local.excluded_exceptions});
      let CrashDetails = exceptions
        | where not(${local.exclusion_conditions})
        | where severityLevel >= 3
        | extend
            OuterErr = strcat(outerType, ": ", outerMessage),
            InnerErr = strcat(innermostType, ": ", innermostMessage),
            ExUser = coalesce(
                tostring(user_Id),
                tostring(user_AuthenticatedId),
                tostring(customDimensions.User),
                tostring(customDimensions.user),
                tostring(customDimensions.UserId)
            )
        | mv-expand Parsed = parse_json(details)
        | mv-expand Frame = parse_json(tostring(Parsed.parsedStack))
        | extend StackFrame = strcat(
            "  at ", tostring(Frame.method),
            " in ", tostring(Frame.fileName),
            ":", tostring(Frame.line)
          )
        | summarize
            StackSnippet = strcat_array(make_list(StackFrame, 5), "\r\n"),
            ExUser = any(ExUser)
            by operation_Id, OuterErr, InnerErr, problemId, cloud_RoleName;
        CrashDetails
        | join kind=leftouter (requests) on operation_Id
        | extend
            User = coalesce(
                tostring(user_Id),
                tostring(user_AuthenticatedId),
                ExUser
            )
        | summarize
            Count = count(),
            StackSnippet = any(StackSnippet),
            Users = tostring(make_set(User, 5)),
            Urls = tostring(make_set(url, 5)),
            ResultCodes = tostring(make_set(resultCode, 5)),
            Timestamps = tostring(bag_pack(
             "FirstSeen", min(timestamp),
             "LastSeen", max(timestamp)
            ))
        by
            CloudRole = cloud_RoleName,
            ProblemId = problemId,
            OuterError = OuterErr,
            InnerError = InnerErr
      KQL

    time_aggregation_method = "Count"
    operator                = "GreaterThan"
    threshold               = 0

    dynamic "dimension" {
      for_each = ["Count", "Timestamps", "CloudRole", "Urls", "ResultCodes", "Users", "InnerError", "OuterError", "ProblemId", "StackSnippet"]
      content {
        name     = dimension.value
        operator = "Include"
        values   = ["*"]
      }
    }

    failing_periods {
      minimum_failing_periods_to_trigger_alert = 1
      number_of_evaluation_periods             = 1
    }
  }

  auto_mitigation_enabled          = true
  workspace_alerts_storage_enabled = false
  enabled                          = true

  action {
    action_groups = [azurerm_monitor_action_group.api_alerts.id]
  }

  identity {
    type = "SystemAssigned"
  }

  tags = local.tags
}

resource "azurerm_monitor_scheduled_query_rules_alert_v2" "api_5xx_rate" {
  name                = "alert-lacc-api-5xx-rate-${var.environment}"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location

  display_name         = "5xx Rate Spike in LACC API ${var.environment}"
  description          = "Alerts when the LCC API returns a sustained elevated proportion of HTTP 5xx responses."
  evaluation_frequency = "PT1M"
  window_duration      = "PT5M"
  scopes               = [azurerm_application_insights.app_insights.id]
  severity             = 2

  criteria {
    # Ignore low-volume periods where failure percentage is statistically misleading.
    # Alert when at least 10 real requests occur and >=20% return HTTP 5xx.
    # Filter out the consistent health check requests to the /Status endpoint.
    query = <<-QUERY
      requests
      | where tolower(name) != "status"
      | summarize
          TotalRequests = count(),
          FailedRequests = countif(toint(resultCode) between (500 .. 599))
      | extend FailureRate = FailedRequests * 100.0 / TotalRequests
      | where TotalRequests >= 10
      | where FailureRate >= 20
    QUERY

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
  enabled                          = true

  action {
    action_groups = [azurerm_monitor_action_group.api_alerts.id]
  }

  identity {
    type = "SystemAssigned"
  }

  tags = local.tags
}
