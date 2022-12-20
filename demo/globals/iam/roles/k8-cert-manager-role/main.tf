
#########################################################################
#                                                                       #
# s3 location dynamically created by terragrunt to store state file     #
# Providers provide terraform code for their product i.e., aws, azure   #
#                                                                       #
#########################################################################
terraform {
  backend "s3" {}
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 3.0"
    }
    kubernetes = {
      source      = "hashicorp/kubernetes"
      version     = "~> 2.0"
    }
  }
}

provider "aws" {
  region = "us-east-1"
 # assume_role {
 #   role_arn = "arn:aws:iam::210524891490:role/Dev-Admin"


  default_tags {
    tags = {
      Terraform = true
    }
  }
}

provider "helm" {
  kubernetes {
    config_path = "~/.kube/config"
  }
}

#######################################################################
#                                                                     #
# Datasource holds data i.e., terraform state data, this data source  #
# is referencing the vpc state file located on s3                     #
#                                                                     #
#######################################################################
data "terraform_remote_state" "vpc" {
  backend = "s3"
  config = {
        bucket = "geoff-nonprod-terraform-state"
        key    = "non-prod/use1/network/vpc/terraform.tfstate"
        region = "us-east-1"
       # role_arn = "arn:aws:iam::210524891490:role/Dev-Admin"
  }
}

#######################################################################
#                                                                     #
# Datasource holds data i.e., terraform state data, this data source  #
# is referencing the eks state file located on s3                     #
#                                                                     #
#######################################################################
data "terraform_remote_state" "eks" {
  backend = "s3"
  config = {
        bucket = "geoff-nonprod-terraform-state"
        key    = "non-prod/use1/services/eks/terraform.tfstate"
        region = "us-east-1"
       # role_arn = "arn:aws:iam::210524891490:role/Dev-Admin"
  }
}


data "aws_eks_cluster" "cluster" {
  name = data.terraform_remote_state.eks.outputs.cluster_id
}

data "aws_eks_cluster_auth" "cluster" {
  name = data.terraform_remote_state.eks.outputs.cluster_id
}

provider "kubernetes" {
  host                   = data.aws_eks_cluster.cluster.endpoint
  cluster_ca_certificate = base64decode(data.aws_eks_cluster.cluster.certificate_authority.0.data)
  token                  = data.aws_eks_cluster_auth.cluster.token
}


#############################################################
#                                                           #
# Create .kube/config file                                  #
#                                                           #
#############################################################
resource "null_resource" "merge_kubeconfig" {
  triggers = {
    #always = timestamp()
    always = data.terraform_remote_state.eks.outputs.cluster_id
  }


  provisioner "local-exec" {
    command = "aws eks update-kubeconfig --name ${var.cluster_name} --profile ${var.profile} --region=${var.aws_region}"
  }
}



# IAM Role Service Account for the cert-manager

module "cert_manager_irsa" {
  source                        = "terraform-aws-modules/iam/aws//modules/iam-assumable-role-with-oidc"
  version                       = "3.6.0"
  create_role                   = true
  role_name                     = "${var.cluster_name}-cert_manager-irsa"
  provider_url                  = replace(data.terraform_remote_state.eks.outputs.cluster_identity_oidc_issuer, "https://", "")
  role_policy_arns              = [aws_iam_policy.cert_manager_policy.arn]
  oidc_fully_qualified_subjects = ["system:serviceaccount:cert-manager:cert-manager"]
}

resource "aws_iam_policy" "cert_manager_policy" {
  name        = "${var.cluster_name}-cert-manager-policy"
  path        = "/"
  description = "Policy, which allows CertManager to create Route53 records"

  policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Effect" : "Allow",
        "Action" : "route53:GetChange",
        "Resource" : "arn:aws:route53:::change/*"
      },
      {
        "Effect" : "Allow",
        "Action" : [
          "route53:ChangeResourceRecordSets",
          "route53:ListResourceRecordSets"
        ],
        "Resource" : "arn:aws:route53:::hostedzone/Z089021824US5ZGHYN5UC"
      },
    ]
  })
}


output "cert_manager_irsa_role_arn" {
  value = module.cert_manager_irsa.this_iam_role_arn
}