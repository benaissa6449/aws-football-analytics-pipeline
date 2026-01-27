# Glue Resources - Ressources existantes dans AWS

resource "aws_glue_catalog_database" "football_db" {
  name        = "football_db"
  description = "Database pour les données de football"
  lifecycle {
    ignore_changes = all
  }
}

resource "aws_glue_crawler" "football_crawler" {
  database_name = "football_db"
  name          = "football-crawler"
  role          = local.lab_role_arn
  
  s3_target {
    path = "s3://football-pipeline-data-624409990811-us-east-1/matches/"
  }
  
  lifecycle {
    ignore_changes = all
  }
}

