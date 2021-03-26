variable "owner" {
  type    = string
  default = "Steven Kang"
}

variable "pr_or_branch" {
  type    = string
  default = "pr9000"
}

variable "location" {
  type    = string
  default = "australiaeast"
}

variable "portainer_image" {
  type    = string
  default = "portainerci/portainer:develop"
}
