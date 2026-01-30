#!/bin/bash
# User data script to install Kinesis producer on EC2

set -e

# Update system
apt-get update
apt-get install -y python3 python3-pip git

# Install AWS SDK for Python
pip3 install boto3

# Create directory for the producer script
mkdir -p /opt/kinesis-producer
cd /opt/kinesis-producer

# Create the Python script
cat > /opt/kinesis-producer/kinesis_producer.py << 'PYTHONEOF'
#!/usr/bin/env python3
"""
Kinesis Goals Producer - Runs on EC2 instance
Simulates football goals and sends to Kinesis Stream
"""

import boto3
import json
import time
import csv
import random
from datetime import datetime
import os

KINESIS_STREAM_NAME = os.environ.get('KINESIS_STREAM_NAME', 'football-pipeline-dev-goals-stream')
REGION = os.environ.get('REGION', 'us-east-1')

kinesis = boto3.client('kinesis', region_name=REGION)

def test_kinesis_connection():
    """Test Kinesis connectivity"""
    try:
        response = kinesis.describe_stream(StreamName=KINESIS_STREAM_NAME)
        print(f"[OK] Connected to Kinesis stream: {KINESIS_STREAM_NAME}")
        return True
    except Exception as e:
        print(f"[ERROR] Cannot connect to Kinesis: {str(e)}")
        return False

def read_matches_csv(csv_path):
    """Read matches from CSV"""
    matches = []
    try:
        with open(csv_path, 'r', encoding='utf-8') as f:
            reader = csv.DictReader(f)
            for row in reader:
                matches.append(row)
        print(f"[OK] Loaded {len(matches)} matches from CSV")
        return matches
    except Exception as e:
        print(f"[ERROR] Error reading CSV: {str(e)}")
        return []

def simulate_goals_for_match(match):
    """Simulate goals for a match"""
    home_goals = int(match.get('fulltime_home', 0))
    away_goals = int(match.get('fulltime_away', 0))
    total_goals = home_goals + away_goals
    
    if total_goals == 0:
        return []
    
    goal_minutes = sorted(random.sample(range(1, 91), total_goals))
    goals = []
    home_goal_count = 0
    
    for minute in goal_minutes:
        if home_goal_count < home_goals and random.random() < 0.5:
            team_id = match.get('home_team_id')
            team_name = match.get('home_team')
            home_goal_count += 1
        else:
            team_id = match.get('away_team_id')
            team_name = match.get('away_team')
        
        goal = {
            'match_id': int(match.get('match_id', 0)),
            'minute': minute,
            'scorer_team_id': int(team_id),
            'scorer_team': team_name,
            'home_team': match.get('home_team'),
            'away_team': match.get('away_team'),
            'timestamp': datetime.utcnow().isoformat() + 'Z'
        }
        goals.append(goal)
    
    return goals

def send_to_kinesis(goal_event, delay=0.5):
    """Send goal to Kinesis"""
    try:
        partition_key = str(goal_event['match_id'])
        kinesis.put_record(
            StreamName=KINESIS_STREAM_NAME,
            Data=json.dumps(goal_event),
            PartitionKey=partition_key
        )
        
        print(f"[GOAL] {goal_event['scorer_team']} @ {goal_event['minute']:2d}' | "
              f"{goal_event['home_team']} vs {goal_event['away_team']}")
        time.sleep(delay)
        
    except Exception as e:
        print(f"[ERROR] Error sending to Kinesis: {str(e)}")

def main():
    print("=" * 80)
    print("KINESIS GOALS PRODUCER - Running on EC2")
    print("=" * 80)
    
    if not test_kinesis_connection():
        return
    
    # Try to read from S3 or local copy
    csv_paths = [
        '/opt/kinesis-producer/football_matches_2024_2025.csv',
        '/tmp/football_matches_2024_2025.csv'
    ]
    
    matches = None
    for csv_path in csv_paths:
        if os.path.exists(csv_path):
            matches = read_matches_csv(csv_path)
            break
    
    if not matches:
        print("[ERROR] No CSV file found")
        return
    
    total_goals = 0
    print(f"\nProcessing {len(matches)} matches...\n")
    
    try:
        for idx, match in enumerate(matches, 1):
            goals = simulate_goals_for_match(match)
            
            if goals:
                print(f"Match {idx}/{len(matches)}: {match['home_team']} "
                      f"{match['fulltime_home']}-{match['fulltime_away']} {match['away_team']}")
                
                for goal in goals:
                    send_to_kinesis(goal, delay=0.5)
                    total_goals += 1
                
                print()
    
    except KeyboardInterrupt:
        print("\n[INTERRUPTED] Producer stopped by user")
    
    print("=" * 80)
    print(f"[OK] Total goals sent: {total_goals}")
    print("=" * 80)

if __name__ == "__main__":
    main()
PYTHONEOF

chmod +x /opt/kinesis-producer/kinesis_producer.py

# Download CSV from S3 if available
aws s3 cp s3://${KINESIS_STREAM_NAME%-*}-raw-$(aws sts get-caller-identity --query Account --output text)/football_matches_2024_2025.csv /opt/kinesis-producer/ 2>/dev/null || echo "CSV not found in S3 (expected if not yet uploaded)"

# Create systemd service (optional, for auto-start)
cat > /etc/systemd/system/kinesis-producer.service << 'SERVICEOF'
[Unit]
Description=Kinesis Goals Producer
After=network.target

[Service]
Type=simple
User=root
WorkingDirectory=/opt/kinesis-producer
Environment="KINESIS_STREAM_NAME=${KINESIS_STREAM_NAME}"
Environment="REGION=${REGION}"
ExecStart=/usr/bin/python3 /opt/kinesis-producer/kinesis_producer.py
Restart=on-failure

[Install]
WantedBy=multi-user.target
SERVICEOF

systemctl daemon-reload

echo "[OK] EC2 instance initialized. SSH in and run: python3 /opt/kinesis-producer/kinesis_producer.py"
