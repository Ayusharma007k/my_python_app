##-----------------------------------------------------------------------------
## Outputs
##-----------------------------------------------------------------------------
output "app_service_id" {
  description = "Id of the App Service"
  value       = module.linux-web-app.app_service_id
}

output "app_service_name" {
  description = "Name of the App Service"
  value       = module.linux-web-app.app_service_name
}