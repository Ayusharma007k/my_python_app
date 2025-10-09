output "app_service_name" {
  value       = module.app-container.app_service_name
  description = "The name of the App Service"
}

output "blue_slot_url" {
  value       = azurerm_linux_web_app_slot.blue.default_hostname
  description = "The URL of the Blue deployment slot"
}

output "green_slot_url" {
  value       = azurerm_linux_web_app_slot.green.default_hostname
  description = "The URL of the Green deployment slot"
}
