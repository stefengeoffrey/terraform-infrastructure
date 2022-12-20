# EFS CSI Driver
resource "aws_iam_policy" "main" {
  name        = "AmazonEKS_EFS_CSI_Driver_Policy"
  path        = "/"
  description = "Policy for EKS EFS CSI Driver"

  # Terraform's "jsonencode" function converts a
  # Terraform expression result to valid JSON syntax.
  policy = file("${path.module}/AmazonEKS_EFS_CSI_Driver_Policy.json")
}

resource "aws_iam_role" "main" {
  name = "AmazonEKS_EFS_CSI_DriverRole"

  # Terraform's "jsonencode" function converts a
  # Terraform expression result to valid JSON syntax.
  assume_role_policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Effect" : "Allow",
        "Principal" : {
          "Federated" : var.oidc_arn
        },
        "Action" : "sts:AssumeRoleWithWebIdentity",
        "Condition" : {
          "StringEquals" : {
            "${var.oidc_url}:sub" : "system:serviceaccount:kube-system:efs-csi-controller-sa"
          }
        }
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "main" {
  role       = aws_iam_role.main.name
  policy_arn = aws_iam_policy.main.arn
}
