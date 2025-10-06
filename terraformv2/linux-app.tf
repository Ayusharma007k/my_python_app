##-----------------------------------------------------------------------------
## Linux Web App
##-----------------------------------------------------------------------------
resource "azurerm_linux_web_app" "main" {
  count                              = var.enable && var.os_type == "Linux" ? 1 : 0
  name                               = var.resource_position_prefix ? format("app-%s", local.name) : format("%s-app", local.name)
  resource_group_name                = var.resource_group_name
  location                           = var.location
  service_plan_id                    = local.effective_service_plan_id
  public_network_access_enabled      = var.public_network_access_enabled
  virtual_network_subnet_id          = var.app_service_vnet_integration_subnet_id
  client_certificate_enabled         = lookup(var.site_config, "client_certificate_enabled", false)
  client_certificate_mode            = lookup(var.site_config, "client_certificate_mode", "Required")
  client_certificate_exclusion_paths = lookup(var.site_config, "client_certificate_exclusion_paths", null)

  dynamic "site_config" {
    for_each = [local.site_config]
    content {
      linux_fx_version                              = lookup(site_config.value, "linux_fx_version", null)
      container_registry_managed_identity_client_id = lookup(site_config.value, "container_registry_managed_identity_client_id", null)
      container_registry_use_managed_identity       = lookup(site_config.value, "container_registry_use_managed_identity", false)
      always_on                                     = lookup(site_config.value, "always_on", null)
      app_command_line                              = lookup(site_config.value, "app_command_line", null)
      default_documents                             = lookup(site_config.value, "default_documents", null)
      ftps_state                                    = lookup(site_config.value, "ftps_state", "FtpsOnly")
      health_check_path                             = lookup(site_config.value, "health_check_path", null)
      http2_enabled                                 = lookup(site_config.value, "http2_enabled", false)
      local_mysql_enabled                           = lookup(site_config.value, "local_mysql_enabled", false)
      managed_pipeline_mode                         = lookup(site_config.value, "managed_pipeline_mode", null)
      minimum_tls_version                           = lookup(site_config.value, "minimum_tls_version", lookup(site_config.value, "min_tls_version", "1.2"))
      remote_debugging_enabled                      = lookup(site_config.value, "remote_debugging_enabled", false)
      remote_debugging_version                      = lookup(site_config.value, "remote_debugging_version", null)
      use_32_bit_worker                             = lookup(site_config.value, "use_32_bit_worker", false)
      websockets_enabled                            = lookup(site_config.value, "websockets_enabled", false)
      worker_count                                  = lookup(site_config.value, "worker_count", var.linux_web_app_worker_count)
      ip_restriction_default_action                 = lookup(site_config.value, "ip_restriction_default_action", var.ip_restriction_default_action)

      dynamic "ip_restriction" {
        for_each = var.ip_restrictions
        content {
          name                      = ip_restriction.value.name
          ip_address                = ip_restriction.value.ip_address
          virtual_network_subnet_id = ip_restriction.value.virtual_network_subnet_id
          service_tag               = ip_restriction.value.service_tag
          priority                  = ip_restriction.value.priority
          action                    = ip_restriction.value.action
          headers                   = ip_restriction.value.headers
        }
      }

      dynamic "scm_ip_restriction" {
        for_each = concat(local.scm_subnets, local.scm_cidrs, local.scm_service_tags)
        content {
          name                      = scm_ip_restriction.value.name
          ip_address                = scm_ip_restriction.value.ip_address
          virtual_network_subnet_id = scm_ip_restriction.value.virtual_network_subnet_id
          service_tag               = scm_ip_restriction.value.service_tag
          priority                  = scm_ip_restriction.value.priority
          action                    = scm_ip_restriction.value.action
          headers                   = scm_ip_restriction.value.headers
        }
      }
      scm_minimum_tls_version     = lookup(site_config.value, "scm_minimum_tls_version", "1.2")
      scm_use_main_ip_restriction = length(var.scm_authorized_ips) > 0 || var.scm_authorized_subnet_ids != null ? false : true

      vnet_route_all_enabled = var.app_service_vnet_integration_subnet_id != null

      application_stack {
        docker_image_name        = var.linux_app_stack.docker.enabled ? var.linux_app_stack.docker.image : null
        docker_registry_url      = var.linux_app_stack.docker.enabled ? format("https://%s", var.linux_app_stack.docker.registry_url) : null
        docker_registry_username = var.linux_app_stack.docker.enabled ? var.linux_app_stack.docker.registry_username : null
        docker_registry_password = var.linux_app_stack.docker.enabled ? var.linux_app_stack.docker.registry_password : null

        dotnet_version      = var.linux_app_stack.type == "dotnet" ? var.linux_app_stack.dotnet_version : null
        node_version        = var.linux_app_stack.type == "node" ? var.linux_app_stack.node_version : null
        java_version        = var.linux_app_stack.type == "java" ? var.linux_app_stack.java_version : null
        java_server         = var.linux_app_stack.type == "java" ? var.linux_app_stack.java_server : null
        java_server_version = var.linux_app_stack.type == "java" ? var.linux_app_stack.java_server_version : null
        php_version         = var.linux_app_stack.type == "php" ? var.linux_app_stack.php_version : null
        python_version      = var.linux_app_stack.type == "python" ? var.linux_app_stack.python_version : null
        ruby_version        = var.linux_app_stack.type == "ruby" ? var.linux_app_stack.ruby_version : null
        go_version          = var.linux_app_stack.type == "go" ? var.linux_app_stack.go_version : null
      }

      dynamic "cors" {
        for_each = lookup(site_config.value, "cors", [])
        content {
          allowed_origins     = cors.value.allowed_origins
          support_credentials = lookup(cors.value, "support_credentials", null)
        }
      }
    }
  }

  app_settings = var.staging_slot_custom_app_settings == null ? local.app_settings : merge(local.default_app_settings, var.staging_slot_custom_app_settings)

  dynamic "connection_string" {
    for_each = var.connection_strings
    content {
      name  = lookup(connection_string.value, "name", null)
      type  = lookup(connection_string.value, "type", null)
      value = lookup(connection_string.value, "value", null)
    }
  }

  # NOTE: auth_settings is the legacy authentication configuration (v1).
  # For new implementations, prefer auth_settings_v2 which offers enhanced features,
  # better provider support, and more granular controls.
  # Both blocks are maintained for backward compatibility.
  dynamic "auth_settings" {
    for_each = local.auth_settings.enabled ? ["enabled"] : []
    content {
      enabled                        = local.auth_settings.enabled
      issuer                         = local.auth_settings.issuer
      token_store_enabled            = local.auth_settings.token_store_enabled
      unauthenticated_client_action  = local.auth_settings.unauthenticated_client_action
      default_provider               = local.auth_settings.default_provider
      allowed_external_redirect_urls = local.auth_settings.allowed_external_redirect_urls
      additional_login_parameters    = lookup(local.auth_settings, "additional_login_parameters", null)
      runtime_version                = lookup(local.auth_settings, "runtime_version", null)
      token_refresh_extension_hours  = lookup(local.auth_settings, "token_refresh_extension_hours", 72)

      dynamic "facebook" {
        for_each = lookup(local.auth_settings, "facebook", null) != null ? [local.auth_settings.facebook] : []
        content {
          app_id     = lookup(facebook.value, "app_id", null)
          app_secret = lookup(facebook.value, "app_secret", null)
        }
      }

      dynamic "github" {
        for_each = lookup(local.auth_settings, "github", null) != null ? [local.auth_settings.github] : []
        content {
          client_id     = lookup(github.value, "client_id", null)
          client_secret = lookup(github.value, "client_secret", null)
        }
      }

      dynamic "google" {
        for_each = lookup(local.auth_settings, "google", null) != null ? [local.auth_settings.google] : []
        content {
          client_id     = lookup(google.value, "client_id", null)
          client_secret = lookup(google.value, "client_secret", null)
        }
      }

      dynamic "microsoft" {
        for_each = lookup(local.auth_settings, "microsoft", null) != null ? [local.auth_settings.microsoft] : []
        content {
          client_id     = lookup(microsoft.value, "client_id", null)
          client_secret = lookup(microsoft.value, "client_secret", null)
        }
      }

      dynamic "twitter" {
        for_each = lookup(local.auth_settings, "twitter", null) != null ? [local.auth_settings.twitter] : []
        content {
          consumer_key    = lookup(twitter.value, "consumer_key", null)
          consumer_secret = lookup(twitter.value, "consumer_secret", null)
        }
      }

      dynamic "active_directory" {
        for_each = local.auth_settings_active_directory.client_id == null ? [] : [local.auth_settings_active_directory]
        content {
          client_id         = local.auth_settings_active_directory.client_id
          client_secret     = local.auth_settings_active_directory.client_secret
          allowed_audiences = concat(formatlist("https://%s", [format("%s.azurewebsites.net", format("%s-app", module.labels.id))]), local.auth_settings_active_directory.allowed_audiences)
        }
      }
    }
  }

  # RECOMMENDED: auth_settings_v2 is the modern authentication configuration
  # with comprehensive provider support and advanced features.
  dynamic "auth_settings_v2" {
    for_each = lookup(var.auth_settings_v2, "auth_enabled", false) ? [var.auth_settings_v2] : []
    content {
      auth_enabled                            = lookup(auth_settings_v2.value, "auth_enabled", false)
      runtime_version                         = lookup(auth_settings_v2.value, "runtime_version", "~1")
      config_file_path                        = lookup(auth_settings_v2.value, "config_file_path", null)
      require_authentication                  = lookup(auth_settings_v2.value, "require_authentication", false)
      unauthenticated_action                  = lookup(auth_settings_v2.value, "unauthenticated_action", "RedirectToLoginPage")
      default_provider                        = lookup(auth_settings_v2.value, "default_provider", "azureactivedirectory")
      excluded_paths                          = lookup(auth_settings_v2.value, "excluded_paths", null)
      require_https                           = lookup(auth_settings_v2.value, "require_https", true)
      http_route_api_prefix                   = lookup(auth_settings_v2.value, "http_route_api_prefix", "/.auth")
      forward_proxy_convention                = lookup(auth_settings_v2.value, "forward_proxy_convention", "NoProxy")
      forward_proxy_custom_host_header_name   = lookup(auth_settings_v2.value, "forward_proxy_custom_host_header_name", null)
      forward_proxy_custom_scheme_header_name = lookup(auth_settings_v2.value, "forward_proxy_custom_scheme_header_name", null)

      dynamic "apple_v2" {
        for_each = try(var.auth_settings_v2.apple_v2[*], [])
        content {
          client_id                  = lookup(apple_v2.value, "client_id", null)
          client_secret_setting_name = lookup(apple_v2.value, "client_secret_setting_name", null)
        }
      }

      dynamic "active_directory_v2" {
        for_each = try(var.auth_settings_v2.active_directory_v2[*], [])

        content {
          client_id                            = lookup(active_directory_v2.value, "client_id", null)
          tenant_auth_endpoint                 = lookup(active_directory_v2.value, "tenant_auth_endpoint", null)
          client_secret_setting_name           = lookup(active_directory_v2.value, "client_secret_setting_name", null)
          client_secret_certificate_thumbprint = lookup(active_directory_v2.value, "client_secret_certificate_thumbprint", null)
          jwt_allowed_groups                   = lookup(active_directory_v2.value, "jwt_allowed_groups", null)
          jwt_allowed_client_applications      = lookup(active_directory_v2.value, "jwt_allowed_client_applications", null)
          www_authentication_disabled          = lookup(active_directory_v2.value, "www_authentication_disabled", false)
          allowed_groups                       = lookup(active_directory_v2.value, "allowed_groups", null)
          allowed_identities                   = lookup(active_directory_v2.value, "allowed_identities", null)
          allowed_applications                 = lookup(active_directory_v2.value, "allowed_applications", null)
          login_parameters                     = lookup(active_directory_v2.value, "login_parameters", null)
        }
      }

      dynamic "azure_static_web_app_v2" {
        for_each = try(var.auth_settings_v2.azure_static_web_app_v2[*], [])
        content {
          client_id = lookup(azure_static_web_app_v2.value, "client_id", null)
        }
      }

      dynamic "custom_oidc_v2" {
        for_each = try(var.auth_settings_v2.custom_oidc_v2[*], [])
        content {
          name                          = lookup(custom_oidc_v2.value, "name", null)
          client_id                     = lookup(custom_oidc_v2.value, "client_id", null)
          openid_configuration_endpoint = lookup(custom_oidc_v2.value, "openid_configuration_endpoint", null)
          name_claim_type               = lookup(custom_oidc_v2.value, "name_claim_type", null)
          scopes                        = lookup(custom_oidc_v2.value, "scopes", null)
          client_credential_method      = lookup(custom_oidc_v2.value, "client_credential_method", null)
          client_secret_setting_name    = lookup(custom_oidc_v2.value, "client_secret_setting_name", null)
          authorisation_endpoint        = lookup(custom_oidc_v2.value, "authorisation_endpoint", null)
          token_endpoint                = lookup(custom_oidc_v2.value, "token_endpoint", null)
          issuer_endpoint               = lookup(custom_oidc_v2.value, "issuer_endpoint", null)
          certification_uri             = lookup(custom_oidc_v2.value, "certification_uri", null)
        }
      }

      dynamic "facebook_v2" {
        for_each = try(var.auth_settings_v2.facebook_v2[*], [])
        content {
          app_id                  = lookup(facebook_v2.value, "app_id", null)
          app_secret_setting_name = lookup(facebook_v2.value, "app_secret_setting_name", null)
          graph_api_version       = lookup(facebook_v2.value, "graph_api_version", null)
          login_scopes            = lookup(facebook_v2.value, "login_scopes", null)
        }
      }

      dynamic "github_v2" {
        for_each = try(var.auth_settings_v2.github_v2[*], [])
        content {
          client_id                  = lookup(github_v2.value, "client_id", null)
          client_secret_setting_name = lookup(github_v2.value, "client_secret_setting_name", null)
          login_scopes               = lookup(github_v2.value, "login_scopes", null)
        }
      }

      dynamic "google_v2" {
        for_each = try(var.auth_settings_v2.google_v2[*], [])
        content {
          client_id                  = lookup(google_v2.value, "client_id", null)
          client_secret_setting_name = lookup(google_v2.value, "client_secret_setting_name", null)
          allowed_audiences          = lookup(google_v2.value, "allowed_audiences", null)
          login_scopes               = lookup(google_v2.value, "login_scopes", null)
        }
      }

      dynamic "microsoft_v2" {
        for_each = try(var.auth_settings_v2.microsoft_v2[*], [])
        content {
          client_id                  = lookup(microsoft_v2.value, "client_id", null)
          client_secret_setting_name = lookup(microsoft_v2.value, "client_secret_setting_name", null)
          allowed_audiences          = lookup(microsoft_v2.value, "allowed_audiences", null)
          login_scopes               = lookup(microsoft_v2.value, "login_scopes", null)
        }
      }

      dynamic "twitter_v2" {
        for_each = try(var.auth_settings_v2.twitter_v2[*], [])
        content {
          consumer_key                 = lookup(twitter_v2.value, "consumer_key", null)
          consumer_secret_setting_name = lookup(twitter_v2.value, "consumer_secret_setting_name", null)
        }
      }

      login {
        logout_endpoint                   = lookup(local.auth_settings_v2_login, "logout_endpoint", null)
        cookie_expiration_convention      = lookup(local.auth_settings_v2_login, "cookie_expiration_convention", "FixedTime")
        cookie_expiration_time            = lookup(local.auth_settings_v2_login, "cookie_expiration_time", "08:00:00")
        preserve_url_fragments_for_logins = lookup(local.auth_settings_v2_login, "preserve_url_fragments_for_logins", false)
        token_refresh_extension_time      = lookup(local.auth_settings_v2_login, "token_refresh_extension_time", 72)
        token_store_enabled               = lookup(local.auth_settings_v2_login, "token_store_enabled", false)
        token_store_path                  = lookup(local.auth_settings_v2_login, "token_store_path", null)
        token_store_sas_setting_name      = lookup(local.auth_settings_v2_login, "token_store_sas_setting_name", null)
        validate_nonce                    = lookup(local.auth_settings_v2_login, "validate_nonce", true)
        nonce_expiration_time             = lookup(local.auth_settings_v2_login, "nonce_expiration_time", "00:05:00")
      }
    }
  }

  client_affinity_enabled = var.client_affinity_enabled
  https_only              = var.https_only

  dynamic "identity" {
    for_each = var.identity[*]
    content {
      type         = var.identity.type
      identity_ids = var.identity.identity_ids
    }
  }

  dynamic "storage_account" {
    for_each = var.mount_points
    content {
      name         = lookup(storage_account.value, "name", format("%s-%s", storage_account.value["account_name"], storage_account.value["share_name"]))
      type         = lookup(storage_account.value, "type", "AzureFiles")
      account_name = lookup(storage_account.value, "account_name", null)
      share_name   = lookup(storage_account.value, "share_name", null)
      access_key   = lookup(storage_account.value, "access_key", null)
      mount_path   = lookup(storage_account.value, "mount_path", null)
    }
  }

  dynamic "logs" {
    for_each = var.app_service_logs == null ? [] : [var.app_service_logs]
    content {
      detailed_error_messages = lookup(logs.value, "detailed_error_messages", null)
      failed_request_tracing  = lookup(logs.value, "failed_request_tracing", null)

      dynamic "application_logs" {
        for_each = lookup(logs.value, "application_logs", null) == null ? [] : ["application_logs"]

        content {
          dynamic "azure_blob_storage" {
            for_each = lookup(logs.value["application_logs"], "azure_blob_storage", null) == null ? [] : ["azure_blob_storage"]
            content {
              level             = lookup(logs.value["application_logs"]["azure_blob_storage"], "level", null)
              retention_in_days = lookup(logs.value["application_logs"]["azure_blob_storage"], "retention_in_days", null)
              sas_url           = lookup(logs.value["application_logs"]["azure_blob_storage"], "sas_url", null)
            }
          }
          file_system_level = lookup(logs.value["application_logs"], "file_system_level", null)
        }
      }

      dynamic "http_logs" {
        for_each = lookup(logs.value, "http_logs", null) == null ? [] : ["http_logs"]
        content {
          dynamic "azure_blob_storage" {
            for_each = lookup(logs.value["http_logs"], "azure_blob_storage", null) == null ? [] : ["azure_blob_storage"]
            content {
              retention_in_days = lookup(logs.value["http_logs"]["azure_blob_storage"], "retention_in_days", null)
              sas_url           = lookup(logs.value["http_logs"]["azure_blob_storage"], "sas_url", null)
            }
          }
          dynamic "file_system" {
            for_each = lookup(logs.value["http_logs"], "file_system", null) == null ? [] : ["file_system"]
            content {
              retention_in_days = lookup(logs.value["http_logs"]["file_system"], "retention_in_days", null)
              retention_in_mb   = lookup(logs.value["http_logs"]["file_system"], "retention_in_mb", null)
            }
          }
        }
      }
    }
  }

  tags = module.labels.tags

  lifecycle {
    ignore_changes = [
      site_config[0].cors,
      site_config[0].ftps_state
    ]
  }
}