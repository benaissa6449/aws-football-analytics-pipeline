#!/usr/bin/env python3
"""
Kinesis Goals Simulator - Simulates football goals in real-time
Based on actual match data, distributes goals randomly throughout 90 minutes
"""

import csv
import json
import time
import random
import boto3
import sys
from datetime import datetime
from collections import defaultdict

# Initialize Kinesis client
kinesis = boto3.client('kinesis', region_name='us-east-1')
STREAM_NAME = 'football-pipeline-dev-goals-stream'

def read_matches_csv(csv_path):
    """Read matches from CSV file"""
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
        sys.exit(1)

def simulate_goals_for_match(match):
    """
    Simulate goals for a match based on final score
    Returns list of goal events with simulated minutes
    """
    home_goals = int(match.get('fulltime_home', 0))
    away_goals = int(match.get('fulltime_away', 0))
    total_goals = home_goals + away_goals
    
    if total_goals == 0:
        return []
    
    goals = []
    
    # Generate random minutes for each goal (0-90)
    goal_minutes = sorted(random.sample(range(1, 91), total_goals))
    
    # Distribute goals to home/away
    home_goal_count = 0
    for minute in goal_minutes:
        if home_goal_count < home_goals:
            # 50% chance to be home goal, or if away goals already assigned
            if random.random() < 0.5 or (total_goals - len(goals) <= away_goals - home_goal_count + home_goals - home_goal_count):
                team_id = match.get('home_team_id')
                team_name = match.get('home_team')
                home_goal_count += 1
            else:
                team_id = match.get('away_team_id')
                team_name = match.get('away_team')
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
            'home_team_id': int(match.get('home_team_id', 0)),
            'away_team_id': int(match.get('away_team_id', 0)),
            'competition': match.get('competition_name'),
            'season': match.get('season'),
            'date': match.get('date_utc'),
            'timestamp': datetime.utcnow().isoformat() + 'Z'
        }
        goals.append(goal)
    
    return goals

def send_to_kinesis(goal_event, delay=1.0):
    """
    Send goal event to Kinesis stream
    delay: wait time between goals (seconds)
    """
    try:
        partition_key = str(goal_event['match_id'])
        
        response = kinesis.put_record(
            StreamName=STREAM_NAME,
            Data=json.dumps(goal_event),
            PartitionKey=partition_key
        )
        
        print(f"[GOAL] Goal: {goal_event['scorer_team']} @ {goal_event['minute']:2d}' | "
              f"Match: {goal_event['home_team']} vs {goal_event['away_team']} | "
              f"ShardID: {response['ShardId']}")
        
        time.sleep(delay)
        
    except Exception as e:
        print(f"[ERROR] Error sending to Kinesis: {str(e)}")

def run_simulation(csv_path, delay=1.0, start_match=0, num_matches=None):
    """
    Run the goals simulation
    
    Args:
        csv_path: Path to matches CSV file
        delay: Delay between goals in seconds (default 1.0)
        start_match: Start from match N (default 0 = all)
        num_matches: Limit to N matches (default None = all)
    """
    print("=" * 80)
    print("KINESIS GOALS SIMULATOR - Football Match Events")
    print("=" * 80)
    print(f"Stream: {STREAM_NAME}")
    print(f"Delay between goals: {delay} second(s)")
    print()
    
    # Read matches
    matches = read_matches_csv(csv_path)
    
    # Apply filters
    if num_matches:
        matches = matches[start_match:start_match + num_matches]
    else:
        matches = matches[start_match:]
    
    print(f"Processing {len(matches)} matches...\n")
    
    # Statistics
    total_goals = 0
    matches_with_goals = 0
    start_time = time.time()
    
    # Process each match
    for idx, match in enumerate(matches, 1):
        goals = simulate_goals_for_match(match)
        
        if goals:
            matches_with_goals += 1
            total_goals += len(goals)
            
            print(f"Match {idx}/{len(matches)}: {match['home_team']} {match['fulltime_home']}-{match['fulltime_away']} {match['away_team']}")
            
            for goal in goals:
                send_to_kinesis(goal, delay=delay)
            
            print()
    
    elapsed = time.time() - start_time
    
    print("=" * 80)
    print("SIMULATION COMPLETE")
    print("=" * 80)
    print(f"[OK] Matches processed: {len(matches)}")
    print(f"[OK] Matches with goals: {matches_with_goals}")
    print(f"[OK] Total goals sent: {total_goals}")
    print(f"[OK] Time elapsed: {elapsed:.1f} seconds ({elapsed/60:.1f} minutes)")
    print(f"[OK] Average: {total_goals/elapsed:.2f} goals/second")
    print()

if __name__ == "__main__":
    import argparse
    
    parser = argparse.ArgumentParser(description='Simulate football goals to Kinesis')
    parser.add_argument('--csv', 
                       default='data/football_matches_2024_2025.csv',
                       help='Path to CSV file (default: data/football_matches_2024_2025.csv)')
    parser.add_argument('--delay', 
                       type=float, 
                       default=1.0,
                       help='Delay between goals in seconds (default: 1.0)')
    parser.add_argument('--start', 
                       type=int, 
                       default=0,
                       help='Start from match N (default: 0)')
    parser.add_argument('--limit', 
                       type=int, 
                       default=None,
                       help='Process only N matches (default: all)')
    
    args = parser.parse_args()
    
    try:
        run_simulation(args.csv, delay=args.delay, start_match=args.start, num_matches=args.limit)
    except KeyboardInterrupt:
        print("\n[INTERRUPTED] Simulation interrupted by user")
        sys.exit(0)
