# Security Group dla EFS
resource "aws_security_group" "efs" {
  name        = "${var.project_name}-efs-sg"
  description = "Security group for EFS - allows NFS access from RabbitMQ ECS tasks"
  vpc_id      = aws_vpc.main.id

  ingress {
    description     = "NFS from RabbitMQ ECS tasks"
    from_port       = 2049
    to_port         = 2049
    protocol        = "tcp"
    security_groups = [aws_security_group.rabbitmq.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.project_name}-efs-sg"
  }
}

# EFS File System - zoptymalizowany pod kątem kosztów
resource "aws_efs_file_system" "rabbitmq" {
  creation_token = "${var.project_name}-rabbitmq-efs"
  encrypted      = true

  performance_mode = "generalPurpose"
  throughput_mode  = "bursting" 

  tags = {
    Name = "${var.project_name}-rabbitmq-efs"
  }
}

# EFS Mount Target
resource "aws_efs_mount_target" "rabbitmq" {
  file_system_id  = aws_efs_file_system.rabbitmq.id
  subnet_id       = aws_subnet.public.id
  security_groups = [aws_security_group.efs.id]
}

# EFS Access Point dla RabbitMQ - root permissions aby móc ustawić uprawnienia
resource "aws_efs_access_point" "rabbitmq" {
  file_system_id = aws_efs_file_system.rabbitmq.id

  posix_user {
    gid = 0  # root GID - pozwala root wykonywać operacje
    uid = 0  # root UID - pozwala root wykonywać operacje
  }

  root_directory {
    path = "/"
    creation_info {
      owner_gid   = 999
      owner_uid   = 999
      permissions = "777"  # Pozwól na zapis dla wszystkich - EFS access point zapewnia izolację
    }
  }

  tags = {
    Name = "${var.project_name}-rabbitmq-access-point"
  }
}
