terraform {
  backend "azurerm" {
    resource_group_name  = "ayush-rg"
    storage_account_name = "ayushtfstatestorexyz"
    container_name       = "tfstate"
    key                  = "singleapp.tfstate"
  }
}
