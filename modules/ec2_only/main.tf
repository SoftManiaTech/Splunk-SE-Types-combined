module "base" {
  source = "../base"

  aws_region     = var.aws_region
  instance_name  = var.instance_name
  usermail       = var.usermail
  key_name       = var.key_name
  instance_type  = var.instance_type
  storage_size   = var.storage_size
  quotahours     = var.quotahours
  hoursperday    = var.hoursperday
  category       = var.category
  planstartdate  = var.planstartdate
  user_data      = ""
}

output "public_ip" {
  value = module.base.public_ip
}

output "final_key_name" {
  value = module.base.final_key_name
}

output "s3_key_path" {
  value = module.base.s3_key_path
}
