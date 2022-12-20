terraform {
  backend "s3" {}

  required_providers {
    aws = {
      source = "hashicorp/aws"
      version = "~> 3.0"
    }
  }
}

data "terraform_remote_state" "vpc" {
    backend = "s3"
    config  = {
        bucket = "demo-geoff-terraform-state"
        key    = "non-prod/use1/network/vpc/terraform.tfstate"
        region = "us-east-1"
    }
}


locals {
  zone_name = "geoff-example.com"
  zone_id = "Z089021824US5ZGHYN5UC"
}



module "records" {
source  = "../../../../modules/route53/records"

  zone_name = local.zone_name
  #  zone_id = local.zone_id

  records = [
    {
      name = ""
      type = "A"
      ttl  = 3600
      records = [
        "10.10.10.10",
      ]
    },

  ]

}

