-- =====================================================
-- Vues SQL Athena pour Football Pipeline
-- Table source: football_db.football_data (Parquet)
-- Compatible avec Power BI + DSN ODBC
-- =====================================================

-- 1. Vue: Statistiques globales des matchs
CREATE OR REPLACE VIEW football_db.vw_match_stats AS
SELECT 
    COUNT(*) as total_matches,
    COUNT(DISTINCT competition_name) as total_competitions,
    COUNT(DISTINCT season) as total_seasons,
    COUNT(DISTINCT CASE WHEN home_team IS NOT NULL THEN home_team_id END) as total_teams,
    MIN(date_utc) as first_match_date,
    MAX(date_utc) as last_match_date,
    ROUND(AVG(fulltime_home + fulltime_away), 2) as avg_goals_per_match,
    ROUND(MAX(fulltime_home + fulltime_away), 0) as max_goals_in_match
FROM football_db.football_data;

-- 2. Vue: Statistiques par compétition
CREATE OR REPLACE VIEW football_db.vw_competition_stats AS
SELECT 
    competition_code,
    competition_name,
    season,
    COUNT(*) as match_count,
    COUNT(DISTINCT home_team_id) as unique_home_teams,
    COUNT(DISTINCT away_team_id) as unique_away_teams,
    ROUND(AVG(CAST(fulltime_home AS DOUBLE)), 2) as avg_home_goals,
    ROUND(AVG(CAST(fulltime_away AS DOUBLE)), 2) as avg_away_goals,
    ROUND(AVG(fulltime_home + fulltime_away), 2) as avg_total_goals,
    SUM(CASE WHEN fulltime_home > fulltime_away THEN 1 ELSE 0 END) as home_wins,
    SUM(CASE WHEN fulltime_home = fulltime_away THEN 1 ELSE 0 END) as draws,
    SUM(CASE WHEN fulltime_home < fulltime_away THEN 1 ELSE 0 END) as away_wins
FROM football_db.football_data
GROUP BY competition_code, competition_name, season
ORDER BY competition_code DESC, season DESC;

-- 3. Vue: Performance des équipes à domicile
CREATE OR REPLACE VIEW football_db.vw_home_team_performance AS
SELECT 
    home_team_id,
    home_team,
    COUNT(*) as home_matches,
    SUM(CASE WHEN fulltime_home > fulltime_away THEN 1 ELSE 0 END) as home_wins,
    SUM(CASE WHEN fulltime_home = fulltime_away THEN 1 ELSE 0 END) as home_draws,
    SUM(CASE WHEN fulltime_home < fulltime_away THEN 1 ELSE 0 END) as home_losses,
    SUM(fulltime_home) as total_goals_home,
    SUM(fulltime_away) as total_goals_conceded,
    ROUND(AVG(CAST(fulltime_home AS DOUBLE)), 2) as avg_goals_home,
    ROUND(AVG(CAST(fulltime_away AS DOUBLE)), 2) as avg_goals_conceded,
    SUM(home_points) as total_home_points,
    ROUND(AVG(CAST(home_points AS DOUBLE)), 2) as avg_points_per_match,
    ROUND(100.0 * SUM(CASE WHEN fulltime_home > fulltime_away THEN 1 ELSE 0 END) / COUNT(*), 2) as home_win_percentage
FROM football_db.football_data
GROUP BY home_team_id, home_team
ORDER BY total_home_points DESC, home_wins DESC;

-- 4. Vue: Performance des équipes à l'extérieur
CREATE OR REPLACE VIEW football_db.vw_away_team_performance AS
SELECT 
    away_team_id,
    away_team,
    COUNT(*) as away_matches,
    SUM(CASE WHEN fulltime_away > fulltime_home THEN 1 ELSE 0 END) as away_wins,
    SUM(CASE WHEN fulltime_away = fulltime_home THEN 1 ELSE 0 END) as away_draws,
    SUM(CASE WHEN fulltime_away < fulltime_home THEN 1 ELSE 0 END) as away_losses,
    SUM(fulltime_away) as total_goals_away,
    SUM(fulltime_home) as total_goals_conceded,
    ROUND(AVG(CAST(fulltime_away AS DOUBLE)), 2) as avg_goals_away,
    ROUND(AVG(CAST(fulltime_home AS DOUBLE)), 2) as avg_goals_conceded,
    SUM(away_points) as total_away_points,
    ROUND(AVG(CAST(away_points AS DOUBLE)), 2) as avg_points_per_match,
    ROUND(100.0 * SUM(CASE WHEN fulltime_away > fulltime_home THEN 1 ELSE 0 END) / COUNT(*), 2) as away_win_percentage
FROM football_db.football_data
GROUP BY away_team_id, away_team
ORDER BY total_away_points DESC, away_wins DESC;

-- 5. Vue: Classement global des équipes (Home + Away combiné)
CREATE OR REPLACE VIEW football_db.vw_team_overall_ranking AS
SELECT 
    team_id,
    team_name,
    SUM(total_matches) as total_matches,
    SUM(total_wins) as total_wins,
    SUM(total_draws) as total_draws,
    SUM(total_losses) as total_losses,
    SUM(total_goals_for) as total_goals_for,
    SUM(total_goals_against) as total_goals_against,
    (SUM(total_goals_for) - SUM(total_goals_against)) as goal_difference,
    (SUM(total_wins) * 3 + SUM(total_draws)) as total_points,
    ROUND(100.0 * SUM(total_wins) / SUM(total_matches), 2) as win_percentage,
    ROUND(AVG(CAST(total_goals_for AS DOUBLE)) / AVG(CAST(total_matches AS DOUBLE)), 2) as avg_goals_per_match
FROM (
    SELECT 
        home_team_id as team_id,
        home_team as team_name,
        COUNT(*) as total_matches,
        SUM(CASE WHEN fulltime_home > fulltime_away THEN 1 ELSE 0 END) as total_wins,
        SUM(CASE WHEN fulltime_home = fulltime_away THEN 1 ELSE 0 END) as total_draws,
        SUM(CASE WHEN fulltime_home < fulltime_away THEN 1 ELSE 0 END) as total_losses,
        SUM(fulltime_home) as total_goals_for,
        SUM(fulltime_away) as total_goals_against
    FROM football_db.football_data
    GROUP BY home_team_id, home_team
    
    UNION ALL
    
    SELECT 
        away_team_id as team_id,
        away_team as team_name,
        COUNT(*) as total_matches,
        SUM(CASE WHEN fulltime_away > fulltime_home THEN 1 ELSE 0 END) as total_wins,
        SUM(CASE WHEN fulltime_away = fulltime_home THEN 1 ELSE 0 END) as total_draws,
        SUM(CASE WHEN fulltime_away < fulltime_home THEN 1 ELSE 0 END) as total_losses,
        SUM(fulltime_away) as total_goals_for,
        SUM(fulltime_home) as total_goals_against
    FROM football_db.football_data
    GROUP BY away_team_id, away_team
) combined
GROUP BY team_id, team_name
ORDER BY total_points DESC, goal_difference DESC;

-- 6. Vue: Matchs avec plus de buts (>= 4 buts)
CREATE OR REPLACE VIEW football_db.vw_high_scoring_matches AS
SELECT 
    match_id,
    date_utc,
    home_team,
    away_team,
    fulltime_home,
    fulltime_away,
    (fulltime_home + fulltime_away) as total_goals,
    competition_name,
    season,
    stadium,
    attendance,
    match_outcome
FROM football_db.football_data
WHERE (fulltime_home + fulltime_away) >= 4
ORDER BY total_goals DESC, date_utc DESC;

-- 7. Vue: Résumé par saison et compétition
CREATE OR REPLACE VIEW football_db.vw_season_summary AS
SELECT 
    season,
    competition_name,
    COUNT(*) as total_matches,
    ROUND(AVG(CAST(fulltime_home AS DOUBLE)), 2) as avg_home_goals,
    ROUND(AVG(CAST(fulltime_away AS DOUBLE)), 2) as avg_away_goals,
    ROUND(AVG(fulltime_home + fulltime_away), 2) as avg_total_goals,
    SUM(CASE WHEN fulltime_home > fulltime_away THEN 1 ELSE 0 END) as home_wins,
    SUM(CASE WHEN fulltime_home = fulltime_away THEN 1 ELSE 0 END) as draws,
    SUM(CASE WHEN fulltime_home < fulltime_away THEN 1 ELSE 0 END) as away_wins,
    SUM(fulltime_home + fulltime_away) as total_goals_season,
    COUNT(DISTINCT home_team_id) as unique_teams
FROM football_db.football_data
GROUP BY season, competition_name
ORDER BY season DESC, competition_name;

-- 8. Vue: Comparaison domicile vs extérieur (agrégée)
CREATE OR REPLACE VIEW football_db.vw_home_away_comparison AS
SELECT 
    'Home' as location,
    COUNT(*) as matches,
    ROUND(AVG(CAST(fulltime_home AS DOUBLE)), 2) as avg_goals_scored,
    ROUND(AVG(CAST(fulltime_away AS DOUBLE)), 2) as avg_goals_conceded,
    ROUND(AVG(CAST(home_points AS DOUBLE)), 2) as avg_points_per_match,
    SUM(CASE WHEN fulltime_home > fulltime_away THEN 1 ELSE 0 END) as wins,
    SUM(CASE WHEN fulltime_home = fulltime_away THEN 1 ELSE 0 END) as draws,
    SUM(CASE WHEN fulltime_home < fulltime_away THEN 1 ELSE 0 END) as losses,
    ROUND(100.0 * SUM(CASE WHEN fulltime_home > fulltime_away THEN 1 ELSE 0 END) / COUNT(*), 2) as win_percentage
FROM football_db.football_data

UNION ALL

SELECT 
    'Away' as location,
    COUNT(*) as matches,
    ROUND(AVG(CAST(fulltime_away AS DOUBLE)), 2) as avg_goals_scored,
    ROUND(AVG(CAST(fulltime_home AS DOUBLE)), 2) as avg_goals_conceded,
    ROUND(AVG(CAST(away_points AS DOUBLE)), 2) as avg_points_per_match,
    SUM(CASE WHEN fulltime_away > fulltime_home THEN 1 ELSE 0 END) as wins,
    SUM(CASE WHEN fulltime_away = fulltime_home THEN 1 ELSE 0 END) as draws,
    SUM(CASE WHEN fulltime_away < fulltime_home THEN 1 ELSE 0 END) as losses,
    ROUND(100.0 * SUM(CASE WHEN fulltime_away > fulltime_home THEN 1 ELSE 0 END) / COUNT(*), 2) as win_percentage
FROM football_db.football_data
ORDER BY location;

-- 9. Vue: Matchs détaillés avec métadonnées
CREATE OR REPLACE VIEW football_db.vw_matches_detail AS
SELECT 
    match_id,
    date_utc,
    season,
    matchday,
    stage,
    competition_code,
    competition_name,
    home_team_id,
    home_team,
    away_team_id,
    away_team,
    fulltime_home,
    fulltime_away,
    halftime_home,
    halftime_away,
    goal_difference,
    total_goals,
    match_outcome,
    home_points,
    away_points,
    referee_id,
    referee,
    stadium,
    attendance,
    CASE 
        WHEN fulltime_home > fulltime_away THEN 'Home Win'
        WHEN fulltime_away > fulltime_home THEN 'Away Win'
        ELSE 'Draw'
    END as result_type
FROM football_db.football_data
ORDER BY date_utc DESC;

-- 10. Vue: Statistiques par arbitre
CREATE OR REPLACE VIEW football_db.vw_referee_statistics AS
SELECT 
    referee_id,
    referee,
    COUNT(*) as total_matches,
    ROUND(AVG(fulltime_home + fulltime_away), 2) as avg_goals_per_match,
    SUM(yellow_cards_home + yellow_cards_away) as total_yellow_cards,
    SUM(red_cards_home + red_cards_away) as total_red_cards,
    ROUND(100.0 * SUM(CASE WHEN fulltime_home > fulltime_away THEN 1 ELSE 0 END) / COUNT(*), 2) as home_win_percentage,
    MIN(date_utc) as first_match,
    MAX(date_utc) as last_match
FROM football_db.football_data
GROUP BY referee_id, referee
ORDER BY total_matches DESC;
