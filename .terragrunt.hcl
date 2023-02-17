remote_state {
  backend = "s3"
  config = {
    key       = "${path_relative_to_include()}/terraform.tfstate"
    bucket    = local.bucket
    region    = local.region
    #role_arn  = local.role
    #dynamodb  = "terraform-locks"
    encrypt   = true
  }
}


locals {
  account_vars = read_terragrunt_config(find_in_parent_folders(".account.hcl"))
  region_vars  = read_terragrunt_config(find_in_parent_folders(".region.hcl"))

  #role         = local.account_vars.locals.role
  bucket       = local.account_vars.locals.bucket
  region       = local.region_vars.locals.region
}