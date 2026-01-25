"""
This script generates a timeline of goals for football matches based on their final scores.
It randomly distributes goals across the 90-minute match duration to create a realistic
streaming simulation of match events.
"""

import pandas as pd  # Library for data manipulation and reading CSV files
import random  # Module for generating random numbers
from datetime import datetime  # Module for date and time operations

# Read the CSV file containing all football matches data
df = pd.read_csv('data/football_matches_2024_2025.csv')

# Open the output file in write mode with UTF-8 encoding
with open('goals_timeline.txt', 'w', encoding='utf-8') as f:
    # Write the header section of the file
    f.write("=" * 80 + "\n")
    f.write("TIMELINE DES BUTS - FOOTBALL MATCHES 2024/2025\n")
    f.write("=" * 80 + "\n")
    # Include the generation timestamp
    f.write(f"Généré le: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}\n")
    f.write("=" * 80 + "\n\n")
    
    # Initialize match counter to track which match number we're processing
    match_number = 0
    
    # Iterate through each row (match) in the DataFrame
    for idx, row in df.iterrows():
        # Increment match counter for each new match being processed
        match_number += 1
        
        # Extract relevant match data from the current row
        home_team = row['home_team']  # Home team name
        away_team = row['away_team']  # Away team name
        home_goals = int(row['fulltime_home'])  # Total goals scored by home team
        away_goals = int(row['fulltime_away'])  # Total goals scored by away team
        match_date = row['date_utc']  # Match date and time in UTC
        
        # Calculate total goals in the match (for matches with 0 goals, handle separately)
        total_goals = home_goals + away_goals
        
        # Write the match header information
        f.write(f"\n{'='*80}\n")
        f.write(f"MATCH #{match_number}\n")
        f.write(f"{'='*80}\n")
        f.write(f"Date: {match_date}\n")
        f.write(f"{home_team} vs {away_team}\n")
        f.write(f"Résultat final: {home_goals} - {away_goals}\n")
        f.write(f"Total de buts: {total_goals}\n")
        f.write(f"{'-'*80}\n")
        
        # Handle special case: matches with no goals (0-0 draws)
        if total_goals == 0:
            f.write("0-0 (Match nul sans buts)\n")
        else:
            # Generate random minute values for each home team goal
            # random.sample() ensures no duplicate minutes are generated
            home_goal_minutes = sorted(random.sample(range(1, 91), home_goals)) if home_goals > 0 else []
            
            # Generate random minute values for each away team goal
            away_goal_minutes = sorted(random.sample(range(1, 91), away_goals)) if away_goals > 0 else []
            
            # Create a unified list combining all goals with their team information
            all_goals = []
            # Add home team goals to the list with home team indicator (🏠)
            for min_goal in home_goal_minutes:
                all_goals.append((min_goal, home_team, '🏠'))
            # Add away team goals to the list with away team indicator (✈️)
            for min_goal in away_goal_minutes:
                all_goals.append((min_goal, away_team, '✈️'))
            
            # Sort all goals chronologically by minute
            all_goals.sort(key=lambda x: x[0])
            
            # Initialize counters to track the running score as goals are written
            goal_counter_home = 0
            goal_counter_away = 0
            
            # Iterate through all goals in chronological order
            for minute, team, symbol in all_goals:
                # Check which team scored to update the correct counter
                if team == home_team:
                    goal_counter_home += 1
                    # Write home team goal with current score
                    f.write(f"⚽ {minute:>3}'  {symbol} {team} marque! ({goal_counter_home}-{goal_counter_away})\n")
                else:
                    goal_counter_away += 1
                    # Write away team goal with current score
                    f.write(f"⚽ {minute:>3}'  {symbol} {team} marque! ({goal_counter_home}-{goal_counter_away})\n")
        
        f.write("\n")

# Print success messages after the file is generated
print("✅ Fichier 'goals_timeline.txt' généré avec succès!")
# Display the total number of matches processed
print(f"📊 Total de matchs traités: {len(df)}")
# Show the output file location
print("📁 Emplacement: goals_timeline.txt")
