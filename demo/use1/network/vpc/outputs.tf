output "aws_subnets_public" {
  value   = module.vpc.aws_subnets_public
}

output "aws_subnets_private" {
  value   = module.vpc.aws_subnets_private
}

output "vpc_id" {
  value  = module.vpc.vpc_id
}

