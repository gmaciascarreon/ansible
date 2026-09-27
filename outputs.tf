output "ansiblectl_instance_id" {
  description = "ID of the ansiblectl control instance"
  value       = aws_instance.ansiblectl.id
}

output "ansiblectl_public_ip" {
  description = "Public IP address of the ansiblectl control instance"
  value       = aws_instance.ansiblectl.public_ip
}

output "node_instance_ids" {
  description = "IDs of the prod/test/dev instances, keyed by name"
  value       = { for name, inst in aws_instance.nodes : name => inst.id }
}

output "node_private_ips" {
  description = "Private IPs of the prod/test/dev instances, keyed by name"
  value       = { for name, inst in aws_instance.nodes : name => inst.private_ip }
}

output "ssm_connect_commands" {
  description = "AWS CLI commands to open a Session Manager shell on each instance"
  value = merge(
    { ansiblectl = "aws ssm start-session --target ${aws_instance.ansiblectl.id} --region ${var.aws_region}" },
    { for name, inst in aws_instance.nodes : name => "aws ssm start-session --target ${inst.id} --region ${var.aws_region}" }
  )
}

output "ansible_ssh_private_key" {
  description = "Private key ansiblectl uses to SSH into prod/test/dev (already installed on ansiblectl automatically; kept here as a backup)"
  value       = tls_private_key.ansible.private_key_openssh
  sensitive   = true
}
