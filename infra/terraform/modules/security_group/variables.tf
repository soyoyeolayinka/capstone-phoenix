variable "project_name" {
  type = string
}

variable "environment" {
  type = string
}

variable "vpc_id" {
  type = string
}

variable "allowed_ssh_cidr" {
  type = string
}

variable "node_internal_cidrs" {
  type = list(string)
}

variable "allow_public_http_tls" {
  type = bool
}
