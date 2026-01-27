terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

# Hardcoded values to avoid permission issues
locals {
  account_id = "624409990811"
  region     = "us-east-1"
  data_bucket = "football-pipeline-data-624409990811-us-east-1"
  lab_role_arn = "arn:aws:iam::624409990811:role/LabRole"
}
