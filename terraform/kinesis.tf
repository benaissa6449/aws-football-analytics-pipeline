# ========================================
# Kinesis Stream for Real-time Goals Data
# ========================================

resource "aws_kinesis_stream" "goals_stream" {
  name             = "${local.name_prefix}-${var.kinesis_stream_name}"
  retention_period = var.kinesis_retention_period
  shard_count      = var.kinesis_shard_count

  tags = merge(local.tags, {
    Name = "Goals Kinesis Stream"
  })

  lifecycle {
    ignore_changes = [tags_all]
  }
}

# ========================================
# Kinesis Stream Monitoring
# ========================================

resource "aws_cloudwatch_metric_alarm" "kinesis_iterator_age" {
  alarm_name          = "${local.name_prefix}-kinesis-iterator-age"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "GetRecords.IteratorAgeMilliseconds"
  namespace           = "AWS/Kinesis"
  period              = 300
  statistic           = "Maximum"
  threshold           = 60000
  alarm_description   = "Alert when Kinesis iterator age is high"
  alarm_actions       = []

  dimensions = {
    StreamName = aws_kinesis_stream.goals_stream.name
  }
}

resource "aws_cloudwatch_metric_alarm" "kinesis_read_throughput" {
  alarm_name          = "${local.name_prefix}-kinesis-read-throughput"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "ReadProvisionedThroughputExceeded"
  namespace           = "AWS/Kinesis"
  period              = 300
  statistic           = "Sum"
  threshold           = 0
  alarm_description   = "Alert when read throughput is exceeded"
  alarm_actions       = []

  dimensions = {
    StreamName = aws_kinesis_stream.goals_stream.name
  }
}
