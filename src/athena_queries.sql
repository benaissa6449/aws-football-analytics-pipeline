-- Requêtes SQL Athena pour créer les vues analytiques

-- =================================================================
-- 1. Vue: Statistiques des Matchs
-- =================================================================
CREATE OR REPLACE VIEW football_db.vw_match_stats AS
SELECT 
    match_id,
    home_team,
    away_team,
    league,
    COUNT(*) as total_goals,
    COUNT(DISTINCT scorer) as unique_scorers,
    MIN(CAST(minute AS INT)) as first_goal_minute,
    MAX(CAST(minute AS INT)) as last_goal_minute,
    DATE_TRUNC('day', from_iso8601_timestamp(timestamp)) as match_date
FROM 
    goals_clean
GROUP BY 
    match_id, home_team, away_team, league, DATE_TRUNC('day', from_iso8601_timestamp(timestamp))
ORDER BY 
    match_date DESC;

-- =================================================================
-- 2. Vue: Flux en Temps Réel des Buts
-- =================================================================
CREATE OR REPLACE VIEW football_db.vw_live_goals AS
SELECT 
    event_id,
    timestamp,
    league,
    home_team,
    away_team,
    scorer,
    CAST(minute AS INT) as minute,
    goal_type,
    match_id
FROM 
    goals_clean
ORDER BY 
    timestamp DESC
LIMIT 1000;

-- =================================================================
-- 3. Vue: Analyse des Buts par Ligue
-- =================================================================
CREATE OR REPLACE VIEW football_db.vw_goals_by_league AS
SELECT 
    league,
    COUNT(*) as total_goals,
    COUNT(DISTINCT scorer) as unique_scorers,
    COUNT(DISTINCT match_id) as matches_with_goals,
    ROUND(AVG(CAST(minute AS DOUBLE)), 2) as avg_goal_minute,
    ROUND(100.0 * COUNT(*) / SUM(COUNT(*)) OVER (), 2) as percentage_goals,
    DATE_TRUNC('day', from_iso8601_timestamp(timestamp)) as date
FROM 
    goals_clean
GROUP BY 
    league, DATE_TRUNC('day', from_iso8601_timestamp(timestamp))
ORDER BY 
    date DESC, total_goals DESC;

-- =================================================================
-- 4. Vue: Top Buteurs
-- =================================================================
CREATE OR REPLACE VIEW football_db.vw_top_scorers AS
SELECT 
    scorer,
    league,
    COUNT(*) as goals_scored,
    COUNT(DISTINCT match_id) as matches_played,
    COUNT(CASE WHEN goal_type = 'Penalty' THEN 1 END) as penalties,
    COUNT(CASE WHEN goal_type = 'Header' THEN 1 END) as headers,
    COUNT(CASE WHEN goal_type = 'Free Kick' THEN 1 END) as free_kicks,
    ROUND(100.0 * COUNT(*) / SUM(COUNT(*)) OVER (PARTITION BY league), 2) as pct_league_goals,
    MIN(DATE_TRUNC('day', from_iso8601_timestamp(timestamp))) as first_goal,
    MAX(DATE_TRUNC('day', from_iso8601_timestamp(timestamp))) as last_goal
FROM 
    goals_clean
GROUP BY 
    scorer, league
ORDER BY 
    league ASC, goals_scored DESC;

-- =================================================================
-- 5. Vue: Analyse Temporelle (Buts par Minute)
-- =================================================================
CREATE OR REPLACE VIEW football_db.vw_goals_by_minute AS
SELECT 
    CAST(minute AS INT) as goal_minute,
    league,
    COUNT(*) as goals_count,
    COUNT(DISTINCT match_id) as matches,
    ROUND(100.0 * COUNT(*) / SUM(COUNT(*)) OVER (PARTITION BY league), 2) as pct_of_league_goals
FROM 
    goals_clean
WHERE 
    minute IS NOT NULL
GROUP BY 
    CAST(minute AS INT), league
ORDER BY 
    league ASC, goal_minute ASC;

-- =================================================================
-- 6. Vue: Résumé des Matchs avec Buts
-- =================================================================
CREATE OR REPLACE VIEW football_db.vw_match_summary AS
SELECT 
    match_id,
    home_team,
    away_team,
    league,
    COUNT(*) as goals,
    STRING_AGG(DISTINCT scorer, ', ') as scorers,
    MAX(CAST(minute AS INT)) as latest_goal_minute,
    DATE(from_iso8601_timestamp(timestamp)) as match_date
FROM 
    goals_clean
GROUP BY 
    match_id, home_team, away_team, league, DATE(from_iso8601_timestamp(timestamp))
ORDER BY 
    match_date DESC;

-- =================================================================
-- 7. Vue: Comparaison Équipes
-- =================================================================
CREATE OR REPLACE VIEW football_db.vw_team_comparison AS
SELECT 
    team_name,
    league,
    COUNT(*) as goals_for,
    COUNT(DISTINCT match_id) as matches,
    ROUND(COUNT(*) * 1.0 / COUNT(DISTINCT match_id), 2) as goals_per_match
FROM (
    SELECT home_team as team_name, league, match_id FROM goals_clean
    UNION ALL
    SELECT away_team as team_name, league, match_id FROM goals_clean
) team_goals
GROUP BY 
    team_name, league
ORDER BY 
    league ASC, goals_for DESC;

-- =================================================================
-- 8. Vue: Tendances par Ligue
-- =================================================================
CREATE OR REPLACE VIEW football_db.vw_league_trends AS
SELECT 
    league,
    DATE_TRUNC('day', from_iso8601_timestamp(timestamp)) as trend_date,
    COUNT(*) as daily_goals,
    COUNT(DISTINCT match_id) as daily_matches,
    COUNT(DISTINCT scorer) as daily_scorers
FROM 
    goals_clean
GROUP BY 
    league, DATE_TRUNC('day', from_iso8601_timestamp(timestamp))
ORDER BY 
    league ASC, trend_date DESC;

-- =================================================================
-- Notes de déploiement:
-- - Exécuter ces requêtes dans Athena (workgroup: football-workgroup)
-- - Ces vues utilisent la table 'goals_clean' du Glue Catalog
-- - Adapter les noms de tables/colonnes selon votre schéma réel
-- - Les vues peuvent être utilisées directement dans Power BI via ODBC/JDBC
-- =================================================================
