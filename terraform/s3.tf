# S3 Buckets - Ressources existantes (gérées manuellement dans AWS)
# Les buckets suivants existent et sont utilisés par le pipeline

resource "aws_s3_bucket" "raw_data" {
  bucket = "episen-football-raw-data"
  lifecycle {
    ignore_changes = all
  }
}

resource "aws_s3_bucket" "processed_data" {
  bucket = "episen-football-processed-data"
  lifecycle {
    ignore_changes = all
  }
}

resource "aws_s3_bucket" "scripts" {
  bucket = "episen-football-scripts"
  lifecycle {
    ignore_changes = all
  }
}

resource "aws_s3_bucket" "foot_data_bucket" {
  bucket = "foot-data-bucket-624409990811"
  lifecycle {
    ignore_changes = all
  }
}

resource "aws_s3_bucket" "data_bucket" {
  bucket = "football-pipeline-data-624409990811-us-east-1"
  lifecycle {
    ignore_changes = all
  }
}

resource "aws_s3_bucket" "athena_results" {
  bucket = "query-results-bucket-football-624409990811"
  lifecycle {
    ignore_changes = all
  }
}

resource "aws_s3_bucket_versioning" "athena_results" {
  bucket = aws_s3_bucket.athena_results.id
  versioning_configuration {
    status = "Enabled"
  }
  lifecycle {
    ignore_changes = all
  }
}
