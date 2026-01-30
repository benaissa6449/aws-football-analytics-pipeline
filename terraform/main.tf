terraform {
  required_version = ">= 1.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Project     = var.project_name
      Environment = var.environment
      ManagedBy   = "Terraform"
    }
  }
}

# Get current AWS account ID
data "aws_caller_identity" "current" {}

# Get available AZs
data "aws_availability_zones" "available" {
  state = "available"
}

# Local variables
locals {
  account_id = data.aws_caller_identity.current.account_id
  region     = var.aws_region
  name_prefix = "${var.project_name}-${var.environment}"
  
  # S3 buckets with unique naming
  raw_bucket      = "${local.name_prefix}-raw-${local.account_id}"
  processed_bucket = "${local.name_prefix}-processed-${local.account_id}"
  scripts_bucket   = "${local.name_prefix}-scripts-${local.account_id}"
  athena_bucket    = "${local.name_prefix}-athena-results-${local.account_id}"
  
  tags = {
    Project     = var.project_name
    Environment = var.environment
  }
}
