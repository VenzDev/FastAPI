# CloudWatch Log Group
resource "aws_cloudwatch_log_group" "app" {
  name              = "/ecs/${var.project_name}"
  retention_in_days = 7

  tags = {
    Name = "${var.project_name}-logs"
  }
}

# CloudWatch Log Group dla RabbitMQ
resource "aws_cloudwatch_log_group" "rabbitmq" {
  name              = "/ecs/${var.project_name}-rabbitmq"
  retention_in_days = 7

  tags = {
    Name = "${var.project_name}-rabbitmq-logs"
  }
}
