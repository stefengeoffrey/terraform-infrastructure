# eks
variable "cluster_name" {
  type        = string
  description = "Name of the EKS cluster. Also used as a prefix in names of related resources"
  default     = "non-prod"
}

variable "cluster_version" {
  type        = string
  description = "version of eks"
  default     = "1.22"
}

variable "region" {
  type        = string
  description = "us-east-1"
  default     = "us-east-1"
}

variable "kubeconfig_filename" {
  type        = string
  description = "kubeconfig"
  default     = "config"
}

variable "profile" {
  type        = string
  description = "profile"
  default     = "default"
}

variable "account_id" {
  type        = string
  description = "acount id"
  default     = "019766467906"
}

variable "aws_region" {
  description = "The AWS region to deploy to (e.g. us-east-1)"
  default     = "us-east-1"
}

