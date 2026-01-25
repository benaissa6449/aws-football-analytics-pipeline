# Kinesis Streams et Data Firehose

# Kinesis Data Stream pour les buts
resource "aws_kinesis_stream" "goals" {
  name             = var.kinesis_stream_name
  retention_period = 24

  stream_mode_details {
    stream_mode = "ON_DEMAND"
  }

  tags = {
    Name = "${var.project_name}-goals-stream"
  }
}

# Data Firehose pour livrer les données à S3
resource "aws_kinesis_firehose_delivery_stream" "goals" {
  name            = var.firehose_name
  destination     = "extended_s3"
  kinesis_source_configuration {
    kinesis_stream_arn = aws_kinesis_stream.goals.arn
    role_arn           = aws_iam_role.firehose_role.arn
  }

  extended_s3_configuration {
    role_arn           = aws_iam_role.firehose_role.arn
    bucket_arn         = aws_s3_bucket.data.arn
    prefix             = "goals_raw/YYYY/MM/DD/HH/"
    error_output_prefix = "goals_raw_errors/!{firehose:error-output-type}/!{timestamp:yyyy/MM/dd}/"
    compression_format = "GZIP"

    cloudwatch_logging_options {
      enabled         = true
      log_group_name  = aws_cloudwatch_log_group.firehose.name
      log_stream_name = aws_cloudwatch_log_stream.firehose.name
    }

    processing_configuration {
      enabled = false
    }
  }

  tags = {
    Name = "${var.project_name}-goals-firehose"
  }
}

# CloudWatch Logs pour Firehose
resource "aws_cloudwatch_log_group" "firehose" {
  name              = "/aws/firehose/${var.project_name}"
  retention_in_days = 7

  tags = {
    Name = "${var.project_name}-firehose-logs"
  }
}

resource "aws_cloudwatch_log_stream" "firehose" {
  name           = "S3Delivery"
  log_group_name = aws_cloudwatch_log_group.firehose.name
}

# Output
output "kinesis_stream_arn" {
  value       = aws_kinesis_stream.goals.arn
  description = "ARN du Kinesis Stream"
}

output "firehose_arn" {
  value       = aws_kinesis_firehose_delivery_stream.goals.arn
  description = "ARN du Firehose"
}
