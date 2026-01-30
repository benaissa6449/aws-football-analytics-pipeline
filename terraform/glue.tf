# ========================================
# Glue Data Catalog Database
# ========================================

resource "aws_glue_catalog_database" "football_db" {
  name        = var.glue_database_name
  description = "Database for football data pipeline"

  tags = local.tags

  lifecycle {
    ignore_changes = [tags_all]
  }
}

# ========================================
# Glue Crawler
# ========================================

resource "aws_glue_crawler" "football_crawler" {
  database_name = aws_glue_catalog_database.football_db.name
  name          = "${local.name_prefix}-${var.glue_crawler_name}"
  role          = local.service_role_arn
  
  description = "Crawler to catalog football data in Parquet format"

  s3_target {
    path = "s3://${aws_s3_bucket.processed_data.id}/parquet/"
  }

  configuration = jsonencode({
    Version = 1.0
    CrawlerOutput = {
      Partitions = { AddOrUpdateBehavior = "InheritFromTable" }
      Tables     = { AddOrUpdateBehavior = "MergeNewColumns" }
    }
  })

  schedule = "cron(0 2 * * ? *)"
  
  tags = local.tags
}

# ========================================
# Glue ETL Job
# ========================================

resource "aws_glue_job" "csv_to_parquet" {
  name              = "${local.name_prefix}-${var.glue_job_name}"
  role_arn          = local.service_role_arn
  glue_version      = "4.0"
  worker_type       = var.glue_worker_type
  number_of_workers = var.glue_num_workers
  timeout           = var.glue_job_timeout
  max_retries       = 1

  command {
    name            = "glueetl"
    script_location = "s3://${aws_s3_bucket.scripts.id}/glue/${var.glue_job_name}.py"
    python_version  = "3"
  }

  default_arguments = {
    "--job-language"                      = "python"
    "--TempDir"                           = "s3://${aws_s3_bucket.scripts.id}/temp/"
    "--enable-spark-ui"                   = "true"
    "--spark-event-logs-path"             = "s3://${aws_s3_bucket.scripts.id}/spark-logs/"
    "--enable-continuous-cloudwatch-log"  = "true"
    "--log-path"                          = "s3://${aws_s3_bucket.scripts.id}/logs/"
    "--enable-glue-datacatalog"           = "true"
    
    # Custom arguments for the job
    "--S3_INPUT_PATH"                     = "s3://${aws_s3_bucket.raw_data.id}/matches/"
    "--S3_OUTPUT_PATH"                    = "s3://${aws_s3_bucket.processed_data.id}/parquet/"
    "--DATABASE_NAME"                     = aws_glue_catalog_database.football_db.name
  }

  execution_property {
    max_concurrent_runs = 1
  }

  tags = local.tags

  depends_on = [
    aws_s3_object.glue_script
  ]
}

# ========================================
# Upload Glue Job Script
# ========================================

resource "aws_s3_object" "glue_script" {
  bucket = aws_s3_bucket.scripts.id
  key    = "glue/${var.glue_job_name}.py"
  source = "${path.module}/../src/glue_job_etl.py"
  
  etag = filemd5("${path.module}/../src/glue_job_etl.py")

  tags = local.tags

  depends_on = [aws_s3_bucket.scripts]
}

# ========================================
# Glue Job Run Trigger (Optional)
# ========================================

resource "aws_glue_trigger" "daily_etl" {
  name          = "${local.name_prefix}-daily-etl-trigger"
  schedule      = "cron(0 3 * * ? *)"
  type          = "SCHEDULED"
  start_on_creation = true

  actions {
    job_name = aws_glue_job.csv_to_parquet.name
    
    arguments = {
      "--S3_INPUT_PATH"  = "s3://${aws_s3_bucket.raw_data.id}/matches/"
      "--S3_OUTPUT_PATH" = "s3://${aws_s3_bucket.processed_data.id}/parquet/"
    }
  }

  tags = local.tags
}

# ========================================
# Glue Job Monitoring
# ========================================

resource "aws_cloudwatch_metric_alarm" "glue_job_failures" {
  alarm_name          = "${local.name_prefix}-glue-job-failures"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = 1
  metric_name         = "glue.driver.aggregate.numFailedTasks"
  namespace           = "Glue"
  period              = 300
  statistic           = "Sum"
  threshold           = 1
  alarm_description   = "Alert when Glue job has failed tasks"
  alarm_actions       = []

  dimensions = {
    JobName = aws_glue_job.csv_to_parquet.name
  }
}

