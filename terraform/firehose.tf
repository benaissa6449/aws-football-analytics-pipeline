# ========================================
# Kinesis Firehose Delivery Stream
# ========================================

resource "aws_kinesis_firehose_delivery_stream" "goals_firehose" {
  name            = "${local.name_prefix}-${var.firehose_stream_name}"
  destination     = "extended_s3"
  kinesis_source_configuration {
    kinesis_stream_arn = aws_kinesis_stream.goals_stream.arn
    role_arn           = local.service_role_arn
  }

  extended_s3_configuration {
    role_arn           = local.service_role_arn
    bucket_arn         = aws_s3_bucket.raw_data.arn
    prefix             = "goals_raw/year=!{timestamp:yyyy}/month=!{timestamp:MM}/day=!{timestamp:dd}/"
    error_output_prefix = "goals_errors/year=!{timestamp:yyyy}/month=!{timestamp:MM}/day=!{timestamp:dd}/!{firehose:error-output-type}"

    compression_format = "GZIP"

    cloudwatch_logging_options {
      enabled         = true
      log_group_name  = aws_cloudwatch_log_group.firehose_logs.name
      log_stream_name = aws_cloudwatch_log_stream.firehose_stream.name
    }
  }

  depends_on = [
    aws_cloudwatch_log_stream.firehose_stream
  ]

  tags = merge(local.tags, {
    Name = "Goals Firehose Stream"
  })
}

# ========================================
# CloudWatch Logs for Firehose
# ========================================

resource "aws_cloudwatch_log_group" "firehose_logs" {
  name              = "/aws/kinesisfirehose/${local.name_prefix}-goals-firehose"
  retention_in_days = 7

  tags = local.tags

  lifecycle {
    ignore_changes = [tags_all]
  }
}

resource "aws_cloudwatch_log_stream" "firehose_stream" {
  name           = "S3Delivery"
  log_group_name = aws_cloudwatch_log_group.firehose_logs.name
}

# ========================================
# Lambda Function for Firehose Transformation
# ========================================

# ========================================
# Lambda (Optional - commented for now)
# ========================================

# data "aws_iam_policy_document" "lambda_trust_policy" {
#   statement {
#     actions = ["sts:AssumeRole"]
#     principals {
#       type        = "Service"
#       identifiers = ["lambda.amazonaws.com"]
#     }
#   }
# }

# resource "aws_iam_role" "lambda_role" {
#   name              = "${local.name_prefix}-firehose-lambda-role"
#   assume_role_policy = data.aws_iam_policy_document.lambda_trust_policy.json
#
#   tags = local.tags
# }

# resource "aws_iam_role_policy_attachment" "lambda_basic_execution" {
#   role       = aws_iam_role.lambda_role.name
#   policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
# }

# resource "aws_lambda_function" "firehose_transformer" {
#   filename      = "lambda_firehose_transformer.zip"
#   function_name = "${local.name_prefix}-firehose-transformer"
#   role          = aws_iam_role.lambda_role.arn
#   handler       = "index.handler"
#   runtime       = "python3.11"
#   timeout       = 60
#
#   source_code_hash = data.archive_file.lambda_zip.output_base64sha256
#
#   tags = local.tags
# }

# data "archive_file" "lambda_zip" {
#   type        = "zip"
#   source_file = "${path.module}/../scripts/lambda_firehose_transformer.py"
#   output_path = "${path.module}/lambda_firehose_transformer.zip"
# }

# resource "aws_lambda_permission" "firehose_invoke" {
#   statement_id  = "AllowFirehoseInvoke"
#   action        = "lambda:InvokeFunction"
#   function_name = aws_lambda_function.firehose_transformer.function_name
#   principal     = "firehose.amazonaws.com"
#   source_arn    = aws_kinesis_firehose_delivery_stream.goals_firehose.arn
# }
