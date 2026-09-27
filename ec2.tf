data "aws_ssm_parameter" "amazon_linux_2023" {
  name = "/aws/service/ami-amazon-linux-latest/al2023-ami-kernel-default-x86_64"
}

resource "aws_security_group" "instance" {
  name        = "${var.project_name}-sg"
  description = "No inbound access; instance is reached only via SSM Session Manager"
  vpc_id      = aws_vpc.this.id

  egress {
    description = "Allow all outbound traffic (required for the SSM agent to reach AWS endpoints)"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.project_name}-sg"
  }
}

resource "aws_instance" "this" {
  ami                    = data.aws_ssm_parameter.amazon_linux_2023.value
  instance_type          = var.instance_type
  subnet_id              = aws_subnet.public.id
  vpc_security_group_ids = [aws_security_group.instance.id]
  iam_instance_profile   = aws_iam_instance_profile.ssm_instance_profile.name

  metadata_options {
    http_tokens = "required"
  }

  tags = {
    Name = "${var.project_name}"
  }
}
