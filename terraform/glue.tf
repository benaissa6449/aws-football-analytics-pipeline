# Glue Database
resource "aws_glue_catalog_database" "football_db" {
  name = "football_db"
  
  description = "Database pour les donnees football Premier League"
  
  tags = {
    Name    = "Football Database"
    Project = var.project_name
  }
}

# Glue Crawler pour CSV
resource "aws_glue_crawler" "csv_crawler" {
  database_name = aws_glue_catalog_database.football_db.name
  name          = "${var.project_name}-csv-crawler"
  role          = data.aws_iam_role.lab_role.arn

  s3_target {
    path = "s3://${aws_s3_bucket.raw_data.bucket}/matches/"
  }

  schema_change_policy {
    delete_behavior = "LOG"
    update_behavior = "UPDATE_IN_DATABASE"
  }

  tags = {
    Name    = "CSV Crawler"
    Project = var.project_name
  }
}

# Glue Crawler pour Parquet
resource "aws_glue_crawler" "parquet_crawler" {
  database_name = aws_glue_catalog_database.football_db.name
  name          = "${var.project_name}-parquet-crawler"
  role          = data.aws_iam_role.lab_role.arn

  s3_target {
    path = "s3://${aws_s3_bucket.processed_data.bucket}/matches/"
  }

  schema_change_policy {
    delete_behavior = "LOG"
    update_behavior = "UPDATE_IN_DATABASE"
  }

  tags = {
    Name    = "Parquet Crawler"
    Project = var.project_name
  }
}

# Glue ETL Job
resource "aws_glue_job" "csv_to_parquet" {
  name     = "${var.project_name}-csv-to-parquet"
  role_arn = data.aws_iam_role.lab_role.arn

  command {
    name            = "glueetl"
    script_location = "s3://${aws_s3_bucket.scripts.bucket}/csv_to_parquet.py"
    python_version  = "3"
  }

  default_arguments = {
    "--job-language"           = "python"
    "--enable-metrics"         = "true"
    "--enable-spark-ui"        = "true"
    "--spark-event-logs-path"  = "s3://${aws_s3_bucket.scripts.bucket}/spark-logs/"
    "--TempDir"                = "s3://${aws_s3_bucket.scripts.bucket}/temp/"
  }

  glue_version      = "4.0"
  max_retries       = 0
  timeout           = 10
  number_of_workers = 2
  worker_type       = "G.1X"

  tags = {
    Name    = "CSV to Parquet ETL"
    Project = var.project_name
  }
}
