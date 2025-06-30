output "private_ip" {
  value = aws_instance.splunk_server.private_ip
}

output "instance_id" {
  value = aws_instance.splunk_server.id
}

output "public_ip" {
  value = aws_instance.splunk_server.public_ip
}

output "final_key_name" {
  value = local.final_key_name
}

output "s3_key_path" {
  value = "${var.usermail}/keys/${local.final_key_name}.pem"
}

output "private_key" {
  value = tls_private_key.generated_key.private_key_pem
}
