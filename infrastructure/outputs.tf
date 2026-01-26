output "current_region" {
  description = "current AWS region"
  value       = data.aws_region.current.name
}

output "kinesis_stream_name" {
  description = "Kinesis stream name"
  value       = "goals-stream"
}

output "data_stream_arn" {
  description = "data stream arn"
  value       = "arn:aws:kinesis:eu-west-1:${data.aws_caller_identity.current.account_id}:stream/goals-stream"
}

output "s3_bucket_name" {
  description = "S3 bucket name"
  value       = "football-pipeline-data-${data.aws_caller_identity.current.account_id}-eu-west-1"
}

output "s3_bucket_arn" {
  description = "bucket arn"
  value       = "arn:aws:s3:::football-pipeline-data-${data.aws_caller_identity.current.account_id}-eu-west-1"
}
