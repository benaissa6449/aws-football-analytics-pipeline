# Outputs pour les ressources du pipeline football

output "account_id" {
  description = "AWS Account ID"
  value       = local.account_id
}

output "region" {
  description = "AWS Region"
  value       = local.region
}

output "s3_bucket_name" {
  description = "Nom du bucket S3 pour les données"
  value       = local.data_bucket
}

output "s3_bucket_arn" {
  description = "ARN du bucket S3 pour les données"
  value       = "arn:aws:s3:::${local.data_bucket}"
}

output "athena_results_bucket" {
  description = "Bucket pour les résultats Athena"
  value       = "query-results-bucket-football-624409990811"
}

output "glue_database_name" {
  description = "Nom de la base de données Glue"
  value       = "football_db"
}

output "glue_crawler_name" {
  description = "Nom du crawler Glue"
  value       = "football-crawler"
}

output "glue_job_name" {
  description = "Nom du Glue Job ETL"
  value       = aws_glue_job.csv_to_parquet.name
}

output "glue_job_arn" {
  description = "ARN du Glue Job ETL"
  value       = aws_glue_job.csv_to_parquet.arn
}

output "lab_role_arn" {
  description = "ARN du rôle LabRole pour Glue"
  value       = local.lab_role_arn
}

output "athena_workgroup_name" {
  description = "Nom du workgroup Athena"
  value       = "football-workgroup"
}
