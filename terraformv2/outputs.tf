##-----------------------------------------------------------------------------
## Outputs
##-----------------------------------------------------------------------------
output "app_service_id" {
  description = "Id of the App Service"
  value       = var.os_type == "Linux" ? azurerm_linux_web_app.main[0].id : azurerm_windows_web_app.main[0].id
}

output "app_service_name" {
  description = "Name of the App Service"
  value       = var.os_type == "Linux" ? azurerm_linux_web_app.main[0].name : azurerm_windows_web_app.main[0].name
}

output "app_service_default_site_hostname" {
  description = "The Default Hostname associated with the App Service"
  value       = var.os_type == "Linux" ? azurerm_linux_web_app.main[0].default_hostname : azurerm_windows_web_app.main[0].default_hostname
}

output "app_service_outbound_ip_addresses" {
  description = "Outbound IP addresses of the App Service"
  value       = var.os_type == "Linux" ? azurerm_linux_web_app.main[0].outbound_ip_addresses : azurerm_windows_web_app.main[0].outbound_ip_addresses
}

output "app_service_possible_outbound_ip_addresses" {
  description = "Possible outbound IP addresses of the App Service"
  value       = var.os_type == "Linux" ? azurerm_linux_web_app.main[0].possible_outbound_ip_addresses : azurerm_windows_web_app.main[0].possible_outbound_ip_addresses
}

output "app_service_site_credential" {
  description = "Site credential block of the App Service"
  value       = var.os_type == "Linux" ? azurerm_linux_web_app.main[0].site_credential : azurerm_windows_web_app.main[0].site_credential
}

output "linux_identity" {
  value = length(azurerm_linux_web_app.main) > 0 ? [
    for id in azurerm_linux_web_app.main[0].identity : {
      principal_id = id.principal_id
      type         = id.type
    }
  ] : []
  description = "Managed identity info for Linux web app (empty if not created)"
}

output "windows_identity" {
  value = length(azurerm_windows_web_app.main) > 0 ? [
    for id in azurerm_windows_web_app.main[0].identity : {
      principal_id = id.principal_id
      type         = id.type
    }
  ] : []
  description = "Managed identity info for Windows web app (empty if not created)"
}

