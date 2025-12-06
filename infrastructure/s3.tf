# Buckets S3

# Bucket principal pour les données
resource "aws_s3_bucket" "data" {
  bucket = "${var.bucket_prefix}-data-${data.aws_caller_identity.current.account_id}"

  tags = {
    Name = "${var.project_name}-data-bucket"
  }
}

# Versioning pour le bucket principal
resource "aws_s3_bucket_versioning" "data" {
  bucket = aws_s3_bucket.data.id
  versioning_configuration {
    status = "Enabled"
  }
}

# Encryption pour le bucket principal
resource "aws_s3_bucket_server_side_encryption_configuration" "data" {
  bucket = aws_s3_bucket.data.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# Bucket pour les résultats des requêtes Athena
resource "aws_s3_bucket" "query_results" {
  bucket = "${var.bucket_prefix}-query-results-${data.aws_caller_identity.current.account_id}"

  tags = {
    Name = "${var.project_name}-query-results-bucket"
  }
}

# Versioning pour le bucket query results
resource "aws_s3_bucket_versioning" "query_results" {
  bucket = aws_s3_bucket.query_results.id
  versioning_configuration {
    status = "Enabled"
  }
}

# Encryption pour le bucket query results
resource "aws_s3_bucket_server_side_encryption_configuration" "query_results" {
  bucket = aws_s3_bucket.query_results.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# Data source pour obtenir l'ID du compte
data "aws_caller_identity" "current" {}

# Lifecycle policy pour archiver les anciens objets
resource "aws_s3_bucket_lifecycle_configuration" "data" {
  bucket = aws_s3_bucket.data.id

  rule {
    id     = "archive-old-data"
    status = "Enabled"

    transition {
      days          = 90
      storage_class = "GLACIER"
    }

    expiration {
      days = 365
    }
  }
}

# Output des noms de buckets
output "data_bucket_name" {
  value       = aws_s3_bucket.data.id
  description = "Nom du bucket S3 principal"
}

output "query_results_bucket_name" {
  value       = aws_s3_bucket.query_results.id
  description = "Nom du bucket pour les résultats Athena"
}
