# 📊 Dossier Data - Pipeline de Traitements de Données pour le Cloud

## Description

Ce dossier contient les fichiers de données CSV pour le pipeline de traitement des matchs de football.

## 📁 Fichiers

### `football_matches_2024_2025.csv` ⭐ (PRINCIPAL)
- **Source** : Données complètes des matchs de football 2024-2025
- **Format** : CSV (1941 matchs)
- **Colonnes** : 23 colonnes incluant :
  - `match_id` : Identifiant unique du match
  - `date_utc` : Date et heure du match
  - `home_team` / `away_team` : Équipes
  - `fulltime_home` / `fulltime_away` : Scores finaux
  - `competition_name` : Type de compétition (Premier League, etc.)
  - `season` : Saison du match
  - Autres données : arbitre, stage, résultat, points, etc.

### `football_matches_test.csv`
- **Destination** : Fichier de test (non utilisé actuellement)
- **Usage** : Pour les tests et développement

### `generate_goals_*.py`
- Scripts Python pour générer des données de buts
- Utilisés pour les flux Kinesis/S3

## 🔄 Pipeline de Traitement

```
CSV local → S3 Bucket → Glue Crawler → Glue Catalog → Athena Queries → Power BI
```

### Étapes
1. **Upload S3** : Les fichiers CSV sont uploadés dans `s3://football-pipeline-data-624409990811-us-east-1/matches/`
2. **Glue Crawler** : Scan automatique et création de la table `matches` dans `football_db`
3. **Athena Views** : 7 vues SQL créées pour l'analyse :
   - `vw_match_stats` : Statistiques globales
   - `vw_competition_stats` : Stats par compétition
   - `vw_home_team_performance` : Performance à domicile
   - `vw_away_team_performance` : Performance à l'extérieur
   - `vw_team_overall_ranking` : Classement global
   - `vw_high_scoring_matches` : Matchs avec 4+ buts
   - `vw_season_summary` : Résumé par saison

## 📊 Statistiques

| Métrique | Valeur |
|----------|--------|
| Total Matchs | 1941 |
| Compétitions | Premier League (PL) |
| Saisons | 2024/2025 |
| Équipes | 20 (Premier League) |

## 🚀 Utilisation

### 1. Upload du fichier CSV
```bash
aws s3 cp football_matches_2024_2025.csv \
  s3://football-pipeline-data-624409990811-us-east-1/matches/ \
  --region us-east-1
```

### 2. Exécuter le Glue Crawler
```bash
aws glue start-crawler --name football-crawler --region us-east-1
```

### 3. Interroger avec Athena
```sql
SELECT * FROM football_db.matches LIMIT 10;
SELECT * FROM football_db.vw_match_stats;
SELECT * FROM football_db.vw_team_overall_ranking;
```

## 📝 Notes

- Les données sont stockées en **S3** pour la scalabilité
- Le **Glue Crawler** détecte automatiquement le schéma
- Les **vues Athena** permettent l'analyse sans transformation
- **Power BI** peut se connecter directement à Athena pour la visualisation

## 🔧 Technologies

- **Cloud** : AWS (S3, Glue, Athena)
- **Format** : CSV
- **Requêtes** : SQL
- **Visualisation** : Power BI

---

**Dernière mise à jour** : 27 janvier 2026
