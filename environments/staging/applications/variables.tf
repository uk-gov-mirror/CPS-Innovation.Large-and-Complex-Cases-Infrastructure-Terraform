variable "environment" {
  type        = string
  description = "The resource group name"
}

variable "location" {
  type        = string
  description = "The location of the resource group"
}

variable "vnet_name" {
  type        = string
  description = "The name of the virtual network in which to create the subnet"
}

variable "vnet_rg" {
  type        = string
  description = "The name of the resource group containing the VNet."
}

variable "ado_sc_name" {
  type        = string
  description = "The name of the service principal used for deployment with Azure Pipelines"
}

variable "private_dns_zones" {
  type        = map(string)
  description = "A map of private dns subresource name to their zone names"
}

##### ui app #####

variable "ui_spa_always_on" {
  type        = bool
  description = "Should the app be kept warm during periods of inactivity?"
}

variable "ui_spa_pe_ip" {
  type        = string
  description = "A static private IP address to use for the UI SPA private endpoint."
  default     = null
}

variable "app_asp_sku" {
  type        = string
  description = "The SKU of the Linux App Service Plan."
}

variable "app_asp_zone_balancing_enabled" {
  type        = bool
  description = "Determines if zone balancing is enabled for the app service plan."
  default     = false
}

variable "app_asp_auto_scale_enabled" {
  type        = bool
  description = "Should auto-scaling be enabled for the app service plan?"
  default     = false
}

variable "app_asp_worker_count" {
  type        = number
  description = "The number of instances running each app on the service plan."
}

variable "app_asp_max_elastic_worker_count" {
  type        = number
  description = "The maximum number of workers that can be used when scaling out the apps on the service plan."
  default     = null
}

##### function apps #####

variable "fa_asp_sku" {
  type        = string
  description = "The SKU of the api function apps' App Service Plan. Must be one of: EP1, EP2, EP3"
  validation {
    condition     = can(regex("^EP[0-9]$", var.fa_asp_sku))
    error_message = "Invalid SKU. Only Elastic Premium plans can be selected. Please input one of EP1, EP2 or EP3"
  }
}

variable "fa_asp_max_elastic_worker_count" {
  type        = number
  description = "The maximum number of workers that can be used when scaling out the apps on the service plan"
}

variable "fa_asp_worker_count" {
  type        = number
  description = "The number of instances running each app on the service plan. Must be a multiple of availability zones in the region"
}

variable "fa_elastic_instance_minimum" {
  type        = number
  description = "The minimum number of pre-warmed instances running for the function app. To enable zone redundancy, this must be a multiple of availability zones in the region."
}

variable "fa_scale_limit" {
  type        = number
  description = "The maximum number of instances the app can scale out to. Setting it to 0 equates to removing any limit."
}

variable "health_check_eviction_min" {
  type        = number
  description = "The number of minutes that a node can be unhealthy before being removed from the load balancer. Possible values are between 2 and 10. Only valid in conjunction with health_check_path."
}

##### key vault #####

variable "kv_sku" {
  type        = string
  description = "The SKU for the key vault. Valid input: 'standard' or 'premium'."
}

variable "kv_purge_protection_enabled" {
  type        = bool
  description = "Is purge protection is enabled for the Key Vault? Once enabled, it cannot be disabled. If true, the vault will be retained for 90 days after deletion."
}

variable "kv_soft_delete_retention_days" {
  type        = number
  description = "The number of days to retain deleted KV objects in a recoverable state"
  default     = 90
}

##### storage account #####

variable "sa_sku" {
  type        = string
  description = "The SKU of the storage account. Valid options are Standard and Premium."
}

variable "sa_replication" {
  type        = string
  description = "The type of replication to use for the storage account. Valid options are LRS, GRS, RAGRS, ZRS, GZRS and RAGZRS."
}

variable "blob_delete_retention" {
  type = object({
    days                     = number
    permanent_delete_enabled = bool
  })
  description = "The delete retention policy for the storage account"
}

variable "sa_key_access_enabled" {
  type        = bool
  description = "Is shared access key authorization enabled for the storage account?"
}

variable "sa_containers" {
  type        = list(string)
  description = "A list of storage container names within the main storage account"
}

##### log analytics #####

variable "log_retention_days" {
  type        = number
  description = "The number of days to retain logs in the logs analytics workspace"
  default     = 60
}

##### monitoring #####

variable "dev_team_email" {
  type        = string
  description = "The DL email address of the project's dev team."
  sensitive   = true
}

variable "alert_api_excluded_exceptions" {
  type        = map(list(string))
  description = "A map of exception properties to lists of values that should be excluded from the api exceptions alert rule. The key is the property name and the value is a list of values to exclude."
  default     = {}
}
