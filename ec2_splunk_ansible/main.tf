terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.16"
    }
    tls = {
      source  = "hashicorp/tls"
      version = "~> 4.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.0"
    }
    null = {
      source  = "hashicorp/null"
      version = "~> 3.0"
    }
    external = {
      source  = "hashicorp/external"
      version = "~> 2.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

data "external" "key_check" {
  program = ["${path.cwd}/scripts/check_key.sh", var.key_name, var.aws_region]
}

resource "random_integer" "suffix" {
  min = 10
  max = 99
}

locals {
  key_exists     = data.external.key_check.result.exists == "true"
  suffix         = local.key_exists ? data.external.key_check.result.next_suffix : ""
  final_key_name = "${var.key_name}${local.suffix}"
}

resource "tls_private_key" "generated_key" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "aws_key_pair" "generated_key_pair" {
  key_name   = local.final_key_name
  public_key = tls_private_key.generated_key.public_key_openssh
}

resource "aws_s3_object" "upload_pem_key" {
  bucket  = "splunk-deployment-test"
  key     = "${var.usermail}/keys/${local.final_key_name}.pem"
  content = tls_private_key.generated_key.private_key_pem

}

resource "random_id" "sg_suffix" {
  byte_length = 2
}

resource "aws_security_group" "splunk_sg" {
  name        = "splunk-security-group-${random_id.sg_suffix.hex}"
  description = "Security group for Splunk server"

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 8000
    to_port     = 9999
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }


  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

data "aws_ami" "rhel9" {
  most_recent = true

  filter {
    name   = "name"
    values = ["RHEL-9.*x86_64-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["309956199498"]
}

resource "aws_instance" "splunk_server" {
  ami                    = data.aws_ami.rhel9.id
  instance_type          = var.instance_type
  key_name               = aws_key_pair.generated_key_pair.key_name
  vpc_security_group_ids = [aws_security_group.splunk_sg.id]

  root_block_device {
    volume_size = var.storage_size
  }


  user_data = file("splunk-setup.sh")

  tags = {
    Name          = var.instance_name
    AutoStop      = true
    Owner         = var.usermail
    UserEmail     = var.usermail
    RunQuotaHours = var.quotahours
    HoursPerDay   = var.hoursperday
    Category      = var.category
    PlanStartDate = var.planstartdate
  }
}

resource "local_file" "pem_file" {
  filename        = "${path.module}/${local.final_key_name}.pem"
  content         = module.base.private_key
  file_permission = "0400"
}

# ✅ Add a 25-second wait before creating Ansible files
resource "null_resource" "wait_for_ssh_ready" {
  provisioner "local-exec" {
    command = "sleep 85"
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
${var.instance_name} ansible_host=${aws_instance.splunk_server.public_ip} ansible_user=ec2-user ansible_ssh_private_key_file=${abspath("${path.module}/${local.final_key_name}.pem")}
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
  private_ip: ${aws_instance.splunk_server.private_ip}
  instance_id: ${aws_instance.splunk_server.id}
  splunk_admin_password: admin123
EOF

  depends_on = [null_resource.wait_for_ssh_ready]
}

output "public_ip" {
  value = aws_instance.splunk_server.public_ip
}

output "final_key_name" {
  value = local.final_key_name
}

output "s3_key_path" {
  value = aws_s3_object.upload_pem_key.key
}
