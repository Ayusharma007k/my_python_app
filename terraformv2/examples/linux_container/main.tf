##-----------------------------------------------------------------------------
## Provider
##-----------------------------------------------------------------------------
provider "azurerm" {
  features {}
}

##-----------------------------------------------------------------------------
## Resource Group
##-----------------------------------------------------------------------------
module "resource_group" {
  source      = "terraform-az-modules/resource-group/azure"
  version     = "1.0.0"
  name        = "ayush"
  environment = "dev"
  label_order = ["environment", "name", "location"]
  location    = "canadacentral"
}

##-----------------------------------------------------------------------------
## Virtual Network
##-----------------------------------------------------------------------------
module "vnet" {
  source              = "terraform-az-modules/vnet/azure"
  version             = "1.0.0"
  name                = "ayush"
  environment         = "dev"
  label_order         = ["name", "environment", "location"]
  resource_group_name = module.resource_group.resource_group_name
  location            = module.resource_group.resource_group_location
  address_spaces      = ["10.0.0.0/16"]
}

##-----------------------------------------------------------------------------
## Subnets
##-----------------------------------------------------------------------------
module "subnet" {
  source               = "terraform-az-modules/subnet/azure"
  version              = "1.0.0"
  environment          = "dev"
  resource_group_name  = module.resource_group.resource_group_name
  location             = module.resource_group.resource_group_location
  virtual_network_name = module.vnet.vnet_name
  subnets = [
    {
      name            = "subnet1"
      subnet_prefixes = ["10.0.1.0/24"]
    },
    {
      name            = "subnet2"
      subnet_prefixes = ["10.0.2.0/24"]

      # Delegation
      delegations = [
        {
          name = "Microsoft.Web/serverFarms"
          service_delegations = [
            {
              name    = "Microsoft.Web/serverFarms"
              actions = []
              # Note: In some versions, 'actions' might not be required or is implicit
            }
          ]
        }
      ]
    }
  ]
  enable_route_table = true
  route_tables = [
    {
      name = "pub"
      routes = [
        {
          name           = "rt-test"
          address_prefix = "0.0.0.0/0"
          next_hop_type  = "Internet"
        }
      ]
    }
  ]
}

##-----------------------------------------------------------------------------
## Subnet for Private Endpoint
##-----------------------------------------------------------------------------
module "subnet-ep" {
  source               = "terraform-az-modules/subnet/azure"
  version              = "1.0.0"
  environment          = "dev"
  resource_group_name  = module.resource_group.resource_group_name
  location             = module.resource_group.resource_group_location
  virtual_network_name = module.vnet.vnet_name

  subnets = [
    {
      name            = "sub3"
      subnet_prefixes = ["10.0.3.0/24"]
    }
  ]
  enable_route_table = false
}

##-----------------------------------------------------------------------------
## Log Analytics
##-----------------------------------------------------------------------------
module "log-analytics" {
  source              = "terraform-az-modules/log-analytics/azure"
  version             = "1.0.0"
  name                = "ayush"
  environment         = "dev"
  label_order         = ["name", "environment", "location"]
  resource_group_name = module.resource_group.resource_group_name
  location            = module.resource_group.resource_group_location
}

##-----------------------------------------------------------------------------
## Private DNS Zone
##-----------------------------------------------------------------------------
module "private-dns-zone" {
  source              = "terraform-az-modules/private-dns/azure"
  version             = "1.0.0"
  resource_group_name = module.resource_group.resource_group_name
  location            = module.resource_group.resource_group_location
  label_order         = ["name", "environment", "location"]
  name                = "ayush"
  environment         = "dev"
  private_dns_config = [
    {
      resource_type = "azure_web_apps"
      vnet_ids      = [module.vnet.vnet_id]
    },
  ]
}

##-----------------------------------------------------------------------------
## Application Insights
##-----------------------------------------------------------------------------
module "application-insights" {
  source                     = "git::https://github.com/terraform-az-modules/terraform-azure-application-insights.git?ref=feat/update"
  name                       = "ayush"
  environment                = "dev"
  label_order                = ["name", "environment", "location"]
  resource_group_name        = module.resource_group.resource_group_name
  location                   = module.resource_group.resource_group_location
  workspace_id               = module.log-analytics.workspace_id
  log_analytics_workspace_id = module.log-analytics.workspace_id
  web_test_enable            = false
}

##-----------------------------------------------------------------------------
## Linux Web App with Container
##-----------------------------------------------------------------------------
module "linux-web-app" {
  source              = "../.."
  depends_on          = [module.vnet, module.subnet]
  enable              = true
  name                = "ayush"
  environment         = "dev"
  label_order         = ["name", "environment", "location"]
  resource_group_name = module.resource_group.resource_group_name
  location            = module.resource_group.resource_group_location
  os_type             = "Linux"
  linux_sku_name      = "B1"
  linux_app_stack = {
    # For built-in stacks, use the following structure:
    # type           = "dotnet" # change to "node", "java", etc, as needed
    # dotnet_version = "8.0"
    docker = {
      enabled           = true
      image             = "python:3.7-slim" # Use "nginx", "node", etc. for public images; or "myimage:tag" for private images
      registry_url      = "ayushacr123.azurecr.io" # null for public hub; set like "myregistry.azurecr.io" for ACR
      # registry_username = var.acr_username # null for public hub; set like "myregistry" for ACR
      # registry_password = var.acr_password # null for public hub; set like "mypassword" for ACR
    }
  }
  acr_id = "/subscriptions/1ac2caa4-336e-4daa-b8f1-0fbabe2d4b11/resourceGroups/ayush-rg/providers/Microsoft.ContainerRegistry/registries/ayushacr123" # Set your ACR resource ID here
  # VNet and Private Endpoint Integration
  private_endpoint_subnet_id             = module.subnet-ep.subnet_ids["sub3"] # Use private endpoint subnet here
  enable_private_endpoint                = true
  app_service_vnet_integration_subnet_id = module.subnet.subnet_ids["subnet2"]                         # Delegated subnet for App Service integration
  private_dns_zone_ids                   = module.private-dns-zone.private_dns_zone_ids.azure_web_apps # Reference the private DNS zone IDs for web apps
  public_network_access_enabled          = false
  ip_restriction_default_action          = "Allow"
  # Site config
  site_config = {
    container_registry_use_managed_identity = true # Set to true if using managed identity for ACR access
    #Checkov suggested 
    minimum_tls_version      = "1.2"
    remote_debugging_enabled = false
    http2_enabled            = true
    ftps_state               = "FtpsOnly"
  }
  https_only = true
  # Application Insights/AppSettings
  app_settings = {
    ApplicationInsightsAgent_EXTENSION_VERSION = "~3"
  }
  # app_insights_id                  = module.application-insights.app_insights_id
  # app_insights_instrumentation_key = module.application-insights.instrumentation_key
  # app_insights_connection_string   = module.application-insights.connection_string
}


