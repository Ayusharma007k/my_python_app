provider "azurerm" {
  features {}
}

data "azurerm_container_registry" "acr" {
  name                = var.acr_name
  resource_group_name = var.resource_group_name
}

resource "azurerm_service_plan" "plan" {
  name                = "python-app-service-plan"
  location            = var.location
  resource_group_name = var.resource_group_name
  os_type             = "Linux"
  sku_name            = "B1"
}

resource "azurerm_linux_web_app" "app" {
  name                = var.webapp_name
  location            = var.location
  resource_group_name = var.resource_group_name
  service_plan_id     = azurerm_service_plan.plan.id

  site_config {
    linux_fx_version = "DOCKER|${data.azurerm_container_registry.acr.login_server}/python-app:${var.image_tag}"
  }

  app_settings = {
    "APP_ENV"       = var.env
    "WEBSITES_PORT" = "5000"
  }
}
