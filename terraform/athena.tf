# ========================================
# Athena Workgroup
# ========================================

resource "aws_athena_workgroup" "football_workgroup" {
  name        = "${local.name_prefix}-${var.athena_workgroup_name}"
  description = "Workgroup for football data analysis"
  state       = "ENABLED"

  configuration {
    result_configuration {
      output_location = "s3://${aws_s3_bucket.athena_results.id}/results/"
      encryption_configuration {
        encryption_option = "SSE_S3"
      }
    }

    enforce_workgroup_configuration    = true
    publish_cloudwatch_metrics_enabled = true
    bytes_scanned_cutoff_per_query     = 10737418240
  }

  tags = merge(local.tags, {
    Name = "Football Analysis Workgroup"
  })

  depends_on = [aws_s3_bucket.athena_results]
}

# ========================================
# Athena Named Queries
# ========================================

resource "aws_athena_named_query" "select_matches" {
  name        = "${local.name_prefix}-select-matches"
  workgroup   = aws_athena_workgroup.football_workgroup.id
  description = "Select all football matches with their scores"

  database = aws_glue_catalog_database.football_db.name

  query = <<-SQL
SELECT
  match_id,
  home_team_id,
  away_team_id,
  fulltime_home,
  fulltime_away,
  halftime_home,
  halftime_away,
  date,
  season
FROM ${aws_glue_catalog_database.football_db.name}.parquet
WHERE season IS NOT NULL
ORDER BY date DESC
LIMIT 100
  SQL
}

resource "aws_athena_named_query" "goals_by_season" {
  name        = "${local.name_prefix}-goals-by-season"
  workgroup   = aws_athena_workgroup.football_workgroup.id
  description = "Total goals by season"

  database = aws_glue_catalog_database.football_db.name

  query = <<-SQL
SELECT
  season,
  COUNT(*) as total_matches,
  SUM(fulltime_home + fulltime_away) as total_goals,
  ROUND(CAST(SUM(fulltime_home + fulltime_away) AS DECIMAL) / COUNT(*), 2) as avg_goals_per_match
FROM ${aws_glue_catalog_database.football_db.name}.parquet
WHERE season IS NOT NULL
GROUP BY season
ORDER BY season DESC
  SQL
}

resource "aws_athena_named_query" "home_away_goals" {
  name        = "${local.name_prefix}-home-away-goals"
  workgroup   = aws_athena_workgroup.football_workgroup.id
  description = "Home vs Away goals statistics"

  database = aws_glue_catalog_database.football_db.name

  query = <<-SQL
SELECT
  season,
  'Home' as team_side,
  ROUND(AVG(fulltime_home), 2) as avg_goals,
  ROUND(STDDEV(fulltime_home), 2) as stddev_goals,
  MAX(fulltime_home) as max_goals,
  MIN(fulltime_home) as min_goals
FROM ${aws_glue_catalog_database.football_db.name}.parquet
WHERE season IS NOT NULL
GROUP BY season

UNION ALL

SELECT
  season,
  'Away' as team_side,
  ROUND(AVG(fulltime_away), 2) as avg_goals,
  ROUND(STDDEV(fulltime_away), 2) as stddev_goals,
  MAX(fulltime_away) as max_goals,
  MIN(fulltime_away) as min_goals
FROM ${aws_glue_catalog_database.football_db.name}.parquet
WHERE season IS NOT NULL
GROUP BY season

ORDER BY season DESC, team_side
  SQL
}

# ========================================
# Athena Monitoring
# ========================================

resource "aws_cloudwatch_metric_alarm" "athena_query_failures" {
  alarm_name          = "${local.name_prefix}-athena-query-failures"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = 1
  metric_name         = "EngineExecutionTime"
  namespace           = "AWS/Athena"
  period              = 3600
  statistic           = "Sum"
  threshold           = 1
  alarm_description   = "Alert on Athena query execution issues"
  treat_missing_data  = "notBreaching"
  alarm_actions       = []

  dimensions = {
    WorkGroup = aws_athena_workgroup.football_workgroup.name
  }
}
