# Data source for availability zones
data "aws_availability_zones" "available" {
  state = "available"
}

# Data source do pobrania account ID
data "aws_caller_identity" "current" {}

# ECR Repository - using existing repository (data source)
data "aws_ecr_repository" "app" {
  name = var.ecr_repository_name
}

# Data source do odczytu wszystkich parametrów z Parameter Store
data "aws_ssm_parameters_by_path" "app_secrets" {
  path      = "/${var.project_name}"
  recursive = true

  depends_on = [
    aws_ssm_parameter.celery_broker_url
  ]
}
