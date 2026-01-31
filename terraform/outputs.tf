output "ecr_repository_url" {
  description = "URL of the ECR repository"
  value       = data.aws_ecr_repository.app.repository_url
}

output "ecs_cluster_name" {
  description = "Name of the ECS cluster"
  value       = aws_ecs_cluster.main.name
}

output "ecs_service_name" {
  description = "Name of the ECS service"
  value       = aws_ecs_service.app.name
}

output "ecs_rabbitmq_service_name" {
  description = "Name of the RabbitMQ ECS service"
  value       = aws_ecs_service.rabbitmq.name
}

output "cloudwatch_log_group" {
  description = "CloudWatch log group name"
  value       = aws_cloudwatch_log_group.app.name
}

output "cloudwatch_log_group_rabbitmq" {
  description = "CloudWatch log group name for RabbitMQ"
  value       = aws_cloudwatch_log_group.rabbitmq.name
}

output "service_discovery_namespace" {
  description = "Service Discovery namespace"
  value       = aws_service_discovery_private_dns_namespace.main.name
}

output "celery_broker_url_parameter" {
  description = "Parameter Store path for Celery broker URL"
  value       = aws_ssm_parameter.celery_broker_url.name
  sensitive   = true
}