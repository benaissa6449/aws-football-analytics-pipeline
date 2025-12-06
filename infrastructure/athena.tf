# Amazon Athena

# Workgroup Athena
resource "aws_athena_workgroup" "football" {
  name = "${var.project_name}-workgroup"

  configuration {
    enforce_workgroup_configuration    = true
    publish_cloudwatch_metrics_enabled = true

    result_configuration {
      output_location = "s3://${aws_s3_bucket.query_results.id}/results/"
    }

    engine_version {
      selected_engine_version = "AUTO"
    }
  }

  tags = {
    Name = "${var.project_name}-workgroup"
  }
}

# Database Athena (pointe vers Glue Catalog)
resource "aws_athena_database" "football" {
  name   = var.glue_database_name
  bucket = aws_s3_bucket.query_results.id

  depends_on = [aws_glue_catalog_database.football]
}

# Output
output "athena_workgroup_name" {
  value       = aws_athena_workgroup.football.name
  description = "Nom du workgroup Athena"
}

output "athena_database_name" {
  value       = aws_athena_database.football.name
  description = "Nom de la base de données Athena"
}
