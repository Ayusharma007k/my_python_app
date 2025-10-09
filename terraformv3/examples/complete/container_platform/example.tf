# Provider

provider "azurerm" {
  features {}
}

# Local declaration

locals {
  name        = "ayush-test"
  environment = "dev"
  label_order = ["name", "environment"]
  location    = "Canada Central"
}

# Resource Group

module "resource_group" {
  source      = "clouddrove/resource-group/azure"
  version     = "1.0.2"
  name        = local.name
  environment = local.environment
  label_order = local.label_order
  location    = local.location
}

# Log Analytics

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
  log_analytics_workspace_id       = module.log-analytics.workspace_id
}

# Primary App Service (Production Slot)

module "app-container" {
  source              = "../../.."
  name                = local.name
  environment         = local.environment
  label_order         = local.label_order
  resource_group_name = module.resource_group.resource_group_name
  location            = module.resource_group.resource_group_location
  os_type             = "Linux"
  sku_name            = "S1"

  use_docker               = true
  docker_image_name        = "python-app"
  docker_registry_url      = "ayushacr123.azurecr.io"
  acr_id                   = "/subscriptions/1ac2caa4-336e-4daa-b8f1-0fbabe2d4b11/resourceGroups/ayush-rg/providers/Microsoft.ContainerRegistry/registries/ayushacr123"

  site_config = {
    container_registry_use_managed_identity = true
  }

  app_settings = {
    foo = "bar"
  }

  app_service_logs = {
    detailed_error_messages = false
    failed_request_tracing  = false
    application_logs = {
      file_system_level = "Information"
    }
    http_logs = {
      file_system = {
        retention_in_days = 7
        retention_in_mb   = 35
      }
    }
  }

  log_analytics_workspace_id = module.log-analytics.workspace_id
}

# Blue-Green Deployment Configuration

# --- Blue Slot (Active Production) ---
resource "azurerm_linux_web_app_slot" "blue" {
  name          = "blue"
  app_service_id = module.app-container.app_service_id  # ✅ FIXED
  service_plan_id = module.app-container.app_service_plan_id

  site_config {
    linux_fx_version = "DOCKER|ayushacr123.azurecr.io/python-app:blue"
    container_registry_use_managed_identity = true
  }

  app_settings = {
    SLOT_NAME = var.slot_name
  }

  identity {
    type = "SystemAssigned"
  }
}

# --- Green Slot (Staging Slot) ---
resource "azurerm_linux_web_app_slot" "green" {
  name          = "green"
  app_service_id = module.app-container.app_service_id  # ✅ FIXED
  service_plan_id = module.app-container.app_service_plan_id


  site_config {
    linux_fx_version = "DOCKER|ayushacr123.azurecr.io/python-app:green"
    container_registry_use_managed_identity = true
  }
  app_settings = {
    SLOT_NAME = var.slot_name
  }

  identity {
    type = "SystemAssigned"
  }
}

# Optional: Blue-Green Swap (Manual or Pipeline Triggered)

resource "azurerm_web_app_slot_swap" "swap" {
  resource_group_name = module.resource_group.resource_group_name
  web_app_name        = module.app-container.app_service_name
  slot_name           = azurerm_linux_web_app_slot.green.name   # New version (staging)
  target_slot_name    = azurerm_linux_web_app_slot.blue.name    # Current production
}
