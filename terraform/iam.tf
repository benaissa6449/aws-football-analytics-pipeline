# ========================================
# IAM Roles - Use existing Lab Role
# ========================================

# Get the existing LabRole from the lab environment
data "aws_iam_role" "lab_role" {
  name = "LabRole"
}

# Use the LabRole for both Glue and Firehose
locals {
  service_role_arn = data.aws_iam_role.lab_role.arn
  service_role_id  = data.aws_iam_role.lab_role.id
}

# ========================================
# Additional IAM Policy for Athena
# ========================================

data "aws_iam_policy_document" "athena_policy" {
  statement {
    sid = "AthenaS3Access"
    actions = [
      "s3:GetObject",
      "s3:ListBucket"
    ]
    resources = [
      "arn:aws:s3:::${local.raw_bucket}",
      "arn:aws:s3:::${local.raw_bucket}/*",
      "arn:aws:s3:::${local.processed_bucket}",
      "arn:aws:s3:::${local.processed_bucket}/*",
      "arn:aws:s3:::${local.athena_bucket}",
      "arn:aws:s3:::${local.athena_bucket}/*"
    ]
  }

  statement {
    sid = "AthenaGlueCatalog"
    actions = [
      "glue:GetDatabase",
      "glue:GetTable",
      "glue:GetPartitions"
    ]
    resources = ["*"]
  }
}
