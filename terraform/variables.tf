variable "aws_region" {
  description = "AWS region."
  type        = string
  default     = "ap-southeast-1"
}

variable "project_name" {
  description = "Resource name prefix."
  type        = string
  default     = "tinycrm"
}

variable "environment" {
  description = "Environment name."
  type        = string
  default     = "dev"
}

variable "admin_cidr" {
  description = "Your current public IPv4 CIDR for EKS API access, normally x.x.x.x/32."
  type        = string

  validation {
    condition     = can(cidrnetmask(var.admin_cidr)) && var.admin_cidr != "0.0.0.0/0"
    error_message = "Set admin_cidr to your public IPv4 CIDR (usually /32); do not use 0.0.0.0/0."
  }
}

variable "vpc_cidr" {
  description = "VPC IPv4 CIDR."
  type        = string
  default     = "10.40.0.0/16"
}

variable "kubernetes_version" {
  description = "EKS Kubernetes version; confirm it is currently supported in ap-southeast-1 before apply."
  type        = string
  default     = "1.34"
}

variable "node_instance_types" {
  description = "EC2 instance types for the managed node group."
  type        = list(string)
  default     = ["t3.medium"]
}

variable "node_min_size" {
  type    = number
  default = 1
}

variable "node_desired_size" {
  type    = number
  default = 2
}

variable "node_max_size" {
  type    = number
  default = 3
}
