# IAM Role for EC2 Kinesis Producer
# This role has permissions to write to Kinesis stream

resource "aws_iam_role" "kinesis_producer_role" {
  name = "football-pipeline-kinesis-producer-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })

  tags = {
    Name = "football-pipeline-kinesis-producer-role"
  }
}

resource "aws_iam_role_policy" "kinesis_producer_policy" {
  name = "football-pipeline-kinesis-producer-policy"
  role = aws_iam_role.kinesis_producer_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "kinesis:PutRecord",
          "kinesis:PutRecords",
          "kinesis:DescribeStream",
          "kinesis:GetShardIterator",
          "kinesis:GetRecords"
        ]
        Resource = "arn:aws:kinesis:us-east-1:249399230817:stream/football-pipeline-dev-goals-stream"
      }
    ]
  })
}

resource "aws_iam_instance_profile" "kinesis_producer_profile" {
  name = "football-pipeline-kinesis-producer-profile"
  role = aws_iam_role.kinesis_producer_role.name
}
