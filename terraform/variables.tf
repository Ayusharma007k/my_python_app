variable "location" {
  type    = string
  default = "Canada Central"
}

variable "resource_group_name" {
  type    = string
  default = "ayush-rg"
}

variable "acr_name" {
  type    = string
  default = "ayushacr123"
}

variable "image_tag" {
  type    = string
  default = "latest"
}

variable "env" {
  type    = string
  default = "dev"
}

variable "webapp_name" {
  type    = string
  default = "python-single-app"
}
