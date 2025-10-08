###########################################################
# Core Variables
###########################################################

variable "env" {
  description = "Environment name (dev, stage, prod)"
  type        = string
  default     = "dev"
}

variable "location" {
  description = "Azure region for deployment"
  type        = string
  default     = "Canada Central"
}

variable "resource_group_name" {
  description = "Resource group name"
  type        = string
  default     = "ayush-test-rg"
}

variable "docker_image_name" {
  description = "Docker image name"
  type        = string
  default     = "python-app"
}

variable "docker_registry_url" {
  description = "Docker registry URL"
  type        = string
  default     = "ayushacr123.azurecr.io"
}

variable "docker_registry_username" {
  description = "Docker registry username"
  type        = string
}

variable "docker_registry_password" {
  description = "Docker registry password"
  type        = string
}

variable "acr_id" {
  description = "Azure Container Registry resource ID"
  type        = string
  default     = "/subscriptions/1ac2caa4-336e-4daa-b8f1-0fbabe2d4b11/resourceGroups/ayush-rg/providers/Microsoft.ContainerRegistry/registries/ayushacr123"
}

###########################################################
# Blue-Green Deployment Variables
###########################################################

variable "deployment_slot" {
  description = "The slot name to deploy to (blue or green)"
  type        = string
  default     = "blue"
}

variable "image_tag" {
  description = "Docker image tag to deploy"
  type        = string
  default     = "latest"
}
