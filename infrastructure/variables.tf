# Variables Terraform pour le pipeline football

variable "aws_region" {
  description = "Région AWS"
  type        = string
  default     = "eu-west-1"
}

variable "environment" {
  description = "Environnement (dev, staging, production)"
  type        = string
  default     = "production"
}

variable "project_name" {
  description = "Nom du projet"
  type        = string
  default     = "football-pipeline"
}

variable "bucket_prefix" {
  description = "Préfixe pour les buckets S3"
  type        = string
  default     = "foot-data"
}

variable "glue_job_name" {
  description = "Nom du job Glue ETL"
  type        = string
  default     = "goals-etl"
}

variable "kinesis_stream_name" {
  description = "Nom du stream Kinesis"
  type        = string
  default     = "goals-stream"
}

variable "firehose_name" {
  description = "Nom de Firehose"
  type        = string
  default     = "goals-firehose"
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

variable "tags" {
  description = "Tags communs"
  type        = map(string)
  default = {
    Project     = "Football Pipeline"
    Environment = "Production"
    CreatedBy   = "Terraform"
  }
}
