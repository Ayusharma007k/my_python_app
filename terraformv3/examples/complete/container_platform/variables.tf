variable "docker_image_name" {
  description = "Docker image name"
  type        = string
}

variable "docker_registry_url" {
  description = "ACR URL"
  type        = string
}

variable "image_tag" {
  description = "Docker image tag (run number or latest)"
  type        = string
}

variable "app_settings" {
  description = "App service settings"
  type        = map(string)
  default     = {}
}

variable "current_slot" {
  description = "Current active slot (blue or green)"
  type        = string
  default     = ""
}

variable "env" {
  description = "Environment name (dev, test, prod)"
  type        = string
  default     = "dev"
}
