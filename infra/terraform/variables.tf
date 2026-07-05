variable "project_name" {
  description = "Name prefix for all resources."
  type        = string
  default     = "capstone-phoenix"
}

variable "environment" {
  description = "Environment tag."
  type        = string
  default     = "prod"
}

variable "aws_region" {
  description = "AWS region to deploy into."
  type        = string
  default     = "eu-west-1"
}

variable "availability_zones" {
  description = "Availability zones for public subnets."
  type        = list(string)
  default     = ["eu-west-1a", "eu-west-1b", "eu-west-1c"]
}

variable "vpc_cidr" {
  description = "VPC CIDR block."
  type        = string
  default     = "10.20.0.0/16"
}

variable "public_subnet_cidrs" {
  description = "Public subnet CIDRs. Provide at least three."
  type        = list(string)
  default     = ["10.20.1.0/24", "10.20.2.0/24", "10.20.3.0/24"]
}

variable "allowed_ssh_cidr" {
  description = "Your public IP in CIDR form, for example 203.0.113.10/32."
  type        = string
}

variable "key_name" {
  description = "Existing AWS EC2 key pair name."
  type        = string
}

variable "instance_type" {
  description = "Instance type for k3s nodes."
  type        = string
  default     = "t3.small"
}

variable "worker_count" {
  description = "Number of k3s worker nodes."
  type        = number
  default     = 2

  validation {
    condition     = var.worker_count >= 2
    error_message = "The capstone requires at least two worker nodes."
  }
}

variable "root_volume_size_gb" {
  description = "Root EBS volume size for each node."
  type        = number
  default     = 30
}
