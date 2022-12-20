output "role_arn" {
  value       = aws_iam_role.main.arn
  description = "EFS Driver Role ARN - should be referenced in k8s's ServiceAccount"
}
