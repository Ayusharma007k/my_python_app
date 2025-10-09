###############################################################
# Variables
###############################################################

variable "slot_name" {
  description = "Slot name"
  type        = string
}
variable "image_tag" {
  description = "Tag for the Docker image"
  type        = string
}

variable "location" {
  description = "Azure region for deployment"
  type        = string
  default     = "Canada Central"
}

variable "name" {
  description = "Base name for all resources"
  type        = string
  default     = "ayush-test"
}

variable "environment" {
  description = "Environment name (e.g. dev, staging, prod)"
  type        = string
  default     = "dev"
}

variable "docker_registry_url" {
  description = "Azure Container Registry login server URL"
  type        = string
  default     = "ayushacr123.azurecr.io"
}

variable "docker_image_name" {
  description = "Docker image name for deployment"
  type        = string
  default     = "python-app"
}

variable "acr_id" {
  description = "Resource ID of Azure Container Registry"
  type        = string
  default     = "/subscriptions/1ac2caa4-336e-4daa-b8f1-0fbabe2d4b11/resourceGroups/ayush-rg/providers/Microsoft.ContainerRegistry/registries/ayushacr123"
}

variable "sku_name" {
  description = "App Service plan SKU (S1, P1v2, etc.)"
  type        = string
  default     = "S1"
}

variable "os_type" {
  description = "Operating system type"
  type        = string
  default     = "Linux"
}

variable "enable_logs" {
  description = "Enable or disable App Service logs"
  type        = bool
  default     = true
}

variable "log_retention_days" {
  description = "Days to retain logs"
  type        = number
  default     = 7
}

variable "log_retention_mb" {
  description = "Retention size (MB) for logs"
  type        = number
  default     = 35
}
