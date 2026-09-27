data "aws_ssm_parameter" "amazon_linux_2023" {
  name = "/aws/service/ami-amazon-linux-latest/al2023-ami-kernel-default-x86_64"
}

locals {
  node_names = ["prod", "test", "dev"]
}

resource "aws_security_group" "instance" {
  name        = "${var.project_name}-sg"
  description = "No inbound access from the internet; SSH only between instances in this group, human access via SSM Session Manager"
  vpc_id      = aws_vpc.this.id

  ingress {
    description = "Allow SSH from ansiblectl to the managed nodes (both share this security group)"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    self        = true
  }

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

# Key pair ansiblectl uses to SSH into the prod/test/dev nodes.
resource "tls_private_key" "ansible" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "aws_instance" "nodes" {
  for_each = toset(local.node_names)

  ami                    = data.aws_ssm_parameter.amazon_linux_2023.value
  instance_type          = var.instance_type
  subnet_id              = aws_subnet.public.id
  vpc_security_group_ids = [aws_security_group.instance.id]
  iam_instance_profile   = aws_iam_instance_profile.ssm_instance_profile.name

  metadata_options {
    http_tokens = "required"
  }

  user_data = templatefile("${path.module}/templates/node_user_data.sh.tftpl", {
    hostname   = each.key
    public_key = tls_private_key.ansible.public_key_openssh
  })

  tags = {
    Name = each.key
  }
}

resource "aws_instance" "ansiblectl" {
  ami                    = data.aws_ssm_parameter.amazon_linux_2023.value
  instance_type          = var.instance_type
  subnet_id              = aws_subnet.public.id
  vpc_security_group_ids = [aws_security_group.instance.id]
  iam_instance_profile   = aws_iam_instance_profile.ssm_instance_profile.name

  metadata_options {
    http_tokens = "required"
  }

  user_data = templatefile("${path.module}/templates/ansiblectl_user_data.sh.tftpl", {
    hostname    = "ansiblectl"
    private_key = tls_private_key.ansible.private_key_openssh
    prod_ip     = aws_instance.nodes["prod"].private_ip
    test_ip     = aws_instance.nodes["test"].private_ip
    dev_ip      = aws_instance.nodes["dev"].private_ip
  })

  tags = {
    Name = "ansiblectl"
  }
}
