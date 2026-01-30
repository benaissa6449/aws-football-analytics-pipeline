variable "aws_region" {
  description = "AWS region for all resources"
  type        = string
  default     = "us-east-1"
}

variable "project_name" {
  description = "Project name - used for naming resources"
  type        = string
  default     = "football-pipeline"
}

variable "environment" {
  description = "Environment name (dev, staging, prod)"
  type        = string
  default     = "dev"
  
  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "Environment must be dev, staging, or prod."
  }
}

# ========================
# Kinesis Configuration
# ========================

variable "kinesis_stream_name" {
  description = "Kinesis stream name for real-time goals data"
  type        = string
  default     = "goals-stream"
}

variable "kinesis_shard_count" {
  description = "Number of shards for Kinesis stream"
  type        = number
  default     = 1
}

variable "kinesis_retention_period" {
  description = "Retention period in hours for Kinesis stream"
  type        = number
  default     = 24
}

# ========================
# Firehose Configuration
# ========================

variable "firehose_stream_name" {
  description = "Firehose delivery stream name"
  type        = string
  default     = "goals-firehose"
}

variable "firehose_buffer_size_mb" {
  description = "Buffer size in MB for Firehose"
  type        = number
  default     = 5
}

variable "firehose_buffer_interval_sec" {
  description = "Buffer interval in seconds for Firehose"
  type        = number
  default     = 300
}

# ========================
# Glue Configuration
# ========================

variable "glue_database_name" {
  description = "Glue Data Catalog database name"
  type        = string
  default     = "football_db"
}

variable "glue_crawler_name" {
  description = "Glue Crawler name"
  type        = string
  default     = "football-crawler"
}

variable "glue_job_name" {
  description = "Glue Job name for ETL"
  type        = string
  default     = "football-csv-to-parquet"
}

variable "glue_worker_type" {
  description = "Glue Job worker type (G.1X, G.2X, G.025X)"
  type        = string
  default     = "G.2X"
}

variable "glue_num_workers" {
  description = "Number of workers for Glue Job"
  type        = number
  default     = 2
}

variable "glue_job_timeout" {
  description = "Glue Job timeout in minutes"
  type        = number
  default     = 2880
}

# ========================
# Athena Configuration
# ========================

variable "athena_workgroup_name" {
  description = "Athena workgroup name"
  type        = string
  default     = "football-workgroup"
}

variable "athena_query_timeout_minutes" {
  description = "Athena query timeout in minutes"
  type        = number
  default     = 30
}

# ========================
# S3 Configuration
# ========================

variable "s3_enable_versioning" {
  description = "Enable versioning on S3 buckets"
  type        = bool
  default     = true
}

variable "s3_enable_encryption" {
  description = "Enable encryption on S3 buckets"
  type        = bool
  default     = true
}

variable "s3_block_public_access" {
  description = "Block public access to S3 buckets"
  type        = bool
  default     = true
}

# ========================
# Tags
# ========================

variable "additional_tags" {
  description = "Additional tags to apply to all resources"
  type        = map(string)
  default     = {}
}
