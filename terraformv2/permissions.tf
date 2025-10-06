##-----------------------------------------------------------------------------
## Permissions, Roles, and Policies
##-----------------------------------------------------------------------------
resource "azurerm_role_assignment" "acr_pull" {
  count                            = var.enable && (var.os_type == "Linux" ? var.linux_app_stack.docker.enabled : var.windows_app_stack.docker.enabled) && local.site_config.container_registry_use_managed_identity == true ? 1 : 0
  principal_id                     = var.enable && var.os_type == "Linux" ? azurerm_linux_web_app.main[0].identity[0].principal_id : azurerm_windows_web_app.main[0].identity[0].principal_id # Updated Condition
  role_definition_name             = "AcrPull"
  scope                            = var.acr_id
  skip_service_principal_aad_check = true
}