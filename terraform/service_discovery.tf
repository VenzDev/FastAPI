# Service Discovery Namespace
resource "aws_service_discovery_private_dns_namespace" "main" {
  name        = "${var.project_name}.local"
  description = "Service discovery namespace for ${var.project_name}"
  vpc         = aws_vpc.main.id
}

# Service Discovery Service dla RabbitMQ
resource "aws_service_discovery_service" "rabbitmq" {
  name = "rabbitmq"

  dns_config {
    namespace_id = aws_service_discovery_private_dns_namespace.main.id

    dns_records {
      ttl  = 10
      type = "A"
    }
  }
}
