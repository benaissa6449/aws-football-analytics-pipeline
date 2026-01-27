# Athena Configuration - Ressource existante dans AWS

resource "aws_athena_workgroup" "football_workgroup" {
  name        = "football-workgroup"
  state       = "ENABLED"
  description = ""
  
  configuration {
    result_configuration {
      output_location = "s3://query-results-bucket-football-624409990811/"
    }
    enforce_workgroup_configuration    = true
    publish_cloudwatch_metrics_enabled = true
  }
  
  lifecycle {
    ignore_changes = all
  }
}
