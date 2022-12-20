# eks
variable "cluster_name" {
  type        = string
  description = "Name of the EKS cluster. Also used as a prefix in names of related resources"
  default     = "non-prod"
}


variable "profile" {
  type        = string
  description = "profile"
  default     = "default"
}

variable "aws_region" {
  description = "The AWS region to deploy to (e.g. us-east-1)"
  default     = "us-east-1"
}


variable "account_id" {
  type        = string
  description = "acount id"
  default     = "019766467906"
}

variable "external_dns_chart_version" {
  description = "External-dns Helm chart version to deploy. 3.0.0 is the minimum version for this function"
  type        = string
  default     = "3.2.0"
}

variable "external_dns_chart_log_level" {
  description = "External-dns Helm chart log leve. Possible values are: panic, debug, info, warn, error, fatal"
  type        = string
  default     = "warn"
}

variable "external_dns_zoneType" {
  description = "External-dns Helm chart AWS DNS zone type (public, private or empty for both)"
  type        = string
  default     = "public"
}

variable "external_dns_domain_filters" {
  description = "External-dns Domain filters."
  type        = list(string)
  default     = []
}
