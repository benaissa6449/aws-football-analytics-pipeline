#!/usr/bin/env python3
"""
AWS Glue Job ETL: Convert CSV to Parquet with Partitioning
- Reads CSV data from S3 matches/
- Transforms and cleans data
- Partitions by season
- Writes to Parquet format for optimized Athena queries
"""

import sys
import logging
from awsglue.transforms import *
from awsglue.utils import getResolvedOptions
from pyspark.context import SparkContext
from awsglue.context import GlueContext
from awsglue.job import Job
from pyspark.sql.functions import col

# Setup logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

# Arguments du job
args = getResolvedOptions(
    sys.argv,
    ["JOB_NAME", "TempDir"],
)

# Configuration Spark
sc = SparkContext()
glueContext = GlueContext(sc)
spark = glueContext.spark_session
job = Job(glueContext)
job.init(args["JOB_NAME"], args)

# Paramètres CORRECTS
S3_BUCKET = "football-pipeline-data-624409990811-us-east-1"
S3_INPUT_PATH = f"s3://{S3_BUCKET}/matches/"
S3_OUTPUT_PATH = f"s3://{S3_BUCKET}/parquet/"
DATABASE_NAME = "football_db"

logger.info(f"Job: {args['JOB_NAME']}")
logger.info(f"Input: {S3_INPUT_PATH}")
logger.info(f"Output: {S3_OUTPUT_PATH}")

try:
    # 1. Lire les données CSV depuis S3
    logger.info("📖 Lecture des données CSV...")
    df = spark.read \
        .option("header", "true") \
        .option("inferSchema", "true") \
        .csv(S3_INPUT_PATH)
    
    logger.info(f"✓ {df.count()} lignes chargées")
    
    # 2. Nettoyage et transformation des données
    logger.info("🧹 Nettoyage et transformation...")
    
    # Cast types de colonnes
    df_cleaned = df \
        .withColumn("match_id", col("match_id").cast("int")) \
        .withColumn("home_team_id", col("home_team_id").cast("int")) \
        .withColumn("away_team_id", col("away_team_id").cast("int")) \
        .withColumn("fulltime_home", col("fulltime_home").cast("int")) \
        .withColumn("fulltime_away", col("fulltime_away").cast("int")) \
        .withColumn("halftime_home", col("halftime_home").cast("int")) \
        .withColumn("halftime_away", col("halftime_away").cast("int"))
    
    # Supprimer les lignes avec match_id NULL
    df_cleaned = df_cleaned.filter(col("match_id").isNotNull())
    
    logger.info(f"✓ {df_cleaned.count()} lignes après nettoyage")
    
    # 3. Écriture en Parquet avec partitions par saison
    logger.info(f"💾 Écriture en Parquet avec partitions (par season)...")
    
    df_cleaned.coalesce(4) \
        .write \
        .mode("overwrite") \
        .partitionBy("season") \
        .parquet(S3_OUTPUT_PATH)
    
    logger.info(f"✓ Données écrites dans {S3_OUTPUT_PATH}")
    
    logger.info("✅ ETL complété avec succès")
    
    # Commit job
    job.commit()
    
except Exception as e:
    logger.error(f"Erreur lors de l'ETL: {e}")
    raise
