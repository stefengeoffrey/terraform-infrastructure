output "cluster_name" {
  value = aws_eks_cluster.eks-cluster.name
}

output "cluster_id" {
  value = aws_eks_cluster.eks-cluster.id
}

output "cluster_identity_oidc_issuer" {
  value = aws_iam_openid_connect_provider.main.url
}

output "cluster_identity_oidc_issuer_arn" {
  value = aws_iam_openid_connect_provider.main.arn
}

output "cluster_security_group_id" {
  value = aws_eks_cluster.eks-cluster.vpc_config[0].cluster_security_group_id
}

output "aws_iam_role_worker_node" {
  value = aws_iam_role.worker-nodes.arn
}

output "aws_iam_role_worker_node_name" {
  value = aws_iam_role.worker-nodes.name
}

