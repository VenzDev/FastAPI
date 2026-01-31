# Utwórz URL RabbitMQ i zapisz w Parameter Store
resource "aws_ssm_parameter" "celery_broker_url" {
  name  = "/${var.project_name}/celery_broker_url"
  type  = "SecureString"
  value = "amqp://${var.rabbitmq_username}:${var.rabbitmq_password}@rabbitmq.${aws_service_discovery_private_dns_namespace.main.name}:5672//"

  lifecycle {
    create_before_destroy = true
  }

  tags = {
    Name      = "${var.project_name}-celery-broker-url"
    ManagedBy = "Terraform"
    Service   = "RabbitMQ"
  }
}

# Lokalne zmienne do mapowania parametrów
locals {
  # Automatyczne mapowanie parametrów na secrets dla ECS
  ssm_secrets = [
    for param_path in data.aws_ssm_parameters_by_path.app_secrets.names : {
      name = upper(
        replace(
          replace(param_path, "/${var.project_name}/", ""),
          "/",
          "_"
        )
      )
      valueFrom = "arn:aws:ssm:${var.aws_region}:${data.aws_caller_identity.current.account_id}:parameter${param_path}"
    }
  ]

  # Zwykłe zmienne środowiskowe (nie-secrets)
  environment_vars = [
    {
      name  = "ENVIRONMENT"
      value = "production"
    },
    {
      name  = "APP_NAME"
      value = var.project_name
    }
  ]
}
