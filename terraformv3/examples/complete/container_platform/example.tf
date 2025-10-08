provider "azurerm" {
  features {}
}

##----------------------------------------------------------------------------- 
## Local declaration
##-----------------------------------------------------------------------------
locals {
  name        = "ayush-test"
  environment = "dev"
  label_order = ["name", "environment"]
  location    = "Canada Central"
}

##----------------------------------------------------------------------------- 
## Resource group
##-----------------------------------------------------------------------------
module "resource_group" {
  source      = "clouddrove/resource-group/azure"
  version     = "1.0.2"
  name        = local.name
  environment = local.environment
  label_order = local.label_order
  location    = local.location
}

##----------------------------------------------------------------------------- 
## Log Analytics
##-----------------------------------------------------------------------------
module "log-analytics" {
  source                           = "clouddrove/log-analytics/azure"
  version                          = "1.1.0"
  name                             = local.name
  environment                      = local.environment
  label_order                      = local.label_order
  create_log_analytics_workspace   = true
  log_analytics_workspace_sku      = "PerGB2018"
  resource_group_name              = module.resource_group.resource_group_name
  log_analytics_workspace_location = module.resource_group.resource_group_location
}

##----------------------------------------------------------------------------- 
## App Service Plan
##-----------------------------------------------------------------------------
resource "azurerm_app_service_plan" "plan" {
  name                = "${local.name}-plan"
  location            = module.resource_group.resource_group_location
  resource_group_name = module.resource_group.resource_group_name
  kind                = "Linux"
  reserved            = true

  sku {
    tier = "Basic"
    size = "B1"
  }
}

##----------------------------------------------------------------------------- 
## App Service (Production)
##-----------------------------------------------------------------------------
resource "azurerm_linux_web_app" "prod" {
  name                = local.name
  location            = module.resource_group.resource_group_location
  resource_group_name = module.resource_group.resource_group_name
  service_plan_id     = azurerm_app_service_plan.plan.id

  site_config {
    linux_fx_version = "DOCKER|${var.docker_registry_url}/${var.docker_image_name}:${var.image_tag}"
  }

  app_settings = var.app_settings

  identity {
    type = "SystemAssigned"
  }
}

##----------------------------------------------------------------------------- 
## Blue Slot
##-----------------------------------------------------------------------------
resource "azurerm_linux_web_app_slot" "blue" {
  name                = "blue"
  location            = module.resource_group.resource_group_location
  resource_group_name = module.resource_group.resource_group_name
  app_service_plan_id = azurerm_app_service_plan.plan.id
  parent_app_id       = azurerm_linux_web_app.prod.id

  site_config {
    linux_fx_version = "DOCKER|${var.docker_registry_url}/${var.docker_image_name}:${var.image_tag}"
  }

  app_settings = var.app_settings
}

##----------------------------------------------------------------------------- 
## Green Slot
##-----------------------------------------------------------------------------
resource "azurerm_linux_web_app_slot" "green" {
  name                = "green"
  location            = module.resource_group.resource_group_location
  resource_group_name = module.resource_group.resource_group_name
  app_service_plan_id = azurerm_app_service_plan.plan.id
  parent_app_id       = azurerm_linux_web_app.prod.id

  site_config {
    linux_fx_version = "DOCKER|${var.docker_registry_url}/${var.docker_image_name}:${var.image_tag}"
  }

  app_settings = var.app_settings
}

##----------------------------------------------------------------------------- 
## Slot Swap Logic
##-----------------------------------------------------------------------------
resource "azurerm_linux_web_app_slot_swap" "swap" {
  count           = var.auto_swap ? 1 : 0
  resource_group_name = module.resource_group.resource_group_name
  name                = azurerm_linux_web_app.prod.name
  target_slot_name    = var.current_slot == "blue" ? "green" : "blue"
}

##----------------------------------------------------------------------------- 
## Outputs
##-----------------------------------------------------------------------------
output "current_slot" {
  value = var.current_slot != "" ? var.current_slot : "blue"
}

output "production_url" {
  value = azurerm_linux_web_app.prod.default_site_hostname
}
