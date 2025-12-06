# Scripts Python pour le Pipeline

## 📁 Fichiers

### 1. `goals_producer.py`
**Producteur de données pour Kinesis**

Simule des événements de buts en temps réel et les envoie à Kinesis Streams.

#### Installation
```bash
pip install boto3
```

#### Configuration
```python
KINESIS_STREAM_NAME = "goals-stream"
REGION = "eu-west-1"
```

#### Utilisation
```bash
# Exécution infinie
python goals_producer.py

# Avec variables d'environnement
AWS_PROFILE=default python goals_producer.py
```

#### Paramètres
```python
producer.run(
    interval=5,      # Intervalle entre les buts (secondes)
    duration=None    # Durée totale (None = infini)
)
```

### 2. `glue_job_etl.py`
**Job Glue pour transformation des données**

Lit les données brutes (goals_raw) et les matchs, nettoie et enrichit, puis écrit vers goals_clean.

#### Déploiement
1. Télécharger vers S3 :
```bash
aws s3 cp glue_job_etl.py s3://foot-data-bucket/scripts/
```

2. Mettre à jour `glue.tf` avec le chemin S3 correct

3. Configurer les variables :
```python
S3_BUCKET = "foot-data-bucket"  # À remplacer
DATABASE_NAME = "football_db"
```

#### Exécution
```bash
# Via Terraform (recommandé)
terraform apply

# Via AWS Console
# Glue → Jobs → goals-etl → Run job
```

### 3. `athena_queries.sql`
**Requêtes SQL pour créer les vues analytiques**

Contient 8 vues Athena pour l'analyse.

#### Déploiement
1. Ouvrir Athena dans AWS Console
2. Sélectionner workgroup : `football-workgroup`
3. Copier-coller chaque requête CREATE VIEW
4. Exécuter

#### Vues créées
- `vw_match_stats` : Statistiques des matchs
- `vw_live_goals` : Flux en temps réel
- `vw_goals_by_league` : Analyse par ligue
- `vw_top_scorers` : Classement buteurs
- `vw_goals_by_minute` : Analyse temporelle
- `vw_match_summary` : Résumé des matchs
- `vw_team_comparison` : Comparaison équipes
- `vw_league_trends` : Tendances par ligue

## 📋 Exemple de Données

### Format Kinesis (goals_producer.py)
```json
{
  "event_id": "goal_1702000000.123456",
  "timestamp": "2024-12-06T10:00:00.123456",
  "league": "PL",
  "home_team": "Man City",
  "away_team": "Liverpool",
  "scorer": "Player_42",
  "minute": 45,
  "goal_type": "Open Play",
  "match_id": "match_2024-12-06_Man City_Liverpool"
}
```

### Format S3 (goals_raw)
Fichiers JSON dans : `s3://foot-data-bucket/goals_raw/`

### Format S3 (goals_clean)
Fichiers Parquet partitionnés dans : `s3://foot-data-bucket/goals_clean/year=YYYY/month=MM/`

## 🔧 Configuration AWS

### Credentials
```bash
# Option 1: ~/.aws/credentials
aws configure

# Option 2: Variables d'environnement
export AWS_ACCESS_KEY_ID=...
export AWS_SECRET_ACCESS_KEY=...
export AWS_REGION=eu-west-1
```

### IAM Permissions Requises
- Kinesis: PutRecord, PutRecords
- S3: GetObject, PutObject, ListBucket
- Glue: All (pour le crawler et job)
- CloudWatch: PutMetricData (logs)

## 📊 Monitoring

### CloudWatch Logs
```bash
# Logs du producteur
# Configurer dans le script (optionnel)

# Logs du job Glue
aws logs tail /aws-glue/football-pipeline --follow

# Logs du Firehose
aws logs tail /aws/firehose/football-pipeline --follow
```

### Métriques Kinesis
```bash
# Voir les métriques du stream
aws kinesis describe-stream --stream-name goals-stream
```

## 🐛 Dépannage

### Erreur: "Cannot connect to Kinesis"
- Vérifier les credentials AWS
- Vérifier la région AWS
- Vérifier la sécurité du VPC/SG

### Erreur: "Bucket not found"
- Vérifier le nom exact du bucket
- Vérifier les permissions S3
- Vérifier la région

### Job Glue échoue
- Vérifier les logs CloudWatch
- Vérifier le chemin du script S3
- Vérifier les permissions IAM

## 📞 Support

Pour des questions sur les scripts, consulter :
- AWS Glue Documentation: https://docs.aws.amazon.com/glue/
- Boto3 Documentation: https://boto3.amazonaws.com/
