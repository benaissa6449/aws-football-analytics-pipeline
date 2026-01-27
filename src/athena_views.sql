-- =====================================================
-- Vues SQL Athena pour Statistics de Football
-- =====================================================

-- 1. Vue: Statistiques globales des matchs
CREATE OR REPLACE VIEW football_db.vw_match_stats AS
SELECT 
    COUNT(*) as total_matches,
    COUNT(DISTINCT competition_code) as total_competitions,
    COUNT(DISTINCT season) as total_seasons,
    COUNT(DISTINCT home_team_id) as total_teams,
    MIN(date_utc) as first_match_date,
    MAX(date_utc) as last_match_date
FROM football_db.matches;

-- 2. Vue: Statistiques par compétition
CREATE OR REPLACE VIEW football_db.vw_competition_stats AS
SELECT 
    competition_code,
    competition_name,
    season,
    COUNT(*) as match_count,
    COUNT(DISTINCT home_team_id) as unique_home_teams,
    COUNT(DISTINCT away_team_id) as unique_away_teams,
    AVG(CAST(fulltime_home AS DOUBLE)) as avg_home_goals,
    AVG(CAST(fulltime_away AS DOUBLE)) as avg_away_goals
FROM football_db.matches
GROUP BY competition_code, competition_name, season
ORDER BY competition_code, season;

-- 3. Vue: Performance des équipes à domicile
CREATE OR REPLACE VIEW football_db.vw_home_team_performance AS
SELECT 
    home_team_id,
    home_team,
    COUNT(*) as home_matches,
    SUM(CASE WHEN fulltime_home > fulltime_away THEN 1 ELSE 0 END) as home_wins,
    SUM(CASE WHEN fulltime_home = fulltime_away THEN 1 ELSE 0 END) as home_draws,
    SUM(CASE WHEN fulltime_home < fulltime_away THEN 1 ELSE 0 END) as home_losses,
    ROUND(SUM(CAST(fulltime_home AS DOUBLE)) / COUNT(*), 2) as avg_home_goals,
    ROUND(100.0 * SUM(CASE WHEN fulltime_home > fulltime_away THEN 1 ELSE 0 END) / COUNT(*), 2) as home_win_percentage
FROM football_db.matches
GROUP BY home_team_id, home_team
ORDER BY home_wins DESC;

-- 4. Vue: Performance des équipes à l'extérieur
CREATE OR REPLACE VIEW football_db.vw_away_team_performance AS
SELECT 
    away_team_id,
    away_team,
    COUNT(*) as away_matches,
    SUM(CASE WHEN fulltime_away > fulltime_home THEN 1 ELSE 0 END) as away_wins,
    SUM(CASE WHEN fulltime_away = fulltime_home THEN 1 ELSE 0 END) as away_draws,
    SUM(CASE WHEN fulltime_away < fulltime_home THEN 1 ELSE 0 END) as away_losses,
    ROUND(SUM(CAST(fulltime_away AS DOUBLE)) / COUNT(*), 2) as avg_away_goals,
    ROUND(100.0 * SUM(CASE WHEN fulltime_away > fulltime_home THEN 1 ELSE 0 END) / COUNT(*), 2) as away_win_percentage
FROM football_db.matches
GROUP BY away_team_id, away_team
ORDER BY away_wins DESC;

-- 5. Vue: Classement global des équipes
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
    ROUND(100.0 * SUM(total_wins) / SUM(total_matches), 2) as win_percentage
FROM (
    SELECT 
        home_team_id as team_id,
        home_team as team_name,
        COUNT(*) as total_matches,
        SUM(CASE WHEN fulltime_home > fulltime_away THEN 1 ELSE 0 END) as total_wins,
        SUM(CASE WHEN fulltime_home = fulltime_away THEN 1 ELSE 0 END) as total_draws,
        SUM(CASE WHEN fulltime_home < fulltime_away THEN 1 ELSE 0 END) as total_losses,
        SUM(CAST(fulltime_home AS INT)) as total_goals_for,
        SUM(CAST(fulltime_away AS INT)) as total_goals_against
    FROM football_db.matches
    GROUP BY home_team_id, home_team
    
    UNION ALL
    
    SELECT 
        away_team_id as team_id,
        away_team as team_name,
        COUNT(*) as total_matches,
        SUM(CASE WHEN fulltime_away > fulltime_home THEN 1 ELSE 0 END) as total_wins,
        SUM(CASE WHEN fulltime_away = fulltime_home THEN 1 ELSE 0 END) as total_draws,
        SUM(CASE WHEN fulltime_away < fulltime_home THEN 1 ELSE 0 END) as total_losses,
        SUM(CAST(fulltime_away AS INT)) as total_goals_for,
        SUM(CAST(fulltime_home AS INT)) as total_goals_against
    FROM football_db.matches
    GROUP BY away_team_id, away_team
) combined
GROUP BY team_id, team_name
ORDER BY total_points DESC, goal_difference DESC;

-- 6. Vue: Matchs avec plus de buts
CREATE OR REPLACE VIEW football_db.vw_high_scoring_matches AS
SELECT 
    match_id,
    date_utc,
    home_team,
    away_team,
    fulltime_home,
    fulltime_away,
    (CAST(fulltime_home AS INT) + CAST(fulltime_away AS INT)) as total_goals,
    competition_name,
    season
FROM football_db.matches
WHERE (CAST(fulltime_home AS INT) + CAST(fulltime_away AS INT)) >= 4
ORDER BY total_goals DESC, date_utc DESC;

-- 7. Vue: Résumé par saison
CREATE OR REPLACE VIEW football_db.vw_season_summary AS
SELECT 
    season,
    COUNT(*) as total_matches,
    AVG(CAST(fulltime_home AS DOUBLE)) as avg_home_goals,
    AVG(CAST(fulltime_away AS DOUBLE)) as avg_away_goals,
    ROUND(AVG(CAST(fulltime_home AS DOUBLE) + CAST(fulltime_away AS DOUBLE)), 2) as avg_total_goals,
    SUM(CASE WHEN fulltime_home > fulltime_away THEN 1 ELSE 0 END) as home_wins,
    SUM(CASE WHEN fulltime_home = fulltime_away THEN 1 ELSE 0 END) as draws,
    SUM(CASE WHEN fulltime_home < fulltime_away THEN 1 ELSE 0 END) as away_wins
FROM football_db.matches
GROUP BY season
ORDER BY season DESC;
