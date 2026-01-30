# ========================================
# Terraform Outputs
# ========================================

# ===== EC2 Instance =====
output "ec2_public_ip" {
  description = "Public IP of Kinesis producer EC2 instance"
  value       = aws_instance.kinesis_producer.public_ip
}

output "ec2_ssh_command" {
  description = "SSH command to connect to EC2 instance"
  value       = "ssh -i ~/mykey.pem ubuntu@${aws_instance.kinesis_producer.public_ip}"
}

output "kinesis_producer_start_command" {
  description = "Command to start Kinesis producer on EC2"
  value       = "python3 /opt/kinesis-producer/kinesis_producer.py"
}

# ===== AWS Account Info =====
output "account_id" {
  description = "AWS Account ID"
  value       = local.account_id
}

output "region" {
  description = "AWS Region"
  value       = local.region
}

# ===== S3 Buckets =====
output "raw_data_bucket" {
  description = "S3 bucket for raw data (CSV input)"
  value       = aws_s3_bucket.raw_data.id
}

output "processed_data_bucket" {
  description = "S3 bucket for processed data (Parquet output)"
  value       = aws_s3_bucket.processed_data.id
}

output "scripts_bucket" {
  description = "S3 bucket for Glue job scripts"
  value       = aws_s3_bucket.scripts.id
}

output "athena_results_bucket" {
  description = "S3 bucket for Athena query results"
  value       = aws_s3_bucket.athena_results.id
}

output "s3_buckets_summary" {
  description = "Summary of all S3 buckets"
  value = {
    raw_data       = aws_s3_bucket.raw_data.id
    processed_data = aws_s3_bucket.processed_data.id
    scripts        = aws_s3_bucket.scripts.id
    athena_results = aws_s3_bucket.athena_results.id
  }
}

# ===== Kinesis =====
output "kinesis_stream_name" {
  description = "Kinesis stream name for real-time goals data"
  value       = aws_kinesis_stream.goals_stream.name
}

output "kinesis_stream_arn" {
  description = "Kinesis stream ARN"
  value       = aws_kinesis_stream.goals_stream.arn
}

output "kinesis_shard_count" {
  description = "Number of shards in Kinesis stream"
  value       = var.kinesis_shard_count
}

# ===== Firehose =====
output "firehose_delivery_stream_name" {
  description = "Kinesis Firehose delivery stream name"
  value       = aws_kinesis_firehose_delivery_stream.goals_firehose.name
}

output "firehose_delivery_stream_arn" {
  description = "Kinesis Firehose delivery stream ARN"
  value       = aws_kinesis_firehose_delivery_stream.goals_firehose.arn
}

output "lambda_transformer_function_name" {
  description = "Lambda function name for Firehose data transformation (Optional)"
  value       = ""
  # value       = aws_lambda_function.firehose_transformer.function_name
}

output "lambda_transformer_function_arn" {
  description = "Lambda function ARN for Firehose data transformation (Optional)"
  value       = ""
  # value       = aws_lambda_function.firehose_transformer.arn
}

# ===== Glue =====
output "glue_database_name" {
  description = "Glue Data Catalog database name"
  value       = aws_glue_catalog_database.football_db.name
}

output "glue_crawler_name" {
  description = "Glue Crawler name"
  value       = aws_glue_crawler.football_crawler.name
}

output "glue_job_name" {
  description = "Glue ETL Job name"
  value       = aws_glue_job.csv_to_parquet.name
}

output "glue_job_arn" {
  description = "Glue ETL Job ARN"
  value       = aws_glue_job.csv_to_parquet.arn
}

output "glue_trigger_name" {
  description = "Glue trigger name for scheduled ETL"
  value       = aws_glue_trigger.daily_etl.name
}

output "glue_trigger_schedule" {
  description = "Glue trigger schedule expression"
  value       = aws_glue_trigger.daily_etl.schedule
}

output "glue_summary" {
  description = "Summary of Glue resources"
  value = {
    database  = aws_glue_catalog_database.football_db.name
    crawler   = aws_glue_crawler.football_crawler.name
    job       = aws_glue_job.csv_to_parquet.name
    trigger   = aws_glue_trigger.daily_etl.name
  }
}

# ===== Athena =====
output "athena_workgroup_name" {
  description = "Athena workgroup name"
  value       = aws_athena_workgroup.football_workgroup.name
}

output "athena_workgroup_id" {
  description = "Athena workgroup ID"
  value       = aws_athena_workgroup.football_workgroup.id
}

output "athena_results_location" {
  description = "S3 location for Athena query results"
  value       = "s3://${aws_s3_bucket.athena_results.id}/results/"
}

output "athena_named_queries" {
  description = "Athena named queries"
  value = {
    select_matches   = aws_athena_named_query.select_matches.name
    goals_by_season  = aws_athena_named_query.goals_by_season.name
    home_away_goals  = aws_athena_named_query.home_away_goals.name
  }
}

# ===== IAM Roles =====
output "glue_role_arn" {
  description = "IAM role ARN for Glue (using LabRole)"
  value       = local.service_role_arn
}

output "firehose_role_arn" {
  description = "IAM role ARN for Firehose (using LabRole)"
  value       = local.service_role_arn
}

output "lambda_role_arn" {
  description = "IAM role ARN for Lambda (Optional)"
  value       = ""
  # value       = aws_iam_role.lambda_role.arn
}

# ===== Pipeline Summary =====
output "pipeline_summary" {
  description = "Complete pipeline configuration summary"
  value = {
    # Ingestion Layer
    kinesis_stream = {
      name = aws_kinesis_stream.goals_stream.name
      arn  = aws_kinesis_stream.goals_stream.arn
    }
    firehose_stream = {
      name = aws_kinesis_firehose_delivery_stream.goals_firehose.name
      arn  = aws_kinesis_firehose_delivery_stream.goals_firehose.arn
    }

    # Storage Layer
    s3_buckets = {
      raw        = aws_s3_bucket.raw_data.id
      processed  = aws_s3_bucket.processed_data.id
      scripts    = aws_s3_bucket.scripts.id
      athena     = aws_s3_bucket.athena_results.id
    }

    # Processing Layer
    glue_resources = {
      database = aws_glue_catalog_database.football_db.name
      crawler  = aws_glue_crawler.football_crawler.name
      job      = aws_glue_job.csv_to_parquet.name
      trigger  = aws_glue_trigger.daily_etl.name
    }

    # Analytics Layer
    athena_resources = {
      workgroup        = aws_athena_workgroup.football_workgroup.name
      results_location = "s3://${aws_s3_bucket.athena_results.id}/results/"
    }

    # IAM
    iam_roles = {
      glue     = local.service_role_arn
      firehose = local.service_role_arn
      # lambda   = aws_iam_role.lambda_role.arn  # Optional
    }
  }
}

# ===== Connection Strings =====
output "connection_strings" {
  description = "Connection strings for various services"
  value = {
    kinesis_endpoint = "https://kinesis.${local.region}.amazonaws.com"
    s3_endpoint      = "s3://${aws_s3_bucket.raw_data.id}/"
    glue_database    = aws_glue_catalog_database.football_db.name
    athena_output    = "s3://${aws_s3_bucket.athena_results.id}/results/"
  }
}
