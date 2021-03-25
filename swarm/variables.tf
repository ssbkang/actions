variable "owner" {
  type    = string
  default = "Steven Kang"
}

variable "pr" {
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

variable "os" {
  type    = string
  default = "win"
}

variable "orchestration" {
  type    = string
  default = "swarm"
}

variable "manager_count" {
  type    = number
  default = 1
}

variable "worker_count" {
  type    = number
  default = 1
}

variable "branch" {
  type    = string
  default = "main"
}