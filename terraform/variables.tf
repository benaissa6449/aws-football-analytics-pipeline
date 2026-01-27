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
  default     = "episen-football"
}

variable "environment" {
  description = "Environnement de déploiement"
  type        = string
  default     = "dev"
}

variable "glue_database_name" {
  description = "Nom de la base de données Glue"
  type        = string
  default     = "football_db"
}

variable "glue_crawler_name" {
  description = "Nom du crawler Glue"
  type        = string
  default     = "football-crawler"
}

variable "athena_workgroup_name" {
  description = "Nom du workgroup Athena"
  type        = string
  default     = "football-workgroup"
}
