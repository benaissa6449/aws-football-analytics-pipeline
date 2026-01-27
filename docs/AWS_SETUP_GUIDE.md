# Configuration AWS pour Pipeline Football

## 1️⃣ Créer un Glue Job ETL via AWS Console

### Étape 1: Accéder à AWS Glue
1. Ouvrez https://console.aws.amazon.com/glue/
2. Cliquez sur **Jobs** → **Create job**

### Étape 2: Configuration du Job
- **Name**: `football-csv-to-parquet`
- **Job type**: `Spark`
- **Glue version**: `4.0` (ou plus récent)
- **Language**: `Python 3`
- **IAM Role**: Sélectionnez **LabRole** (ou créez une avec permissions S3 + Glue)

### Étape 3: Configuration Spark
Cliquez sur **Advanced properties**:
- **Max Concurrent Runs**: 1
- **Timeout**: 60 min
- **Max Retries**: 0
- **DPU**: 2.0 (suffisant pour des données petites/moyennes)

### Étape 4: Script Python
Copiez ce script dans l'éditeur:

```python
import sys
from awsglue.transforms import *
from awsglue.utils import getResolvedOptions
from pyspark.context import SparkContext
from awsglue.context import GlueContext
from awsglue.job import Job
from awsglue.dynamicframe import DynamicFrame
from pyspark.sql.functions import col, to_timestamp

args = getResolvedOptions(sys.argv, ['JOB_NAME'])
sc = SparkContext()
glueContext = GlueContext(sc)
spark = glueContext.spark_session
job = Job(glueContext)
job.init(args['JOB_NAME'], args)

# Paramètres
S3_INPUT = "s3://football-pipeline-data-624409990811-us-east-1/matches/"
S3_OUTPUT = "s3://football-pipeline-data-624409990811-us-east-1/parquet/"

# 1. Lire CSV
df = spark.read.option("header", "true").option("inferSchema", "true").csv(S3_INPUT)
print(f"Loaded {df.count()} rows")

# 2. Nettoyer et typer
df_clean = df.withColumn("match_id", col("match_id").cast("int")) \
    .withColumn("fulltime_home", col("fulltime_home").cast("int")) \
    .withColumn("fulltime_away", col("fulltime_away").cast("int")) \
    .filter(col("match_id").isNotNull())

# 3. Écrire en Parquet partitionné par season
df_clean.coalesce(4).write.mode("overwrite").partitionBy("season").parquet(S3_OUTPUT)
print(f"Written to {S3_OUTPUT}")

job.commit()
```

### Étape 5: Job Parameters
Cliquez sur **Job parameters** et ajoutez:
| Key | Value |
|-----|-------|
| `--S3_BUCKET` | `football-pipeline-data-624409990811-us-east-1` |

### Étape 6: Créer et Exécuter
Cliquez **Save job and edit script** → **Run job**

---

## 2️⃣ Configurer les Partitions Athena

### Après que le Glue Job ait écrit en Parquet:

1. Ouvrez **Athena Console**: https://console.aws.amazon.com/athena/
2. Sélectionnez database: `football_db`
3. Exécutez cette requête **une par une**:

#### Créer la table partitionnée:
```sql
CREATE EXTERNAL TABLE IF NOT EXISTS football_db.matches_parquet (
    competition_code STRING,
    competition_name STRING,
    match_id INT,
    matchday INT,
    stage STRING,
    status STRING,
    date_utc TIMESTAMP,
    referee STRING,
    referee_id INT,
    home_team_id INT,
    home_team STRING,
    away_team_id INT,
    away_team STRING,
    fulltime_home INT,
    fulltime_away INT,
    halftime_home INT,
    halftime_away INT,
    goal_difference INT,
    total_goals INT,
    match_outcome STRING,
    home_points INT,
    away_points INT
)
PARTITIONED BY (season STRING)
STORED AS PARQUET
LOCATION 's3://football-pipeline-data-624409990811-us-east-1/parquet/';
```

#### Synchroniser les partitions:
```sql
MSCK REPAIR TABLE football_db.matches_parquet;
```

#### Vérifier les partitions:
```sql
SHOW PARTITIONS football_db.matches_parquet;
```

#### Tester une requête partitionnée (plus rapide):
```sql
SELECT COUNT(*) as total_matches
FROM football_db.matches_parquet
WHERE season = '2024/2025';
```

---

## 3️⃣ Connecter Power BI à Athena (ODBC)

### Prérequis:
- ODBC Driver for Amazon Athena installé ([Télécharger](https://docs.aws.amazon.com/athena/latest/ug/connect-with-odbc.html))

### Configuration ODBC DSN:

1. **Windows**: Ouvrez **Outils de données ODBC** (tapez `ODBC` dans Windows Search)
2. Cliquez **Ajouter** (dans l'onglet DNS utilisateur)
3. Sélectionnez **Amazon Athena ODBC Driver**
4. Remplissez:
   - **DSN**: `AthenaFootball`
   - **Workgroup**: `football-workgroup`
   - **S3 Output Location**: `s3://query-results-bucket-football-624409990811/`
   - **Region**: `us-east-1`
   - **Database**: `football_db`
   - **AWS Access Key ID**: [Votre clé]
   - **AWS Secret Access Key**: [Votre secret]

5. Cliquez **Test** pour vérifier la connexion ✓

### Connecter Power BI Desktop:

1. Ouvrez **Power BI Desktop**
2. **Accueil** → **Obtenir les données** → **ODBC**
3. Sélectionnez le DSN: `AthenaFootball`
4. Cliquez **Charger**
5. Sélectionnez les vues à importer:
   - `vw_match_stats`
   - `vw_competition_stats`
   - `vw_home_team_performance`
   - `vw_away_team_performance`
   - `vw_team_overall_ranking`
   - `vw_high_scoring_matches`
   - `vw_season_summary`

6. Cliquez **Charger**

### Créer des Visualisations:

Exemples:
- **Graphique**: Top 10 équipes (depuis `vw_team_overall_ranking`)
- **Table**: Matchs à haut score (depuis `vw_high_scoring_matches`)
- **Indicateur KPI**: Total de matchs (depuis `vw_match_stats`)
- **Carte thermique**: Stats par compétition (depuis `vw_competition_stats`)

---

## Résumé du Pipeline Final

```
CSV (S3 matches/) 
    ↓
Glue Job ETL (CSV → Parquet, partitionné par season)
    ↓
Parquet (S3 parquet/, optimisé)
    ↓
Athena (Requêtes SQL + Vues)
    ↓
Power BI (ODBC Driver) → Visualisations
```

**Avantages:**
✅ Parquet = 80% compression vs CSV
✅ Partitions = Requêtes 10x plus rapides
✅ Power BI = Dashboard interactifs
