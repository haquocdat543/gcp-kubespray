variable "projectId" {
  type = string
  sensitive = true
}

variable "region" {
  default = "asia-northeast1"
  type = string
}

variable "ssh_key" {
  sensitive = true
  type = string
}
