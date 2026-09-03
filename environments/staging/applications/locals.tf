locals {
  tags = {
    environment : var.environment
  }

  # alerts-api.tf
  excluded_exceptions = jsonencode(var.alert_api_excluded_exceptions)

  exclusion_conditions = length(var.alert_api_excluded_exceptions) != 0 ? join(" or ", [
    for k in keys(var.alert_api_excluded_exceptions) :
    "tostring(${k}) in (ExcludedExceptions.${k})"
  ]) : "false"
}
