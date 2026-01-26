#!/usr/bin/env python3
"""
Football Goals Kinesis Streamer
Streams goal events from CSV data to AWS Kinesis
Based on ingestion pattern from streaming pipeline
"""

import pandas as pd
import json
import boto3
import os
import random
import time
from datetime import datetime

# Configuration
STREAM_NAME = os.getenv('KINESIS_STREAM_NAME', 'goals-stream')
REGION = os.getenv('AWS_REGION', 'eu-west-1')

def read_csv_data(filepath):
    """Read football matches CSV data"""
    try:
        df = pd.read_csv(filepath)
        print(f"✅ Loaded {len(df)} matches from CSV")
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

def get_match_data(row, idx):
    """Extract match data from CSV row"""
    match_id = str(row.get('match_id', idx))
    home_team = row.get('home_team', 'Unknown')
    away_team = row.get('away_team', 'Unknown')
    home_goals = int(row.get('fulltime_home', 0))
    away_goals = int(row.get('fulltime_away', 0))
    referee = row.get('referee', 'Unknown')
    
    return {
        'match_id': match_id,
        'home_team': home_team,
        'away_team': away_team,
        'home_goals': home_goals,
        'away_goals': away_goals,
        'referee': referee
    }

def generate_events(match_data):
    """Generate all events for a match"""
    events = []
    
    match_id = match_data['match_id']
    home_team = match_data['home_team']
    away_team = match_data['away_team']
    home_goals = match_data['home_goals']
    away_goals = match_data['away_goals']
    referee = match_data['referee']
    total_goals = home_goals + away_goals
    goal_times = generate_goal_times(home_goals, away_goals, total_goals)
    
    # Match start event
    events.append({
        'event_type': 'MATCH_START',
        'match_id': match_id,
        'home_team': home_team,
        'away_team': away_team,
        'referee': referee,
        'expected_home_goals': home_goals,
        'expected_away_goals': away_goals,
        'timestamp': datetime.now().isoformat()
    })
    
    # Goal events
    home_goals_scored = 0
    away_goals_scored = 0
    
    for minute in goal_times:
        if home_goals_scored < home_goals and (away_goals_scored >= away_goals or random.random() < 0.5):
            scoring_team = home_team
            team_type = 'home'
            home_goals_scored += 1
        else:
            scoring_team = away_team
            team_type = 'away'
            away_goals_scored += 1
        
        events.append({
            'event_type': 'GOAL',
            'match_id': match_id,
            'minute': minute,
            'scoring_team': scoring_team,
            'team_type': team_type,
            'home_goals_current': home_goals_scored,
            'away_goals_current': away_goals_scored,
            'timestamp': datetime.now().isoformat()
        })
    
    # Match end event
    events.append({
        'event_type': 'MATCH_END',
        'match_id': match_id,
        'home_team': home_team,
        'away_team': away_team,
        'final_home_goals': home_goals,
        'final_away_goals': away_goals,
        'timestamp': datetime.now().isoformat()
    })
    
    return events

def stream_to_kinesis(events, kinesis_client, match_id):
    """Stream events to Kinesis"""
    for event in events:
        try:
            kinesis_client.put_record(
                StreamName=STREAM_NAME,
                Data=json.dumps(event),
                PartitionKey=str(match_id)
            )
            print(f"   ✅ {event['event_type']} sent to Kinesis")
        except Exception as e:
            print(f"   ❌ Error sending {event['event_type']}: {str(e)}")
        
        # Small delay between events to simulate realistic streaming
        time.sleep(0.1)

def main():
    """Main streaming function"""
    print("=" * 80)
    print("FOOTBALL GOALS KINESIS STREAMER - 2024/2025")
    print("=" * 80)
    print(f"Streaming to Kinesis: {STREAM_NAME}")
    print(f"Region: {REGION}")
    print("=" * 80 + "\n")
    
    # Initialize Kinesis client
    kinesis_client = boto3.client('kinesis', region_name=REGION)
    
    # Read CSV
    csv_path = 'data/football_matches_2024_2025.csv'
    df = read_csv_data(csv_path)
    
    if df is None:
        return
    
    # Process and stream matches
    total_matches = len(df)
    successful = 0
    
    print(f"📊 Processing {total_matches} matches...\n")
    
    try:
        for idx, row in df.iterrows():
            match_data = get_match_data(row, idx)
            
            print(f"📊 MATCH #{idx + 1}: {match_data['home_team']} vs {match_data['away_team']}")
            print(f"   Expected score: {match_data['home_goals']}-{match_data['away_goals']}")
            
            # Generate and stream events
            events = generate_events(match_data)
            stream_to_kinesis(events, kinesis_client, match_data['match_id'])
            
            print(f"   ✅ Match complete\n")
            successful += 1
            
            # Realistic wait between matches
            wait_time = round(random.uniform(0.1, 0.5), 3)
            time.sleep(wait_time)
    
    except KeyboardInterrupt:
        print("\n⚠️ Streaming interrupted by user\n")
    except Exception as e:
        print(f"\n❌ Error: {e}\n")
    
    # Summary
    print("=" * 80)
    print("STREAMING SUMMARY")
    print("=" * 80)
    print(f"✅ Total matches processed: {successful}")
    print(f"📊 Total matches in dataset: {total_matches}")
    print(f"💾 Data streamed to Kinesis: {STREAM_NAME}")
    print("=" * 80)

if __name__ == '__main__':
    main()
