variable "client_id" {
  description = "Azure Service Principal Client ID"
  type        = string
}

variable "client_secret" {
  description = "Azure Service Principal Client Secret"
  type        = string
}

variable "subscription_id" {
  description = "Azure Subscription ID"
  type        = string
}

variable "tenant_id" {
  description = "Azure Tenant ID"
  type        = string
}

variable "docker_registry_url" {
  description = "Azure Container Registry URL"
  type        = string
}

variable "docker_image_name" {
  description = "Docker image name to deploy"
  type        = string
}

variable "image_tag" {
  description = "Docker image tag"
  type        = string
  default     = "latest"
}

variable "app_settings" {
  description = "App Service settings"
  type        = map(string)
  default     = {}
}

variable "current_slot" {
  description = "Current active slot (blue or green)"
  type        = string
  default     = "blue"
}

variable "auto_swap" {
  description = "Whether to automatically swap the slots"
  type        = bool
  default     = true
}
