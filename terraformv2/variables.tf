
##-----------------------------------------------------------------------------
## Naming convention
##-----------------------------------------------------------------------------
variable "custom_name" {
  type        = string
  default     = null
  description = "Override default naming convention"
}

variable "resource_position_prefix" {
  type        = bool
  default     = true
  description = <<EOT
Controls the placement of the resource type keyword (e.g., "vnet", "ddospp") in the resource name.

- If true, the keyword is prepended: "vnet-core-dev".
- If false, the keyword is appended: "core-dev-vnet".

This helps maintain naming consistency based on organizational preferences.
EOT
}

##-----------------------------------------------------------------------------
## Labels
##-----------------------------------------------------------------------------
variable "name" {
  type        = string
  default     = null
  description = "Name  (e.g. `app` or `cluster`)."
}

variable "location" {
  type        = string
  default     = null
  description = "The location/region where the virtual network is created. Changing this forces a new resource to be created."
}

variable "environment" {
  type        = string
  default     = null
  description = "Environment (e.g. `prod`, `dev`, `staging`)."
}

variable "managedby" {
  type        = string
  default     = "terraform-az-modules"
  description = "ManagedBy, eg 'terraform-az-modules'."
}

variable "label_order" {
  type        = list(string)
  default     = ["name", "environment", "location"]
  description = "The order of labels used to construct resource names or tags. If not specified, defaults to ['name', 'environment', 'location']."
}

variable "repository" {
  type        = string
  default     = "https://github.com/terraform-az-modules/terraform-azure-vnet"
  description = "Terraform current module repo"

  validation {
    # regex(...) fails if it cannot find a match
    condition     = can(regex("^https://", var.repository))
    error_message = "The module-repo value must be a valid Git repo link."
  }
}

variable "deployment_mode" {
  type        = string
  default     = "terraform"
  description = "Specifies how the infrastructure/resource is deployed"
}

variable "extra_tags" {
  type        = map(string)
  default     = null
  description = "Variable to pass extra tags."
}

##-----------------------------------------------------------------------------
## Global Variables
##-----------------------------------------------------------------------------
variable "enable" {
  type        = bool
  default     = true
  description = "Set to false to prevent the module from creating any resources."
}

variable "resource_group_name" {
  type        = string
  default     = ""
  description = "A container that holds related resources for an Azure solution"
}

variable "os_type" {
  type        = string
  description = "The O/S type for the App Services to be hosted in this plan. Possible values include `Windows`, `Linux`, and `WindowsContainer`."

  validation {
    condition     = try(contains(["Windows", "Linux", "WindowsContainer"], var.os_type), true)
    error_message = "The `os_type` value must be valid. Possible values are `Windows`, `Linux`, and `WindowsContainer`."
  }
}

##-----------------------------------------------------------------------------
## App Service Plan 
##-----------------------------------------------------------------------------
variable "enable_asp" {
  type        = bool
  default     = true
  description = "Enable creation of the App Service Plan"
}

variable "linux_sku_name" {
  type        = string
  default     = "B1"
  description = "SKU name for Linux App Service Plan (e.g. B1, P1V2)"
}

variable "windows_sku_name" {
  type        = string
  default     = "S1"
  description = "SKU name for Windows App Service Plan (e.g. S1, P1V2)"
}

variable "app_service_environment_id" {
  type        = string
  default     = null
  description = "The ID of the App Service Environment to create this Service Plan in. Requires an Isolated SKU. Use one of I1, I2, I3 for azurerm_app_service_environment, or I1v2, I2v2, I3v2 for azurerm_app_service_environment_v3"
}

variable "worker_count" {
  type        = number
  default     = 1
  description = "The number of Workers (instances) to be allocated."
}

variable "maximum_elastic_worker_count" {
  type        = number
  default     = null
  description = "The maximum number of workers to use in an Elastic SKU Plan. Cannot be set unless using an Elastic SKU."
}

variable "per_site_scaling_enabled" {
  type        = bool
  default     = false
  description = "Should Per Site Scaling be enabled."
}

variable "existing_service_plan_id" {
  type        = string
  default     = null
  description = "If provided, use this existing Service Plan ID instead of creating a new one."
}

variable "zone_balancing_enabled" {
  type    = bool
  default = false

  validation {
    condition     = !var.zone_balancing_enabled || (var.worker_count > 1)
    error_message = "zone_balancing_enabled can only be true when worker_count > 1."
  }
}

##-----------------------------------------------------------------------------
##  Linux App Service
##-----------------------------------------------------------------------------
variable "public_network_access_enabled" {
  type        = bool
  default     = true
  description = "Whether enable public access for the App Service."
}

variable "site_config" {
  type        = any
  default     = {}
  description = "Site config for App Service. See documentation https://www.terraform.io/docs/providers/azurerm/r/app_service.html#site_config. IP restriction attribute is no more managed in this block."
}

variable "linux_web_app_worker_count" {
  description = "Linux Web App worker instance count"
  type        = number
  default     = 1
}

variable "windows_web_app_worker_count" {
  description = "Windows Web App worker instance count"
  type        = number
  default     = 1
}

variable "ip_restriction_default_action" {
  type        = string
  default     = "Deny"
  nullable    = false
  description = "The default action for traffic that does not match any IP restriction rule. Value must be \"Allow\" or \"Deny\"."

  validation {
    condition     = contains(["Allow", "Deny"], var.ip_restriction_default_action)
    error_message = "IP restriction default action must be \"Allow\" or \"Deny\"."
  }
}

variable "ip_restrictions" {
  type = list(object({
    action                    = optional(string, "Allow")
    ip_address                = optional(string)
    name                      = string
    priority                  = number
    service_tag               = optional(string)
    virtual_network_subnet_id = optional(string)
    headers = optional(list(object({
      x_azure_fdid      = list(string)
      x_fd_health_probe = list(string)
      x_forwarded_for   = list(string)
      x_forwarded_host  = list(string)
      })), [
      {
        x_azure_fdid      = []
        x_fd_health_probe = []
        x_forwarded_for   = []
        x_forwarded_host  = []
      }
    ])
  }))

  default     = []
  description = "A list of IP restrictions to be configured for this web app."
}

variable "scm_authorized_subnet_ids" {
  type        = list(string)
  default     = []
  description = "SCM subnets restriction for App Service. See documentation https://www.terraform.io/docs/providers/azurerm/r/app_service.html#scm_ip_restriction"
}

variable "scm_ip_restriction_headers" {
  type        = map(list(string))
  default     = null
  description = "IPs restriction headers for App Service. See documentation https://www.terraform.io/docs/providers/azurerm/r/app_service.html#headers"
}

variable "scm_authorized_ips" {
  type        = list(string)
  default     = []
  description = "SCM IPs restriction for App Service. See documentation https://www.terraform.io/docs/providers/azurerm/r/app_service.html#scm_ip_restriction"
}

variable "scm_authorized_service_tags" {
  type        = list(string)
  default     = []
  description = "SCM Service Tags restriction for App Service. See documentation https://www.terraform.io/docs/providers/azurerm/r/app_service.html#scm_ip_restriction"
}

variable "app_service_vnet_integration_subnet_id" {
  type        = string
  default     = null
  description = "Id of the subnet to associate with the app service"
}

variable "linux_app_stack" {
  type = object({
    type                = optional(string, null)
    dotnet_version      = optional(string)
    node_version        = optional(string)
    java_version        = optional(string)
    java_server         = optional(string)
    java_server_version = optional(string)
    php_version         = optional(string)
    python_version      = optional(string)
    ruby_version        = optional(string)
    go_version          = optional(string)
    docker = object({
      enabled           = bool
      image             = optional(string)
      registry_url      = optional(string)
      registry_username = optional(string)
      registry_password = optional(string)
    })
  })
  default     = null
  description = "Linux app service stack and Docker configuration"
}

variable "windows_app_stack" {
  type = object({
    current_stack                = string
    python                       = optional(bool)
    php_version                  = optional(string)
    node_version                 = optional(string)
    java_version                 = optional(string)
    java_embedded_server_enabled = optional(bool)
    tomcat_version               = optional(string)
    dotnet_version               = optional(string)
    dotnet_core_version          = optional(string)
    docker = object({
      enabled           = bool
      image             = optional(string)
      registry_url      = optional(string)
      registry_username = optional(string)
      registry_password = optional(string)
    })
  })
  default     = null
  description = "Windows app service stack and Docker configuration"
}

variable "staging_slot_custom_app_settings" {
  type        = map(string)
  default     = null
  description = "Override staging slot with custom app settings"
}

variable "app_settings" {
  type        = map(string)
  default     = {}
  description = "Application settings for App Service. See documentation https://www.terraform.io/docs/providers/azurerm/r/app_service.html#app_settings"
}

variable "connection_strings" {
  type        = list(map(string))
  default     = []
  description = "Connection strings for App Service. See documentation https://www.terraform.io/docs/providers/azurerm/r/app_service.html#connection_string"
}

variable "auth_settings" {
  type        = any
  default     = {}
  description = "Authentication settings. Issuer URL is generated thanks to the tenant ID. For active_directory block, the allowed_audiences list is filled with a value generated with the name of the App Service. See https://www.terraform.io/docs/providers/azurerm/r/app_service.html#auth_settings"
}

variable "auth_settings_v2" {
  type        = any
  default     = {}
  description = "Authentication settings V2. See https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/linux_web_app#auth_settings_v2"
}

variable "client_affinity_enabled" {
  type        = bool
  default     = false
  description = "Client affinity activation for App Service. See documentation https://www.terraform.io/docs/providers/azurerm/r/app_service.html#client_affinity_enabled"
}

variable "https_only" {
  type        = bool
  default     = false
  description = "HTTPS restriction for App Service. See documentation https://www.terraform.io/docs/providers/azurerm/r/app_service.html#https_only"
}

variable "mount_points" {
  type        = list(map(string))
  default     = []
  description = "Storage Account mount points. Name is generated if not set and default type is AzureFiles. See https://www.terraform.io/docs/providers/azurerm/r/app_service.html#storage_account"
}

variable "app_service_logs" {
  type = object({
    detailed_error_messages = optional(bool)
    failed_request_tracing  = optional(bool)
    application_logs = optional(object({
      file_system_level = string
      azure_blob_storage = optional(object({
        level             = string
        retention_in_days = number
        sas_url           = string
      }))
    }))
    http_logs = optional(object({
      azure_blob_storage = optional(object({
        retention_in_days = number
        sas_url           = string
      }))
      file_system = optional(object({
        retention_in_days = number
        retention_in_mb   = number
      }))
    }))
  })
  default     = null
  description = "Configuration of the App Service and App Service Slot logs. Documentation [here](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/linux_web_app#logs)"
}

variable "identity" {
  type = object({
    type         = string
    identity_ids = list(string)
  })
  default = {
    type         = "SystemAssigned"
    identity_ids = []
  }
  description = "Map with identity block information."
}

#------------------------------------------------------------------------------
## Container Registry Integration
#------------------------------------------------------------------------------
variable "acr_id" {
  type        = string
  default     = null
  description = "Container registry id to give access to pull images"
}

#------------------------------------------------------------------------------
## Private Endpoint and DNS Integration
#------------------------------------------------------------------------------
variable "enable_private_endpoint" {
  type        = bool
  default     = false
  description = "enable or disable private endpoint to storage account"
}

variable "private_endpoint_subnet_id" {
  type        = string
  default     = null
  description = "Subnet ID for private endpoint"
}

variable "private_dns_zone_ids" {
  type        = string
  default     = null
  description = "Id of the private DNS Zone"
}

##-----------------------------------------------------------------------------
## Application Insights
##-----------------------------------------------------------------------------
variable "app_insights_id" {
  type        = string
  default     = null
  description = "ID of the existing Application Insights resource to use"
}

variable "read_permissions" {
  type        = list(string)
  default     = ["aggregate", "api", "draft", "extendqueries", "search"]
  description = "Read permissions for telemetry"
}

variable "app_insights_instrumentation_key" {
  type        = string
  default     = null
  description = "Instrumentation key of Application Insights"
}

variable "app_insights_connection_string" {
  type        = string
  default     = null
  description = "Connection string of App Insights"
}

variable "application_insights_enabled" {
  type        = bool
  default     = true
  description = "Enable Application Insights integration"
}