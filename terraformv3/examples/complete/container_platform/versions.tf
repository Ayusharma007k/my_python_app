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