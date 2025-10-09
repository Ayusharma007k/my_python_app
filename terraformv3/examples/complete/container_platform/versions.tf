variable "image_tag" {
  description = "Tag of the Docker image to deploy"
  type        = string
  default     = "latest"
}
# EnVirement ( dev )
variable "env" {
  description = "Environment name (dev, test, prod)"
  type        = string
  default     = "dev"
}
variable "slot_name" {
  type        = string
  description = "Deployment slot name (blue or green)"
  default     = "blue"
}
variable "docker_registry_url" {
  type        = string
  description = "ACR login server URL"
}