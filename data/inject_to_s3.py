"""
Direct S3 injection script - bypasses Kinesis
Writes goal events directly to S3 bucket
"""

import pandas as pd
import random
from datetime import datetime
import json
import boto3
import os

# AWS Configuration
AWS_REGION = os.getenv('AWS_REGION', 'eu-west-1')
S3_BUCKET = os.getenv('S3_BUCKET', 'football-pipeline-data-624409990811-eu-west-1')
S3_PREFIX = 'goals-data/raw/'

# Initialize S3 client
s3_client = boto3.client('s3', region_name=AWS_REGION)

# Read the CSV file
df = pd.read_csv('data/football_matches_2024_2025.csv')

def write_to_s3(events):
    """
    Write events directly to S3 as NDJSON (newline-delimited JSON)
    
    Args:
        events (list): List of event dictionaries
    
    Returns:
        bool: True if successful
    """
    try:
        # Convert events to NDJSON format
        ndjson_content = '\n'.join(json.dumps(event) for event in events)
        
        # Generate S3 key with timestamp
        timestamp = datetime.now().strftime('%Y-%m-%d-%H-%M-%S')
        s3_key = f"{S3_PREFIX}goals-{timestamp}.ndjson"
        
        # Write to S3
        s3_client.put_object(
            Bucket=S3_BUCKET,
            Key=s3_key,
            Body=ndjson_content,
            ContentType='application/x-ndjson'
        )
        
        print(f"✅ {len(events)} events written to S3: s3://{S3_BUCKET}/{s3_key}")
        return True
    
    except Exception as e:
        print(f"❌ Error writing to S3: {str(e)}")
        return False

def process_match(match_number, home_team, away_team, home_goals, away_goals, 
                 match_date, match_id, referee):
    """
    Process a single match and generate goal events
    """
    events = []
    
    print(f"\n📊 MATCH #{match_number}: {home_team} vs {away_team}")
    print(f"   Expected score: {home_goals}-{away_goals}")
    
    # Match start event
    match_start_event = {
        'event_type': 'MATCH_START',
        'match_id': match_id,
        'home_team': home_team,
        'away_team': away_team,
        'match_date': match_date,
        'expected_home_goals': home_goals,
        'expected_away_goals': away_goals,
        'referee': referee,
        'timestamp': datetime.now().isoformat()
    }
    events.append(match_start_event)
    
    # Generate goal times for home team
    if home_goals > 0:
        home_goal_times = sorted(random.sample(range(1, 91), home_goals))
        for goal_time in home_goal_times:
            goal_event = {
                'event_type': 'GOAL',
                'match_id': match_id,
                'team': home_team,
                'minute': goal_time,
                'scorer': f"Player {random.randint(1, 11)}",
                'timestamp': datetime.now().isoformat()
            }
            events.append(goal_event)
    
    # Generate goal times for away team
    if away_goals > 0:
        away_goal_times = sorted(random.sample(range(1, 91), away_goals))
        for goal_time in away_goal_times:
            goal_event = {
                'event_type': 'GOAL',
                'match_id': match_id,
                'team': away_team,
                'minute': goal_time,
                'scorer': f"Player {random.randint(1, 11)}",
                'timestamp': datetime.now().isoformat()
            }
            events.append(goal_event)
    
    # Match end event
    match_end_event = {
        'event_type': 'MATCH_END',
        'match_id': match_id,
        'final_score': f"{home_goals}-{away_goals}",
        'timestamp': datetime.now().isoformat()
    }
    events.append(match_end_event)
    
    return events

def main():
    print("=" * 80)
    print("FOOTBALL GOALS S3 INJECTOR - 2024/2025")
    print("=" * 80)
    print(f"Writing directly to S3: {S3_BUCKET}")
    print(f"Region: {AWS_REGION}")
    print("=" * 80)
    
    all_events = []
    total_matches = len(df)
    
    # Process first 50 matches as demo
    for idx, row in df.head(50).iterrows():
        match_number = idx + 1
        events = process_match(
            match_number=match_number,
            home_team=row['Home'],
            away_team=row['Away'],
            home_goals=row['HG'],
            away_goals=row['AG'],
            match_date=row['Date'],
            match_id=row['ID'],
            referee=row['Referee']
        )
        all_events.extend(events)
    
    # Write all events to S3
    if write_to_s3(all_events):
        print("\n" + "=" * 80)
        print("INJECTION COMPLETE")
        print("=" * 80)
        print(f"✅ {len(all_events)} total events injected")
        print(f"📊 Matches processed: 50")
        print(f"💾 Data stored in S3")
        print("=" * 80)
    else:
        print("❌ Injection failed!")

if __name__ == '__main__':
    main()
