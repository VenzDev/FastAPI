# ECS Cluster
resource "aws_ecs_cluster" "main" {
  name = "${var.project_name}-cluster"

  tags = {
    Name = "${var.project_name}-cluster"
  }
}

# ECS Task Definition dla RabbitMQ
resource "aws_ecs_task_definition" "rabbitmq" {
  family                   = "${var.project_name}-rabbitmq"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = 256
  memory                   = 512
  execution_role_arn       = aws_iam_role.ecs_task_execution.arn
  task_role_arn            = aws_iam_role.ecs_task.arn

  volume {
    name = "rabbitmq-data"

    efs_volume_configuration {
      file_system_id     = aws_efs_file_system.rabbitmq.id
      root_directory     = "/"
      transit_encryption = "ENABLED" 
      authorization_config {
        access_point_id = aws_efs_access_point.rabbitmq.id
        iam             = "ENABLED"
      }
    }
  }

  container_definitions = jsonencode([
    {
      name  = "rabbitmq"
      image = "rabbitmq:3.12-management-alpine"

      portMappings = [
        {
          containerPort = 5672
          protocol      = "tcp"
        },
        {
          containerPort = 15672
          protocol      = "tcp"
        }
      ]

      environment = [
        {
          name  = "RABBITMQ_DEFAULT_USER"
          value = var.rabbitmq_username
        },
        {
          name  = "RABBITMQ_DEFAULT_PASS"
          value = var.rabbitmq_password
        }
      ]

      mountPoints = [
        {
          sourceVolume  = "rabbitmq-data"
          containerPath = "/var/lib/rabbitmq"
          readOnly      = false
        }
      ]

      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = aws_cloudwatch_log_group.rabbitmq.name
          "awslogs-region"        = var.aws_region
          "awslogs-stream-prefix" = "ecs"
        }
      }

      healthCheck = {
        command     = ["CMD-SHELL", "rabbitmq-diagnostics ping"]
        interval    = 30
        timeout     = 5
        retries     = 3
        startPeriod = 60
      }
    }
  ])

  tags = {
    Name = "${var.project_name}-rabbitmq-task"
  }
}

# ECS Service dla RabbitMQ
resource "aws_ecs_service" "rabbitmq" {
  name            = "${var.project_name}-rabbitmq-service"
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.rabbitmq.arn
  desired_count   = 1
  launch_type     = "FARGATE"

  network_configuration {
    subnets          = [aws_subnet.public.id]
    security_groups  = [aws_security_group.rabbitmq.id]
    assign_public_ip = true
  }

  # Service Discovery
  service_registries {
    registry_arn = aws_service_discovery_service.rabbitmq.arn
  }

  depends_on = [
    aws_iam_role_policy_attachment.ecs_task_execution,
    aws_efs_mount_target.rabbitmq,
    aws_efs_access_point.rabbitmq,
    aws_iam_role_policy.ecs_task_execution_efs
  ]

  tags = {
    Name = "${var.project_name}-rabbitmq-service"
  }
}

# ECS Task Definition
resource "aws_ecs_task_definition" "app" {
  family                   = var.project_name
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = 256
  memory                   = 512
  execution_role_arn       = aws_iam_role.ecs_task_execution.arn
  task_role_arn            = aws_iam_role.ecs_task.arn

  container_definitions = jsonencode([
    {
      name  = var.project_name
      image = "${data.aws_ecr_repository.app.repository_url}:latest"

      portMappings = [
        {
          containerPort = 8000
          protocol      = "tcp"
        }
      ]

      environment = local.environment_vars
      secrets = [
        {
          name      = "CELERY_BROKER_URL"
          valueFrom = "arn:aws:ssm:${var.aws_region}:${data.aws_caller_identity.current.account_id}:parameter/${var.project_name}/celery_broker_url"
        }
      ]

      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = aws_cloudwatch_log_group.app.name
          "awslogs-region"        = var.aws_region
          "awslogs-stream-prefix" = "ecs"
        }
      }

      healthCheck = {
        command     = ["CMD-SHELL", "curl -f http://localhost:8000/health || exit 1"]
        interval    = 30
        timeout     = 5
        retries     = 3
        startPeriod = 60
      }
    }
  ])

  tags = {
    Name = "${var.project_name}-task-definition"
  }
}

# ECS Service
resource "aws_ecs_service" "app" {
  name            = "${var.project_name}-service"
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.app.arn
  desired_count   = 1
  launch_type     = "FARGATE"

  network_configuration {
    subnets          = [aws_subnet.public.id]
    security_groups  = [aws_security_group.ecs_tasks.id]
    assign_public_ip = true
  }

  depends_on = [
    aws_iam_role_policy_attachment.ecs_task_execution,
    aws_ecs_service.rabbitmq,
    aws_ssm_parameter.celery_broker_url,
    aws_iam_role_policy.ecs_task_execution_ssm
  ]

  tags = {
    Name = "${var.project_name}-service"
  }
}

# ECS Task Definition dla Celery Worker
resource "aws_ecs_task_definition" "celery_worker" {
  family                   = "${var.project_name}-celery-worker"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = 256
  memory                   = 512
  execution_role_arn       = aws_iam_role.ecs_task_execution.arn
  task_role_arn            = aws_iam_role.ecs_task.arn

  container_definitions = jsonencode([
    {
      name  = "${var.project_name}-celery-worker"
      image = "${data.aws_ecr_repository.app.repository_url}:latest"

      environment = local.environment_vars
      secrets = [
        {
          name      = "CELERY_BROKER_URL"
          valueFrom = "arn:aws:ssm:${var.aws_region}:${data.aws_caller_identity.current.account_id}:parameter/${var.project_name}/celery_broker_url"
        }
      ]

      command = [
        "celery",
        "-A",
        "src.celery_app",
        "worker",
        "--loglevel=info"
      ]

      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = aws_cloudwatch_log_group.celery_worker.name
          "awslogs-region"        = var.aws_region
          "awslogs-stream-prefix" = "ecs"
        }
      }
    }
  ])

  tags = {
    Name = "${var.project_name}-celery-worker-task"
  }
}

# ECS Service dla Celery Worker
resource "aws_ecs_service" "celery_worker" {
  name            = "${var.project_name}-celery-worker-service"
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.celery_worker.arn
  desired_count   = 1
  launch_type     = "FARGATE"

  network_configuration {
    subnets          = [aws_subnet.public.id]
    security_groups  = [aws_security_group.celery_worker.id]
    assign_public_ip = true
  }

  depends_on = [
    aws_iam_role_policy_attachment.ecs_task_execution,
    aws_ecs_service.rabbitmq,
    aws_ssm_parameter.celery_broker_url,
    aws_iam_role_policy.ecs_task_execution_ssm
  ]

  tags = {
    Name = "${var.project_name}-celery-worker-service"
  }
}
