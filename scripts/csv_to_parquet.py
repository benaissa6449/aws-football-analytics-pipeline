import sys
from awsglue.transforms import *
from awsglue.utils import getResolvedOptions
from pyspark.context import SparkContext
from awsglue.context import GlueContext
from awsglue.job import Job
from awsglue.dynamicframe import DynamicFrame

# Initialisation
args = getResolvedOptions(sys.argv, ['JOB_NAME'])
sc = SparkContext()
glueContext = GlueContext(sc)
spark = glueContext.spark_session
job = Job(glueContext)
job.init(args['JOB_NAME'], args)

# Lire depuis le catalogue Glue
datasource = glueContext.create_dynamic_frame.from_catalog(
    database = "football_db", 
    table_name = "matches"
)

# Transformation: convertir en DataFrame
df = datasource.toDF()

# Ecrire en Parquet avec partitionnement et compression
glueContext.write_dynamic_frame.from_options(
    frame = DynamicFrame.fromDF(df, glueContext, "result"),
    connection_type = "s3",
    connection_options = {
        "path": "s3://episen-football-processed-data/matches/",
        "partitionKeys": ["season", "competition_code"]
    },
    format = "parquet",
    format_options = {
        "compression": "snappy"
    }
)

job.commit()
