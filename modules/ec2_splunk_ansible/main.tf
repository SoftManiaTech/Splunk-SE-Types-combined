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

# ✅ Add a 25-second wait before creating Ansible files
resource "null_resource" "wait_for_ssh_ready" {
  provisioner "local-exec" {
    command = "sleep 25"
  }

  triggers = {
    always_run = timestamp()
  }
}

# ✅ Create inventory file after wait
resource "local_file" "ansible_inventory" {
  filename = "${path.root}/inventory.ini"

  content = <<EOF
[splunk]
${var.instance_name} ansible_host=${module.base.public_ip} ansible_user=ec2-user ansible_ssh_private_key_file=${abspath("${path.module}/${module.base.final_key_name}.pem")}
EOF

  depends_on = [null_resource.wait_for_ssh_ready]
}

# ✅ Create group_vars after wait
resource "local_file" "ansible_group_vars" {
  filename = "${path.root}/group_vars/all.yml"

  content = <<EOF
---
splunk_instance:
  name: ${var.instance_name}
  private_ip: ${module.base.private_ip}
  instance_id: ${module.base.instance_id}
  splunk_admin_password: admin123
EOF

  depends_on = [null_resource.wait_for_ssh_ready]
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
