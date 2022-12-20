
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

##############################################################
#                                                            #
# External DNS role                                          #
#                                                            #
##############################################################
resource "aws_iam_role" "external_dns" {
  name  = "${var.cluster_name}-external-dns"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Federated": "arn:aws:iam::${var.account_id}:oidc-provider/${data.terraform_remote_state.eks.outputs.cluster_identity_oidc_issuer}"
      },
      "Action": "sts:AssumeRoleWithWebIdentity",
      "Condition": {
        "StringEquals": {
          "${data.terraform_remote_state.eks.outputs.cluster_identity_oidc_issuer}:sub": "system:serviceaccount:kube-system:external-dns"
        }
      }
    }
  ]
}
EOF

}

##############################################################
#                                                            #
# External DNS role policy                                   #
#                                                            #
##############################################################
resource "aws_iam_role_policy" "external_dns" {
  name_prefix = "${var.cluster_name}-external-dns"
  role        = aws_iam_role.external_dns.name
  policy      = file("${path.module}/files/external-dns-iam-policy.json")
}

##############################################################
#                                                            #
# External DNS kubernetes service account                    #
#                                                            #
##############################################################
resource "kubernetes_service_account" "external_dns" {
  metadata {
    name      = "external-dns"
    namespace = "kube-system"
    annotations = {
      "eks.amazonaws.com/role-arn" = aws_iam_role.external_dns.arn
    }
  }
  automount_service_account_token = true
}

##############################################################
#                                                            #
# Kubernetes cluster role                                    #
#                                                            #
##############################################################
resource "kubernetes_cluster_role" "external_dns" {
  metadata {
    name = "external-dns"
  }

  rule {
    api_groups = [""]
    resources  = ["services", "pods", "nodes"]
    verbs      = ["get", "list", "watch"]
  }
  rule {
    api_groups = ["extensions", "networking.k8s.io"]
    resources  = ["ingresses"]
    verbs      = ["get", "list", "watch"]
  }
  rule {
    api_groups = ["networking.istio.io"]
    resources  = ["gateways"]
    verbs      = ["get", "list", "watch"]
  }
}

##############################################################
#                                                            #
# Kubernetes cluster role  binding                           #
#                                                            #
##############################################################
resource "kubernetes_cluster_role_binding" "external_dns" {
  metadata {
    name = "external-dns"
  }
  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "ClusterRole"
    name      = kubernetes_cluster_role.external_dns.metadata.0.name
  }
  subject {
    kind      = "ServiceAccount"
    name      = kubernetes_service_account.external_dns.metadata.0.name
    namespace = kubernetes_service_account.external_dns.metadata.0.namespace
  }
}

