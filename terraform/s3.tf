# Bucket pour données brutes (CSV)
resource "aws_s3_bucket" "raw_data" {
  bucket = "${var.bucket_prefix}-raw-data"
  
  tags = {
    Name        = "Football Raw Data"
    Environment = "Dev"
    Project     = var.project_name
  }
}

# Bucket pour données transformées (Parquet)
resource "aws_s3_bucket" "processed_data" {
  bucket = "${var.bucket_prefix}-processed-data"
  
  tags = {
    Name        = "Football Processed Data"
    Environment = "Dev"
    Project     = var.project_name
  }
}

# Bucket pour scripts ETL
resource "aws_s3_bucket" "scripts" {
  bucket = "${var.bucket_prefix}-scripts"
  
  tags = {
    Name        = "Football ETL Scripts"
    Environment = "Dev"
    Project     = var.project_name
  }
}

# Bucket pour résultats Athena
resource "aws_s3_bucket" "athena_results" {
  bucket = "${var.bucket_prefix}-athena-results"
  
  tags = {
    Name        = "Athena Query Results"
    Environment = "Dev"
    Project     = var.project_name
  }
}
