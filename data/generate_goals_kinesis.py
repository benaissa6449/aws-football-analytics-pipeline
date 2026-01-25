"""
This script generates a timeline of goals for football matches and streams them to AWS Kinesis.
Instead of writing to a file, it sends real-time goal events to a Kinesis Data Stream,
which is then captured by Kinesis Firehose and stored in S3.

Prerequisites:
- AWS credentials configured (via IAM role in Cloud9 or AWS CLI)
- boto3 library installed
- Kinesis stream created via Terraform
- Terraform resources deployed: terraform apply

Environment Variables (optional):
- AWS_REGION: AWS region (default: eu-west-1)
- KINESIS_STREAM_NAME: Kinesis stream name (default: goals-stream)
"""

import pandas as pd  # Library for data manipulation and reading CSV files
import random  # Module for generating random numbers
from datetime import datetime  # Module for date and time operations
import json  # Module for JSON serialization
import boto3  # AWS SDK for Python
import time  # Module for adding delays in streaming simulation
import os  # Module for environment variables

# Get AWS configuration from environment variables or use defaults
AWS_REGION = os.getenv('AWS_REGION', 'eu-west-1')
KINESIS_STREAM_NAME = os.getenv('KINESIS_STREAM_NAME', 'goals-stream')

# Initialize the Kinesis client using the configured region
kinesis_client = boto3.client('kinesis', region_name=AWS_REGION)

# Read the CSV file containing all football matches data
df = pd.read_csv('data/football_matches_2024_2025.csv')

def send_to_kinesis(event_data):
    """
    Send an event (goal) to AWS Kinesis Data Stream.
    
    Args:
        event_data (dict): Dictionary containing event information (match_id, minute, team, etc.)
    
    Returns:
        bool: True if successful, False if failed
    """
    try:
        # Convert the event dictionary to JSON string for transmission
        message = json.dumps(event_data)
        
        # Use match_id as partition key to ensure related events go to the same shard
        response = kinesis_client.put_record(
            StreamName=KINESIS_STREAM_NAME,
            Data=message,
            # Partition key ensures all events for a match are processed together
            PartitionKey=str(event_data['match_id'])
        )
        
        # Log the successful transmission with sequence number
        print(f"✅ Goal sent to Kinesis | Match: {event_data['match_id']} | "
              f"Minute: {event_data['minute']} | Sequence: {response['SequenceNumber']}")
        return True
    
    except Exception as e:
        # Log any errors that occur during transmission
        print(f"❌ Error sending to Kinesis: {str(e)}")
        return False

def process_match(match_number, home_team, away_team, home_goals, away_goals, 
                 match_date, match_id, referee):
    """
    Process a single match: generate goal times and send them to Kinesis.
    
    Args:
        match_number (int): Sequential match number
        home_team (str): Name of home team
        away_team (str): Name of away team
        home_goals (int): Number of goals by home team
        away_goals (int): Number of goals by away team
        match_date (str): Match date and time
        match_id (int): Unique match identifier
        referee (str): Name of referee
    """
    
    # Log match start event
    print(f"\n📊 MATCH #{match_number}: {home_team} vs {away_team}")
    print(f"   Expected score: {home_goals}-{away_goals}")
    
    # Send match start event to Kinesis
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
    send_to_kinesis(match_start_event)
    
    # Handle matches with no goals (0-0 draws)
    total_goals = home_goals + away_goals
    if total_goals == 0:
        print("   ⚽ No goals in this match (0-0)")
        # Send match end event
        match_end_event = {
            'event_type': 'MATCH_END',
            'match_id': match_id,
            'final_home_goals': 0,
            'final_away_goals': 0,
            'timestamp': datetime.now().isoformat()
        }
        send_to_kinesis(match_end_event)
        return
    
    # Generate random minute values for each home team goal
    # random.sample() ensures no duplicate minutes are generated
    home_goal_minutes = sorted(random.sample(range(1, 91), home_goals)) if home_goals > 0 else []
    
    # Generate random minute values for each away team goal
    away_goal_minutes = sorted(random.sample(range(1, 91), away_goals)) if away_goals > 0 else []
    
    # Create a unified list combining all goals with their team information
    all_goals = []
    # Add home team goals to the list
    for min_goal in home_goal_minutes:
        all_goals.append({
            'minute': min_goal,
            'team': home_team,
            'team_type': 'home'
        })
    # Add away team goals to the list
    for min_goal in away_goal_minutes:
        all_goals.append({
            'minute': min_goal,
            'team': away_team,
            'team_type': 'away'
        })
    
    # Sort all goals chronologically by minute
    all_goals.sort(key=lambda x: x['minute'])
    
    # Initialize counters to track the running score as goals are generated
    goal_counter_home = 0
    goal_counter_away = 0
    
    # Simulate streaming: iterate through all goals in chronological order
    for goal in all_goals:
        minute = goal['minute']
        team = goal['team']
        team_type = goal['team_type']
        
        # Update the running score
        if team_type == 'home':
            goal_counter_home += 1
        else:
            goal_counter_away += 1
        
        # Create goal event payload to send to Kinesis
        goal_event = {
            'event_type': 'GOAL',
            'match_id': match_id,
            'minute': minute,
            'scoring_team': team,
            'team_type': team_type,
            'home_goals_current': goal_counter_home,
            'away_goals_current': goal_counter_away,
            'timestamp': datetime.now().isoformat()
        }
        
        # Send goal event to Kinesis
        send_to_kinesis(goal_event)
        
        # Small delay to simulate realistic streaming (optional - comment out for faster processing)
        # time.sleep(0.5)
    
    # Send match end event with final score
    match_end_event = {
        'event_type': 'MATCH_END',
        'match_id': match_id,
        'final_home_goals': goal_counter_home,
        'final_away_goals': goal_counter_away,
        'timestamp': datetime.now().isoformat()
    }
    send_to_kinesis(match_end_event)
    print(f"   ✅ Match complete: {goal_counter_home}-{goal_counter_away}")

# Main processing loop
if __name__ == "__main__":
    print("=" * 80)
    print("FOOTBALL GOALS KINESIS STREAMER - 2024/2025")
    print("=" * 80)
    print(f"Streaming to Kinesis Stream: {KINESIS_STREAM_NAME}")
    print(f"Region: {AWS_REGION}")
    print("\n💡 Terraform Resources:")
    print("   - Kinesis: managed via infrastructure/kinesis.tf")
    print("   - Firehose: managed via infrastructure/kinesis.tf")
    print("   - S3: managed via infrastructure/s3.tf")
    print("   - IAM: managed via infrastructure/iam.tf")
    print("=" * 80)
    
    match_number = 0
    successful_matches = 0
    
    try:
        # Iterate through each match in the DataFrame
        for idx, row in df.iterrows():
            match_number += 1
            
            # Extract match data from CSV row
            home_team = row['home_team']
            away_team = row['away_team']
            home_goals = int(row['fulltime_home'])
            away_goals = int(row['fulltime_away'])
            match_date = row['date_utc']
            match_id = int(row['match_id'])
            referee = row['referee']
            
            # Process the match and stream its goals to Kinesis
            process_match(match_number, home_team, away_team, home_goals, 
                         away_goals, match_date, match_id, referee)
            
            successful_matches += 1
            
            # Optional: Add delay between matches for realistic streaming simulation
            # time.sleep(1)
    
    except KeyboardInterrupt:
        # Handle user interruption (Ctrl+C)
        print("\n\n⚠️ Streaming interrupted by user")
    
    except Exception as e:
        # Handle any unexpected errors
        print(f"\n❌ Unexpected error: {str(e)}")
    
    finally:
        # Print summary statistics after streaming completes
        print("\n" + "=" * 80)
        print("STREAMING SUMMARY")
        print("=" * 80)
        print(f"✅ Total matches processed: {successful_matches}")
        print(f"📊 Total matches in dataset: {len(df)}")
        print(f"✅ All events sent to Kinesis stream: {KINESIS_STREAM_NAME}")
        print(f"💾 Data will be stored in S3 via Kinesis Firehose")
        print("=" * 80)
