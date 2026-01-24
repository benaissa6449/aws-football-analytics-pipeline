variable "aws_region" {
  description = "AWS Region"
  type        = string
  default     = "us-east-1"
}

variable "project_name" {
  description = "Project name prefix"
  type        = string
  default     = "football-pipeline"
}

variable "bucket_prefix" {
  description = "Unique prefix for S3 buckets"
  type        = string
  default     = "episen-football"  # Changez avec vos initiales
}
