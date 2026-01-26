# Data sources : define variables usable in the TF files

# Keeps the current region name in a variable
data "aws_region" "current" {}

# Get current AWS account ID
data "aws_caller_identity" "current" {}
