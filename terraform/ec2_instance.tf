# EC2 Instance with Kinesis producer capability
# Using hardcoded AMI to avoid ec2:DescribeImages call

resource "aws_security_group" "kinesis_producer_sg" {
  name        = "football-pipeline-kinesis-producer-sg"
  description = "Security group for Kinesis producer EC2 instance"

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "football-pipeline-kinesis-producer-sg"
  }
}

resource "aws_instance" "kinesis_producer" {
  # Ubuntu 22.04 LTS AMI for us-east-1
  ami           = "ami-0c02fb55956c7d316"
  instance_type = "t2.micro"
  
  iam_instance_profile = aws_iam_instance_profile.kinesis_producer_profile.name
  security_groups      = [aws_security_group.kinesis_producer_sg.name]

  user_data = base64encode(<<-EOF
              #!/bin/bash
              set -e
              
              # Update system
              apt-get update
              apt-get install -y python3 python3-pip git
              
              # Install Python dependencies
              pip3 install boto3 pandas pyarrow
              
              # Create producer directory
              mkdir -p /opt/kinesis-producer
              cd /opt/kinesis-producer
              
              # Download Kinesis producer script
              cat > kinesis_producer.py << 'SCRIPT'
              ${file("${path.module}/../scripts/kinesis_producer_ec2.py")}
              SCRIPT
              
              # Set execute permissions
              chmod +x kinesis_producer.py
              
              # Create systemd service for continuous producer
              cat > /etc/systemd/system/kinesis-producer.service << 'SERVICE'
              [Unit]
              Description=Kinesis Football Goals Producer
              After=network.target
              
              [Service]
              Type=simple
              User=ubuntu
              WorkingDirectory=/opt/kinesis-producer
              ExecStart=/usr/bin/python3 kinesis_producer.py
              Restart=on-failure
              RestartSec=10
              
              [Install]
              WantedBy=multi-user.target
              SERVICE
              
              # Enable and start service
              systemctl daemon-reload
              systemctl enable kinesis-producer
              systemctl start kinesis-producer
              
              # Log startup
              echo "Kinesis producer service started at $(date)" >> /var/log/kinesis-producer.log
              EOF
  )

  tags = {
    Name = "football-pipeline-kinesis-producer"
  }

  depends_on = [
    aws_iam_instance_profile.kinesis_producer_profile,
    aws_security_group.kinesis_producer_sg
  ]
}
