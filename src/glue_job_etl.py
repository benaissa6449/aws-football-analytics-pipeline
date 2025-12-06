#!/usr/bin/env python3
"""
Job AWS Glue pour transformer les données de buts
ETL: Extraction → Transformation → Chargement

Ce job reçoit:
- goals_raw/: buts bruts depuis Firehose
- matches/: données historiques des matchs

Output: goals_clean/ (données nettoyées et enrichies)
"""

import sys
from awsglue.transforms import *
from awsglue.utils import getResolvedOptions
from pyspark.context import SparkContext
from awsglue.context import GlueContext
from awsglue.job import Job

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

# Paramètres
S3_BUCKET = "foot-data-bucket"  # À remplacer par le vrai bucket
DATABASE_NAME = "football_db"

try:
    # 1. Lire les données brutes des buts depuis S3
    print("📖 Lecture des données brutes des buts...")
    goals_raw_dyf = glueContext.create_dynamic_frame.from_options(
        connection_type="s3",
        connection_options={"paths": [f"s3://{S3_BUCKET}/goals_raw/"]},
        format="json",
    )

    # 2. Lire les données des matchs
    print("📖 Lecture des données des matchs...")
    matches_dyf = glueContext.create_dynamic_frame.from_options(
        connection_type="s3",
        connection_options={"paths": [f"s3://{S3_BUCKET}/matches/"]},
        format="csv",
        format_options={"withHeader": True},
    )

    # 3. Convertir en Spark DataFrames
    goals_df = goals_raw_dyf.toDF()
    matches_df = matches_dyf.toDF()

    # 4. Nettoyage des données
    print("🧹 Nettoyage des données...")

    # Supprimer les doublons et les valeurs NULL critiques
    goals_clean = goals_df.dropDuplicates(["event_id"]).filter(
        goals_df["scorer"].isNotNull()
    )

    # Ajouter des colonnes de traitement
    from pyspark.sql.functions import (
        current_timestamp,
        col,
        when,
        year,
        month,
        dayofmonth,
    )

    goals_clean = goals_clean.withColumn(
        "processed_at", current_timestamp()
    ).withColumn("year", year(col("timestamp"))).withColumn(
        "month", month(col("timestamp"))
    ).withColumn(
        "day", dayofmonth(col("timestamp"))
    )

    # 5. Enrichissement (jointure avec les données de matchs si nécessaire)
    print("🔗 Enrichissement des données...")
    # Exemple simple de jointure
    if not matches_df.rdd.isEmpty():
        goals_enriched = goals_clean.join(
            matches_df,
            goals_clean["match_id"] == matches_df["match_id"],
            "left",
        )
    else:
        goals_enriched = goals_clean

    # 6. Écrire les données nettoyées
    print("💾 Écriture des données nettoyées...")
    output_dyf = DynamicFrame.fromDF(
        goals_enriched, glueContext, "goals_clean_output"
    )

    glueContext.write_dynamic_frame.from_options(
        frame=output_dyf,
        connection_type="s3",
        connection_options={
            "path": f"s3://{S3_BUCKET}/goals_clean/",
            "partitionKeys": ["year", "month"],
        },
        format="parquet",
    )

    print("✅ ETL complété avec succès")

except Exception as e:
    print(f"❌ Erreur lors de l'ETL: {e}")
    raise

finally:
    job.commit()
