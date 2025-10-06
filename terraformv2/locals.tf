##-----------------------------------------------------------------------------
## Locals
##-----------------------------------------------------------------------------
locals {
  name = var.custom_name != null ? var.custom_name : module.labels.id

  default_site_config = {
    always_on                               = "true"
    scm_minimum_tls_version                 = "1.2"
    container_registry_use_managed_identity = false
  }

  effective_service_plan_id = var.existing_service_plan_id != null ? var.existing_service_plan_id : azurerm_service_plan.main[0].id

  site_config = merge(local.default_site_config, var.site_config)

  default_ip_restrictions_headers = {
    x_azure_fdid      = null
    x_fd_health_probe = null
    x_forwarded_for   = null
    x_forwarded_host  = null
  }

  scm_subnets = [for subnet in var.scm_authorized_subnet_ids : {
    name                      = "scm_ip_restriction_subnet_${join("", [1, index(var.scm_authorized_subnet_ids, subnet)])}"
    ip_address                = null
    virtual_network_subnet_id = subnet
    service_tag               = null
    subnet_id                 = subnet
    priority                  = join("", [1, index(var.scm_authorized_subnet_ids, subnet)])
    action                    = "Allow"
    headers                   = local.scm_ip_restriction_headers
  }]

  scm_ip_restriction_headers = var.scm_ip_restriction_headers != null ? [merge(local.default_ip_restrictions_headers, var.scm_ip_restriction_headers)] : []

  scm_cidrs = [for cidr in var.scm_authorized_ips : {
    name                      = "scm_ip_restriction_cidr_${join("", [1, index(var.scm_authorized_ips, cidr)])}"
    ip_address                = cidr
    virtual_network_subnet_id = null
    service_tag               = null
    subnet_id                 = null
    priority                  = join("", [1, index(var.scm_authorized_ips, cidr)])
    action                    = "Allow"
    headers                   = local.scm_ip_restriction_headers
  }]

  scm_service_tags = [for service_tag in var.scm_authorized_service_tags : {
    name                      = "scm_service_tag_restriction_${join("", [1, index(var.scm_authorized_service_tags, service_tag)])}"
    ip_address                = null
    virtual_network_subnet_id = null
    service_tag               = service_tag
    subnet_id                 = null
    priority                  = join("", [1, index(var.scm_authorized_service_tags, service_tag)])
    action                    = "Allow"
    headers                   = local.scm_ip_restriction_headers
  }]

  default_app_settings = var.application_insights_enabled ? {
    APPLICATION_INSIGHTS_IKEY             = var.app_insights_instrumentation_key
    APPINSIGHTS_INSTRUMENTATIONKEY        = var.app_insights_instrumentation_key
    APPLICATIONINSIGHTS_CONNECTION_STRING = var.app_insights_connection_string
  } : {}
  app_settings = merge(local.default_app_settings, var.app_settings)

  auth_settings_active_directory = merge(
    {
      client_id         = null
      client_secret     = null
      allowed_audiences = []
    },
  local.auth_settings.active_directory == null ? local.auth_settings_ad_default : var.auth_settings.active_directory)
  auth_settings_ad_default = {
    client_id         = null
    client_secret     = null
    allowed_audiences = []
  }

  auth_settings = merge(
    {
      enabled                        = false
      issuer                         = format("https://sts.windows.net/%s/", data.azurerm_client_config.main.tenant_id)
      token_store_enabled            = false
      unauthenticated_client_action  = "RedirectToLoginPage"
      default_provider               = "AzureActiveDirectory"
      allowed_external_redirect_urls = []
      active_directory               = null
    },
  var.auth_settings)

  auth_settings_v2_login_default = {
    token_store_enabled               = false
    token_refresh_extension_time      = 72
    preserve_url_fragments_for_logins = false
    cookie_expiration_convention      = "FixedTime"
    cookie_expiration_time            = "08:00:00"
    validate_nonce                    = true
    nonce_expiration_time             = "00:05:00"
  }

  auth_settings_v2_login = try(var.auth_settings_v2.login, null) == null ? local.auth_settings_v2_login_default : var.auth_settings_v2.login
}