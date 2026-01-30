#!/bin/bash
set -e

echo "========================================"
echo "Setting up Kinesis Producer on EC2"
echo "========================================"

# Update system
echo "📦 Installing dependencies..."
apt-get update
apt-get install -y python3 python3-pip git curl

# Install Python packages
pip3 install boto3 pandas pyarrow

# Create producer directory
mkdir -p /opt/kinesis-producer
cd /opt/kinesis-producer

# Create the Kinesis producer script
echo "📝 Creating Kinesis producer script..."
cat > kinesis_producer.py << 'EOF'
#!/usr/bin/env python3
"""
Kinesis Producer for Football Goals - Runs on EC2 Instance
Continuously reads CSV and sends goal events to Kinesis stream
"""

import boto3
import json
import time
import logging
import pandas as pd
from datetime import datetime

# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(levelname)s - %(message)s',
    handlers=[
        logging.FileHandler('/var/log/kinesis-producer.log'),
        logging.StreamHandler()
    ]
)
logger = logging.getLogger(__name__)

# AWS clients
kinesis_client = boto3.client('kinesis', region_name='us-east-1')
s3_client = boto3.client('s3', region_name='us-east-1')

# Configuration
KINESIS_STREAM = 'football-pipeline-dev-goals-stream'
S3_BUCKET = 'football-pipeline-dev-raw-249399230817'
S3_CSV_KEY = 'matches/football_matches_2024_2025.csv'
BATCH_SIZE = 10  # Send goals in batches
BATCH_DELAY = 5  # Delay between batches (seconds)

def download_csv_from_s3():
    """Download CSV file from S3"""
    try:
        logger.info(f"Downloading CSV from s3://{S3_BUCKET}/{S3_CSV_KEY}")
        response = s3_client.get_object(Bucket=S3_BUCKET, Key=S3_CSV_KEY)
        df = pd.read_csv(response['Body'])
        logger.info(f"Downloaded {len(df)} matches")
        return df
    except Exception as e:
        logger.error(f"Failed to download CSV: {e}")
        raise

def extract_goals(df):
    """Extract goal events from matches DataFrame"""
    goals = []
    
    for idx, row in df.iterrows():
        match_id = int(row['match_id'])
        date_utc = row['date_utc']
        home_goals = int(row['goals_home'])
        away_goals = int(row['goals_away'])
        home_team = row['name_home']
        away_team = row['name_away']
        match_status = row['status']
        
        # Generate goal events for home team
        for goal_num in range(1, home_goals + 1):
            goals.append({
                'match_id': match_id,
                'date_utc': date_utc,
                'team': home_team,
                'is_home': True,
                'goal_number': goal_num,
                'total_goals_team': home_goals,
                'opponent': away_team,
                'match_status': match_status,
                'timestamp': datetime.now().isoformat()
            })
        
        # Generate goal events for away team
        for goal_num in range(1, away_goals + 1):
            goals.append({
                'match_id': match_id,
                'date_utc': date_utc,
                'team': away_team,
                'is_home': False,
                'goal_number': goal_num,
                'total_goals_team': away_goals,
                'opponent': home_team,
                'match_status': match_status,
                'timestamp': datetime.now().isoformat()
            })
    
    return goals

def send_to_kinesis(goals):
    """Send goal events to Kinesis stream"""
    total_sent = 0
    failed = 0
    
    try:
        for i in range(0, len(goals), BATCH_SIZE):
            batch = goals[i:i+BATCH_SIZE]
            
            # Prepare records for batch write
            records = []
            for goal in batch:
                records.append({
                    'Data': json.dumps(goal),
                    'PartitionKey': str(goal['match_id'])
                })
            
            # Send batch to Kinesis
            try:
                response = kinesis_client.put_records(
                    StreamName=KINESIS_STREAM,
                    Records=records
                )
                
                successful = len(records) - response['FailedRecordCount']
                total_sent += successful
                failed += response['FailedRecordCount']
                
                logger.info(f"Sent {successful}/{len(records)} goals to Kinesis "
                           f"(batch {i//BATCH_SIZE + 1})")
                
                if response['FailedRecordCount'] > 0:
                    logger.warning(f"Failed to send {response['FailedRecordCount']} records")
                
                # Wait before next batch
                time.sleep(BATCH_DELAY)
                
            except Exception as e:
                logger.error(f"Error sending batch to Kinesis: {e}")
                failed += len(records)
        
        logger.info(f"✅ Producer complete: {total_sent} goals sent, {failed} failed")
        return total_sent, failed
        
    except Exception as e:
        logger.error(f"Fatal error during Kinesis send: {e}")
        raise

def main():
    """Main producer loop"""
    logger.info("=" * 60)
    logger.info("🚀 Starting Kinesis Football Goals Producer")
    logger.info(f"Stream: {KINESIS_STREAM}")
    logger.info(f"Bucket: s3://{S3_BUCKET}")
    logger.info("=" * 60)
    
    try:
        # Download CSV
        df = download_csv_from_s3()
        logger.info(f"Loaded {len(df)} matches")
        
        # Extract goals
        goals = extract_goals(df)
        logger.info(f"Extracted {len(goals)} goal events")
        
        # Send to Kinesis
        sent, failed = send_to_kinesis(goals)
        
        logger.info("=" * 60)
        logger.info(f"Producer finished: {sent} goals delivered")
        logger.info("=" * 60)
        
    except Exception as e:
        logger.error(f"❌ Producer failed: {e}")
        raise

if __name__ == '__main__':
    main()
EOF

chmod +x kinesis_producer.py

# Create systemd service
echo "🔧 Creating systemd service..."
cat > /etc/systemd/system/kinesis-producer.service << 'SERVICE'
[Unit]
Description=Kinesis Football Goals Producer
After=network.target

[Service]
Type=simple
User=ubuntu
WorkingDirectory=/opt/kinesis-producer
ExecStart=/usr/bin/python3 /opt/kinesis-producer/kinesis_producer.py
Restart=on-failure
RestartSec=10
StandardOutput=journal
StandardError=journal

[Install]
WantedBy=multi-user.target
SERVICE

# Enable and start service
echo "🚀 Starting Kinesis producer service..."
systemctl daemon-reload
systemctl enable kinesis-producer
systemctl start kinesis-producer

# Verify service is running
sleep 2
systemctl status kinesis-producer

echo "========================================"
echo "✅ Kinesis Producer Setup Complete!"
echo "========================================"
echo "Service: kinesis-producer"
echo "Logs: /var/log/kinesis-producer.log"
echo "Status: systemctl status kinesis-producer"
echo "========================================"
