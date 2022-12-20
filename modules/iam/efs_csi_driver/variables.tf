variable "oidc_url" {
  description = "OpenID Connect provider URL of EKS cluster"
  type        = string
#  validation {
#    condition     = can(regex("^oidc.eks.[\\w-]*.amazonaws.com\\/id\\/.*", var.oidc_url))
#    error_message = "The oidc_url value must be a valid OpenID URL in following format \"oidc.eks.<region-code>.amazonaws.com/id/<unique-id>\"."
#  }
}

variable "oidc_arn" {
  description = "OpenID Connect provier ARN of EKS cluster"
  type        = string
#  validation {
#    condition     = can(regex("^arn:aws:iam:", var.oidc_arn))
#    error_message = "The oidc_arn should be a valid ARN."
#  }
}
