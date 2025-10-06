
##-----------------------------------------------------------------------------
## Tagging Module – Applies standard tags to all resources
##-----------------------------------------------------------------------------
module "labels" {
  source          = "terraform-az-modules/tags/azure"
  version         = "1.0.0"
  name            = var.custom_name == null ? var.name : var.custom_name
  location        = var.location
  environment     = var.environment
  managedby       = var.managedby
  label_order     = var.label_order
  repository      = var.repository
  deployment_mode = var.deployment_mode
  extra_tags      = var.extra_tags
}

##-----------------------------------------------------------------------------
## App Service Plan
##-----------------------------------------------------------------------------
resource "azurerm_service_plan" "main" {
  count               = var.enable && var.existing_service_plan_id == null ? 1 : 0
  name                = var.resource_position_prefix ? format("asp-%s", local.name) : format("%s-asp", local.name)
  resource_group_name = var.resource_group_name
  location            = var.location
  os_type             = var.os_type
  # SKU and scale settings depend on os_type and user inputs; use a conditional to pick correct sku_name
  sku_name = var.os_type == "Linux" ? var.linux_sku_name : var.windows_sku_name
  worker_count = (
    var.os_type == "Linux" && var.linux_sku_name == "B1" ? null :
    var.worker_count
  )
  # Note: worker_count is null for Linux SKU "B1" as it doesn't support specifying worker count.
  maximum_elastic_worker_count = var.maximum_elastic_worker_count
  app_service_environment_id   = var.app_service_environment_id
  per_site_scaling_enabled     = var.per_site_scaling_enabled
  zone_balancing_enabled       = var.zone_balancing_enabled
  tags                         = module.labels.tags
}

##-----------------------------------------------------------------------------
## Private Endpoint for App Service
##-----------------------------------------------------------------------------
resource "azurerm_private_endpoint" "pep" {
  count               = var.enable && var.enable_private_endpoint ? 1 : 0
  name                = format("pe-%s", var.os_type == "Linux" ? azurerm_linux_web_app.main[0].name : azurerm_windows_web_app.main[0].name)
  location            = var.location
  resource_group_name = var.resource_group_name
  subnet_id           = var.private_endpoint_subnet_id
  tags                = module.labels.tags
  private_service_connection {
    name                           = var.resource_position_prefix ? format("psc-app-service-%s", local.name) : format("%s-psc-app-service", local.name)
    is_manual_connection           = false
    private_connection_resource_id = var.os_type == "Linux" ? azurerm_linux_web_app.main[0].id : azurerm_windows_web_app.main[0].id
    subresource_names              = ["sites"]
  }

  private_dns_zone_group {
    name                 = var.resource_position_prefix ? format("as-dns-zone-group-%s", local.name) : format("%s-as-dns-zone-group", local.name)
    private_dns_zone_ids = [var.private_dns_zone_ids]
  }
  lifecycle {
    ignore_changes = [
      tags,
    ]
  }
}

##-----------------------------------------------------------------------------
## Telemetry / Application Insights API Key
##-----------------------------------------------------------------------------
resource "azurerm_application_insights_api_key" "read_telemetry" {
  name                    = var.resource_position_prefix ? format("appi-api-key-%s", local.name) : format("%s-appi-api-key", local.name)
  application_insights_id = var.app_insights_id
  read_permissions        = var.read_permissions
}

