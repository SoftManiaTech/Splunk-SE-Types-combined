terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.16"
    }
  }
  required_version = ">= 1.2.0"
}

provider "aws" {
  region = var.aws_region
}

module "ec2_only" {
  source = "./modules/ec2_only"
  count  = var.build_mode == "ec2_only" ? 1 : 0

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

module "ec2_splunk" {
  source = "./modules/ec2_splunk"
  count  = var.build_mode == "splunk_install" ? 1 : 0

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

module "ec2_splunk_ansible" {
  source = "./modules/ec2_splunk_ansible"
  count  = var.build_mode == "splunk_ansible" ? 1 : 0

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
  value = (
    var.build_mode == "ec2_only" ? module.ec2_only[0].public_ip :
    var.build_mode == "splunk_install" ? module.ec2_splunk[0].public_ip :
    module.ec2_splunk_ansible[0].public_ip
  )
}

output "final_key_name" {
  value = (
    var.build_mode == "ec2_only" ? module.ec2_only[0].final_key_name :
    var.build_mode == "splunk_install" ? module.ec2_splunk[0].final_key_name :
    module.ec2_splunk_ansible[0].final_key_name
  )
}

output "s3_key_path" {
  value = (
    var.build_mode == "ec2_only" ? module.ec2_only[0].s3_key_path :
    var.build_mode == "splunk_install" ? module.ec2_splunk[0].s3_key_path :
    module.ec2_splunk_ansible[0].s3_key_path
  )
}
