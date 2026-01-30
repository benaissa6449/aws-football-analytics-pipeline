# ========================================
# S3 Buckets for Football Pipeline
# ========================================

# Raw data bucket (CSV input)
resource "aws_s3_bucket" "raw_data" {
  bucket = local.raw_bucket
  
  tags = merge(local.tags, {
    Name = "Raw Data Bucket"
  })

  lifecycle {
    ignore_changes = [tags_all]
  }
}

# Processed data bucket (Parquet output)
resource "aws_s3_bucket" "processed_data" {
  bucket = local.processed_bucket
  
  tags = merge(local.tags, {
    Name = "Processed Data Bucket"
  })

  lifecycle {
    ignore_changes = [tags_all]
  }
}

# Scripts bucket (Glue job scripts)
resource "aws_s3_bucket" "scripts" {
  bucket = local.scripts_bucket
  
  tags = merge(local.tags, {
    Name = "Scripts Bucket"
  })

  lifecycle {
    ignore_changes = [tags_all]
  }
}

# Athena query results bucket
resource "aws_s3_bucket" "athena_results" {
  bucket = local.athena_bucket
  
  tags = merge(local.tags, {
    Name = "Athena Results Bucket"
  })

  lifecycle {
    ignore_changes = [tags_all]
  }
}

# ========================================
# S3 Bucket Configuration
# ========================================

# Enable versioning
resource "aws_s3_bucket_versioning" "raw_data" {
  bucket = aws_s3_bucket.raw_data.id

  versioning_configuration {
    status = var.s3_enable_versioning ? "Enabled" : "Suspended"
  }
}

resource "aws_s3_bucket_versioning" "processed_data" {
  bucket = aws_s3_bucket.processed_data.id

  versioning_configuration {
    status = var.s3_enable_versioning ? "Enabled" : "Suspended"
  }
}

resource "aws_s3_bucket_versioning" "athena_results" {
  bucket = aws_s3_bucket.athena_results.id

  versioning_configuration {
    status = var.s3_enable_versioning ? "Enabled" : "Suspended"
  }
}

# Server-side encryption
resource "aws_s3_bucket_server_side_encryption_configuration" "raw_data" {
  bucket = aws_s3_bucket.raw_data.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "processed_data" {
  bucket = aws_s3_bucket.processed_data.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "athena_results" {
  bucket = aws_s3_bucket.athena_results.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# Block public access
resource "aws_s3_bucket_public_access_block" "raw_data" {
  bucket = aws_s3_bucket.raw_data.id

  block_public_acls       = var.s3_block_public_access
  block_public_policy     = var.s3_block_public_access
  ignore_public_acls      = var.s3_block_public_access
  restrict_public_buckets = var.s3_block_public_access
}

resource "aws_s3_bucket_public_access_block" "processed_data" {
  bucket = aws_s3_bucket.processed_data.id

  block_public_acls       = var.s3_block_public_access
  block_public_policy     = var.s3_block_public_access
  ignore_public_acls      = var.s3_block_public_access
  restrict_public_buckets = var.s3_block_public_access
}

resource "aws_s3_bucket_public_access_block" "scripts" {
  bucket = aws_s3_bucket.scripts.id

  block_public_acls       = var.s3_block_public_access
  block_public_policy     = var.s3_block_public_access
  ignore_public_acls      = var.s3_block_public_access
  restrict_public_buckets = var.s3_block_public_access
}

resource "aws_s3_bucket_public_access_block" "athena_results" {
  bucket = aws_s3_bucket.athena_results.id

  block_public_acls       = var.s3_block_public_access
  block_public_policy     = var.s3_block_public_access
  ignore_public_acls      = var.s3_block_public_access
  restrict_public_buckets = var.s3_block_public_access
}

# ========================================
# S3 Bucket Directories (Objects)
# ========================================

# Create directory structures
resource "aws_s3_object" "raw_data_matches_folder" {
  bucket = aws_s3_bucket.raw_data.id
  key    = "matches/"
  content = ""
}

resource "aws_s3_object" "processed_data_parquet_folder" {
  bucket = aws_s3_bucket.processed_data.id
  key    = "parquet/"
  content = ""
}

resource "aws_s3_object" "scripts_folder" {
  bucket = aws_s3_bucket.scripts.id
  key    = "glue/"
  content = ""
}

resource "aws_s3_object" "athena_results_folder" {
  bucket = aws_s3_bucket.athena_results.id
  key    = "results/"
  content = ""
}
