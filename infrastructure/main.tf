# Terraform Configuration for Football Pipeline
# Kinesis + S3 Infrastructure

terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "5.100.0"
    }
  }
}

provider "aws" {
  region = "eu-west-1"
}

