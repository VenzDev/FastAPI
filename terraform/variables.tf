variable "aws_region" {
  description = "AWS region for resources"
  type        = string
  default     = "eu-west-1"
}

variable "project_name" {
  description = "Name of the project (used for resource naming)"
  type        = string
  default     = "fastapi-app"
}

variable "ecr_repository_name" {
  description = "Name of the existing ECR repository to use"
  type        = string
  default     = "fastapi-app"
}
