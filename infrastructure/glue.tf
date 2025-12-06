# AWS Glue - Catalog, Jobs, Crawlers

# Glue Database
resource "aws_glue_catalog_database" "football" {
  name = var.glue_database_name

  description = "Database pour les données de football"
}

# Glue Job pour ETL
resource "aws_glue_job" "goals_etl" {
  name              = var.glue_job_name
  role_arn          = aws_iam_role.glue_job_role.arn
  command {
    name            = "glueetl"
    script_location = "s3://${aws_s3_bucket.data.id}/scripts/glue_job_etl.py"
    python_version  = "3"
  }

  default_arguments = {
    "--job-bookmark-option"    = "job-bookmark-enable"
    "--TempDir"               = "s3://${aws_s3_bucket.data.id}/temp/"
    "--enable-spark-ui"       = "true"
    "--spark-event-logs-path" = "s3://${aws_s3_bucket.data.id}/spark-logs/"
  }

  max_retries       = 1
  timeout           = 60
  glue_version      = "4.0"
  worker_type       = "G.2X"
  number_of_workers = 2

  tags = {
    Name = "${var.project_name}-goals-etl-job"
  }

  depends_on = [aws_glue_catalog_database.football]
}

# Glue Crawler
resource "aws_glue_crawler" "football" {
  name              = var.glue_crawler_name
  database_name     = aws_glue_catalog_database.football.name
  role              = aws_iam_role.glue_crawler_role.arn
  schedule          = "cron(0 1 * * ? *)"  # Exécution à 1h du matin chaque jour

  s3_target {
    path = "s3://${aws_s3_bucket.data.id}/matches/"
  }

  s3_target {
    path = "s3://${aws_s3_bucket.data.id}/goals_raw/"
  }

  s3_target {
    path = "s3://${aws_s3_bucket.data.id}/goals_clean/"
  }

  tags = {
    Name = "${var.project_name}-crawler"
  }

  depends_on = [aws_glue_catalog_database.football]
}

# CloudWatch Log Group pour Glue
resource "aws_cloudwatch_log_group" "glue_job" {
  name              = "/aws-glue/${var.project_name}"
  retention_in_days = 7

  tags = {
    Name = "${var.project_name}-glue-logs"
  }
}

# Output
output "glue_database_name" {
  value       = aws_glue_catalog_database.football.name
  description = "Nom de la base de données Glue"
}

output "glue_job_name" {
  value       = aws_glue_job.goals_etl.name
  description = "Nom du job Glue ETL"
}

output "glue_crawler_name" {
  value       = aws_glue_crawler.football.name
  description = "Nom du crawler Glue"
}
