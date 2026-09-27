output "instance_id" {
  description = "ID of the created EC2 instance"
  value       = aws_instance.this.id
}

output "instance_public_ip" {
  description = "Public IP address of the instance"
  value       = aws_instance.this.public_ip
}

output "ssm_connect_command" {
  description = "AWS CLI command to open a Session Manager shell on the instance"
  value       = "aws ssm start-session --target ${aws_instance.this.id} --region ${var.aws_region}"
}
