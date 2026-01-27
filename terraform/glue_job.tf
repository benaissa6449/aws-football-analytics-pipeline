# Glue Job: Convertir CSV en Parquet
resource "aws_glue_job" "csv_to_parquet" {
  name     = "football-csv-to-parquet"
  role_arn = local.lab_role_arn

  command {
    name            = "glueetl"
    script_location = "s3://${local.data_bucket}/scripts/csv_to_parquet.py"
    python_version  = "3"
  }

  default_arguments = {
    "--job-language"              = "python"
    "--TempDir"                   = "s3://${local.data_bucket}/temp/"
    "--enable-spark-ui"           = "false"
    "--enable-continuous-cloudwatch-log" = "true"
  }

  max_retries       = 0
  timeout           = 2880
  glue_version      = "4.0"
  worker_type       = "G.2X"
  number_of_workers = 2

  tags = {
    Environment = var.environment
    Project     = "football-pipeline"
  }

  lifecycle {
    ignore_changes = all
  }
}

# Uploader le script Python dans S3
resource "aws_s3_object" "glue_script" {
  bucket = local.data_bucket
  key    = "scripts/csv_to_parquet.py"
  
  source = "${path.module}/../src/glue_job_etl.py"
  etag   = filemd5("${path.module}/../src/glue_job_etl.py")

  tags = {
    Environment = var.environment
    Project     = "football-pipeline"
  }

  lifecycle {
    ignore_changes = all
  }
}
