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
  user_data      = file("${path.module}/../../splunk-setup.sh")
}

resource "local_file" "pem_file" {
  filename        = "${path.module}/${module.base.final_key_name}.pem"
  content         = module.base.private_key
  file_permission = "0400"
}


resource "local_file" "ansible_inventory" {
  filename = "${path.module}/inventory.ini"

  content = <<EOF
[splunk]
${var.instance_name} ansible_host=${module.base.public_ip} ansible_user=ec2-user ansible_ssh_private_key_file=${path.module}/${module.base.final_key_name}.pem
EOF
}

resource "local_file" "ansible_group_vars" {
  filename = "${path.module}/group_vars.yml"

  content = <<EOF
---
splunk_instance:
  name: ${var.instance_name}
  private_ip: ${module.base.private_ip}
  instance_id: ${module.base.instance_id}
  splunk_admin_password: admin123
EOF
}

resource "null_resource" "wait_for_ssh" {
  provisioner "local-exec" {
    command = "for i in {1..30}; do nc -zv ${module.base.public_ip} 22 && exit 0 || sleep 10; done; echo 'SSH not ready' && exit 1"
  }
}

resource "null_resource" "ansible_provision" {
  depends_on = [
    local_file.ansible_inventory,
    local_file.ansible_group_vars,
    local_file.pem_file,
    null_resource.wait_for_ssh
  ]

  provisioner "local-exec" {
    command = <<EOT
      chmod 400 ${path.module}/${module.base.final_key_name}.pem
      ANSIBLE_HOST_KEY_CHECKING=False ansible-playbook -i ${path.module}/inventory.ini ${path.module}/../../botsv3-setup.yml
    EOT
  }
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