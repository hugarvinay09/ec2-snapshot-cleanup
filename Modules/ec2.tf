############################################
# IAM Role for EC2
############################################

resource "aws_iam_role" "ec2_role" {
  name = "${var.environment}-ec2-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        Service = "ec2.amazonaws.com"
      }
      Action = "sts:AssumeRole"
    }]
  })

  tags = {
    Environment = var.environment
  }
}

resource "aws_iam_role_policy_attachment" "ec2_ssm_access" {
  role       = aws_iam_role.ec2_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_instance_profile" "ec2_profile" {
  name = "${var.environment}-ec2-profile"
  role = aws_iam_role.ec2_role.name
}

############################################
# Security Group for EC2
############################################

resource "aws_security_group" "ec2_sg" {
  name        = "${var.environment}-ec2-sg"
  description = "Security Group for EC2"
  vpc_id      = aws_vpc.main.id

  ingress {
    description = "Allow SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = var.create_public_ec2 ? ["0.0.0.0/0"] : [var.vpc_cidr]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "${var.environment}-ec2-sg"
    Environment = var.environment
  }
}

############################################
# EC2 Instance
############################################

resource "aws_instance" "app_server" {
  ami                         = var.ec2_ami_id
  instance_type               = var.instance_type
  key_name                    = var.key_name
  subnet_id                   = var.create_public_ec2 ? aws_subnet.public[0].id : aws_subnet.private[0].id
  vpc_security_group_ids      = [aws_security_group.ec2_sg.id]
  iam_instance_profile        = aws_iam_instance_profile.ec2_profile.name
  associate_public_ip_address = var.create_public_ec2

  root_block_device {
    volume_size = 20
    volume_type = "gp3"
    encrypted   = true
  }

  tags = {
    Name        = "${var.environment}-ec2-instance"
    Environment = var.environment
  }
}

############################################
# Elastic IP (Only if public EC2)
############################################

resource "aws_eip" "ec2_eip" {
  count    = var.create_public_ec2 ? 1 : 0
  instance = aws_instance.app_server.id
  domain   = "vpc"
  user_data              = file("${path.module}/user-data.sh")

  tags = {
    Name        = "${var.environment}-ec2-eip"
    Environment = var.environment
  }
}

############################################
# Outputs
############################################

output "ec2_instance_id" {
  value = aws_instance.app_server.id
}

output "ec2_private_ip" {
  value = aws_instance.app_server.private_ip
}

output "ec2_public_ip" {
  value = var.create_public_ec2 ? aws_eip.ec2_eip[0].public_ip : null
}