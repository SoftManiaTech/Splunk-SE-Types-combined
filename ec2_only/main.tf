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
  required_version = ">= 1.2.0"
}

provider "aws" {
  region = var.aws_region
}

# Check if key exists
data "external" "key_check" {
  program = ["${path.cwd}/scripts/check_key.sh", var.key_name, var.aws_region]
}

locals {
  key_exists     = data.external.key_check.result.exists == "true"
  final_key_name = var.key_name
}

# Generate PEM key only if key not exists
resource "tls_private_key" "generated_key" {
  count     = local.key_exists ? 0 : 1
  algorithm = "RSA"
  rsa_bits  = 4096
}

# Create EC2 Key Pair only if key not exists
resource "aws_key_pair" "generated_key_pair" {
  count      = local.key_exists ? 0 : 1
  key_name   = local.final_key_name
  public_key = tls_private_key.generated_key[0].public_key_openssh
}

# Upload PEM to S3 if key not exists
resource "aws_s3_object" "upload_pem_key" {
  count   = local.key_exists ? 0 : 1
  bucket  = "splunk-deployment-test"
  key     = "${var.usermail}/keys/${local.final_key_name}.pem"
  content = tls_private_key.generated_key[0].private_key_pem
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
    to_port     = 8000
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 8089
    to_port     = 8089
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
  key_name               = local.final_key_name
  vpc_security_group_ids = [aws_security_group.splunk_sg.id]

  root_block_device {
    volume_size = var.storage_size
  }

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

output "final_key_name" {
  value = local.final_key_name
}

output "s3_key_path" {
  value = "${var.usermail}/keys/${local.final_key_name}.pem"
}

output "public_ip" {
  value = aws_instance.splunk_server.public_ip
}
