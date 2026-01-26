variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "eu-west-1"
}

variable "project_name" {
  description = "Project name"
  type        = string
  default     = "football-pipeline"
}

variable "environment" {
  description = "Environment"
  type        = string
  default     = "dev"
}
