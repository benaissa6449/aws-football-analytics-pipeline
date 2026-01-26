#!/usr/bin/env python3
"""
Football Goals to S3 Stream
Reads CSV data, generates goal events, and writes directly to S3
"""

import pandas as pd
import json
import boto3
import os
from datetime import datetime, timedelta
import random

# Configuration
AWS_REGION = os.getenv('AWS_REGION', 'eu-west-1')
S3_BUCKET = os.getenv('S3_BUCKET_NAME', 'foot-data-bucket-624409990811')
S3_PREFIX = 'goals_raw'

# Initialize S3 client
s3_client = boto3.client('s3', region_name=AWS_REGION)

# Print header
print("=" * 80)
print("FOOTBALL GOALS S3 WRITER - 2024/2025")
print("=" * 80)
print(f"Writing to S3 Bucket: {S3_BUCKET}")
print(f"Region: {AWS_REGION}")
print(f"Prefix: {S3_PREFIX}/")
print("=" * 80)

def read_csv_data(filepath):
    """Read football matches CSV data"""
    try:
        df = pd.read_csv(filepath)
        print(f"\n✅ Loaded {len(df)} matches from CSV")
        return df
    except Exception as e:
        print(f"❌ Error reading CSV: {e}")
        return None

def generate_goal_times(home_goals, away_goals, total_goals):
    """Generate random goal times (minutes 0-90)"""
    if total_goals == 0:
        return []
    
    goal_times = []
    for _ in range(total_goals):
        minute = random.randint(1, 90)
        goal_times.append(minute)
    
    return sorted(goal_times)

def process_match(match_id, home_team, away_team, home_goals, away_goals, match_date, referee):
    """Process a single match and generate goal events"""
    events = []
    total_goals = home_goals + away_goals
    goal_times = generate_goal_times(home_goals, away_goals, total_goals)
    
    # Match start event
    match_start = {
        'event_type': 'MATCH_START',
        'match_id': str(match_id),
        'home_team': home_team,
        'away_team': away_team,
        'referee': referee,
        'expected_home_goals': home_goals,
        'expected_away_goals': away_goals,
        'timestamp': datetime.now().isoformat()
    }
    events.append(match_start)
    
    # Goal events
    home_goals_scored = 0
    away_goals_scored = 0
    
    for idx, minute in enumerate(goal_times):
        # Determine which team scored
        if home_goals_scored < home_goals and (away_goals_scored >= away_goals or random.random() < 0.5):
            scoring_team = home_team
            team_type = 'home'
            home_goals_scored += 1
            current_home = home_goals_scored
            current_away = away_goals_scored
        else:
            scoring_team = away_team
            team_type = 'away'
            away_goals_scored += 1
            current_home = home_goals_scored
            current_away = away_goals_scored
        
        goal_event = {
            'event_type': 'GOAL',
            'match_id': str(match_id),
            'minute': minute,
            'scoring_team': scoring_team,
            'team_type': team_type,
            'home_goals_current': current_home,
            'away_goals_current': current_away,
            'timestamp': datetime.now().isoformat()
        }
        events.append(goal_event)
    
    # Match end event
    match_end = {
        'event_type': 'MATCH_END',
        'match_id': str(match_id),
        'home_team': home_team,
        'away_team': away_team,
        'final_home_goals': home_goals,
        'final_away_goals': away_goals,
        'timestamp': datetime.now().isoformat()
    }
    events.append(match_end)
    
    return events

def write_to_s3(events, match_id, home_team, away_team):
    """Write events to S3 as JSONL"""
    try:
        # Create file content (JSONL format - one JSON per line)
        content = '\n'.join([json.dumps(event) for event in events])
        
        # Create S3 key with date partition
        now = datetime.now()
        s3_key = f"{S3_PREFIX}/{now.year:04d}/{now.month:02d}/{now.day:02d}/{now.hour:02d}/match_{match_id}_{int(datetime.now().timestamp())}.jsonl"
        
        # Upload to S3
        s3_client.put_object(
            Bucket=S3_BUCKET,
            Key=s3_key,
            Body=content.encode('utf-8'),
            ContentType='application/x-ndjson'
        )
        
        return s3_key
    except Exception as e:
        print(f"   ❌ Error writing to S3: {e}")
        return None

def main():
    """Main function"""
    # Read CSV
    csv_path = 'data/football_matches_2024_2025.csv'
    df = read_csv_data(csv_path)
    
    if df is None:
        return
    
    # Process matches
    total_matches = len(df)
    successful = 0
    
    print(f"\n📊 Processing {total_matches} matches...\n")
    
    try:
        for idx, row in df.iterrows():
            
            match_id = row.get('match_id', idx)
            home_team = row.get('home_team', 'Unknown')
            away_team = row.get('away_team', 'Unknown')
            home_goals = int(row.get('fulltime_home', 0))
            away_goals = int(row.get('fulltime_away', 0))
            match_date = row.get('match_date', '')
            referee = row.get('referee', 'Unknown')
            
            print(f"📊 MATCH #{idx + 1}: {home_team} vs {away_team}")
            print(f"   Expected score: {home_goals}-{away_goals}")
            
            # Process match
            events = process_match(match_id, home_team, away_team, home_goals, away_goals, match_date, referee)
            
            # Write to S3
            s3_key = write_to_s3(events, match_id, home_team, away_team)
            
            if s3_key:
                print(f"   ✅ Written to S3: {s3_key}")
                successful += 1
            else:
                print(f"   ❌ Failed to write to S3")
            
            print()
    
    except KeyboardInterrupt:
        print("\n⚠️ Streaming interrupted by user\n")
    except Exception as e:
        print(f"\n❌ Error processing matches: {e}\n")
    
    # Summary
    print("=" * 80)
    print("STREAMING SUMMARY")
    print("=" * 80)
    print(f"✅ Total matches processed: {successful}")
    print(f"📊 Total matches in dataset: {total_matches}")
    print(f"💾 Data stored in S3: s3://{S3_BUCKET}/{S3_PREFIX}/")
    print("=" * 80)

if __name__ == '__main__':
    main()
