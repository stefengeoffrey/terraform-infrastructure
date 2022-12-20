
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
        bucket = "demo-geoff-terraform-state"
        key    = "demo/use1/network/vpc/terraform.tfstate"
        region = "us-east-1"
  }
}

######################################################################
#                                                                    #
# EKS resources are aws provider services configuration              #
#                                                                    #
######################################################################
resource "aws_iam_role" "eks-iam-role" {
  name = "eks-iam-role"

  path = "/"

  assume_role_policy = <<EOF
{
 "Version": "2012-10-17",
 "Statement": [
  {
   "Effect": "Allow",
   "Principal": {
    "Service": "eks.amazonaws.com"
   },
   "Action": "sts:AssumeRole"
  }
 ]
}
EOF

}

#############################################################
#                                                           #
# Attach EKS Cluster policies to cluster role               #
#                                                           #
#############################################################
resource "aws_iam_role_policy_attachment" "AmazonEKSClusterPolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
  role       = aws_iam_role.eks-iam-role.name
}

resource "aws_iam_role_policy_attachment" "AmazonEC2ContainerRegistryReadOnly-EKS" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
  role       = aws_iam_role.eks-iam-role.name
}

##############################################################
#                                                            #
# Create EKS Cluster                                         #
#                                                            #
##############################################################
resource "aws_eks_cluster" "eks-cluster" {
  name     = var.cluster_name
  version  = var.cluster_version
  role_arn = aws_iam_role.eks-iam-role.arn

  vpc_config {
    subnet_ids = [data.terraform_remote_state.vpc.outputs.aws_subnets_private[0], data.terraform_remote_state.vpc.outputs.aws_subnets_private[1]]
  }

  depends_on = [
    aws_iam_role.eks-iam-role,
  ]
}

########################################################
#                                                      #
# Create worker role                                   #
#                                                      #
########################################################
resource "aws_iam_role" "worker-nodes" {
  name = "eks-node-group"

  assume_role_policy = jsonencode({
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "ec2.amazonaws.com"
      }
    }]
    Version = "2012-10-17"
  })
}

#############################################################
#                                                           #
# Attach EKS worker policies to worker role                 #
#                                                           #
#############################################################
resource "aws_iam_role_policy_attachment" "AmazonEKSWorkerNodePolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
  role       = aws_iam_role.worker-nodes.name
}

resource "aws_iam_role_policy_attachment" "AmazonEKS_CNI_Policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
  role       = aws_iam_role.worker-nodes.name
}

resource "aws_iam_role_policy_attachment" "EC2InstanceProfileForImageBuilderECRContainerBuilds" {
  policy_arn = "arn:aws:iam::aws:policy/EC2InstanceProfileForImageBuilderECRContainerBuilds"
  role       = aws_iam_role.worker-nodes.name
}

resource "aws_iam_role_policy_attachment" "AmazonEC2ContainerRegistryReadOnly" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
  role       = aws_iam_role.worker-nodes.name
}

#resource "aws_iam_role_policy_attachment" "AmazonLoadBalancerController" {
#  policy_arn = aws_iam_policy.aws-load-balancer-controller.arn
#  role       = aws_iam_role.worker-nodes.name
#}

#############################################################
#                                                           #
# Create node group                                         #
#                                                           #
#############################################################
resource "aws_eks_node_group" "worker-node-group" {
  cluster_name    = var.cluster_name
  node_group_name = "worker-nodes"
  node_role_arn   = aws_iam_role.worker-nodes.arn
  subnet_ids      = [data.terraform_remote_state.vpc.outputs.aws_subnets_private[0], data.terraform_remote_state.vpc.outputs.aws_subnets_private[1]]
  instance_types  = ["t3.large"]

  scaling_config {
    desired_size = 2
    max_size     = 2
    min_size     = 0
  }

  depends_on = [
    aws_iam_role_policy_attachment.AmazonEKSWorkerNodePolicy,
    aws_iam_role_policy_attachment.AmazonEKS_CNI_Policy,
    aws_eks_cluster.eks-cluster
    #aws_iam_role_policy_attachment.AmazonEC2ContainerRegistryReadOnly,
  ]
}

data "aws_eks_cluster" "cluster" {
  name = aws_eks_cluster.eks-cluster.id
}

data "aws_eks_cluster_auth" "cluster" {
  name = aws_eks_cluster.eks-cluster.id
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
    always = aws_eks_cluster.eks-cluster.id
  }


  provisioner "local-exec" {
    command = "aws eks update-kubeconfig --name ${var.cluster_name} --profile ${var.profile} --region=${var.region}"
  }
}



#############################################################
#                                                           #
# Create oidc provider                                      #
#                                                           #
#############################################################
data "tls_certificate" "main" {
  url = aws_eks_cluster.eks-cluster.identity.0.oidc.0.issuer
}

resource "aws_iam_openid_connect_provider" "main" {
  url = aws_eks_cluster.eks-cluster.identity.0.oidc.0.issuer

  client_id_list = [
    "sts.amazonaws.com",
  ]

  thumbprint_list = [
    data.tls_certificate.main.certificates.0.sha1_fingerprint
  ]
}


