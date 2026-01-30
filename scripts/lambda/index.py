import json
import boto3
import pandas as pd
import pyarrow.parquet as pq
from io import BytesIO
import os
from datetime import datetime

s3_client = boto3.client('s3')
glue_client = boto3.client('glue')
athena_client = boto3.client('athena')

# Environment variables
RAW_BUCKET = os.environ['RAW_BUCKET']
PROCESSED_BUCKET = os.environ['PROCESSED_BUCKET']
GLUE_DATABASE = os.environ['GLUE_DATABASE']
GLUE_TABLE = os.environ['GLUE_TABLE']
ATHENA_WORKGROUP = os.environ['ATHENA_WORKGROUP']
ATHENA_OUTPUT = os.environ['ATHENA_OUTPUT']

def lambda_handler(event, context):
    """
    Lambda handler for CSV to Parquet transformation pipeline
    """
    try:
        print(f"Starting CSV to Parquet transformation at {datetime.now()}")
        print(f"Event: {json.dumps(event)}")
        
        # PHASE 1: Download and transform CSV
        print("\n=== PHASE 1: CSV Transformation ===")
        df = read_csv_from_s3()
        df = convert_data_types(df)
        
        # PHASE 2: Upload Parquet to S3
        print("\n=== PHASE 2: Upload Parquet to S3 ===")
        parquet_key = upload_parquet_to_s3(df)
        
        # PHASE 3: Update Athena table
        print("\n=== PHASE 3: Update Athena Table ===")
        create_athena_table()
        
        # PHASE 4: Verify data
        print("\n=== PHASE 4: Verification ===")
        verify_data()
        
        return {
            'statusCode': 200,
            'body': json.dumps({
                'message': 'Pipeline completed successfully',
                'rows_processed': len(df),
                'parquet_location': f's3://{PROCESSED_BUCKET}/{parquet_key}'
            })
        }
        
    except Exception as e:
        print(f"ERROR: {str(e)}")
        return {
            'statusCode': 500,
            'body': json.dumps({'error': str(e)})
        }


def read_csv_from_s3():
    """Download CSV from raw S3 bucket and return as DataFrame"""
    print(f"Reading CSV from s3://{RAW_BUCKET}/football_matches_2024_2025.csv")
    
    try:
        obj = s3_client.get_object(
            Bucket=RAW_BUCKET,
            Key='football_matches_2024_2025.csv'
        )
        df = pd.read_csv(obj['Body'])
        print(f"✓ CSV loaded: {len(df)} rows, {len(df.columns)} columns")
        print(f"  Columns: {list(df.columns)}")
        return df
    except Exception as e:
        raise Exception(f"Failed to read CSV from S3: {str(e)}")


def convert_data_types(df):
    """Convert DataFrame columns to correct data types"""
    print("\nConverting data types...")
    
    # Integer columns (int32)
    int_columns = [
        'match_id', 'matchday', 'home_team_id', 'away_team_id',
        'fulltime_home', 'fulltime_away', 'halftime_home', 'halftime_away',
        'goal_difference', 'total_goals', 'home_points', 'away_points', 'referee_id'
    ]
    
    for col in int_columns:
        if col in df.columns:
            df[col] = pd.to_numeric(df[col], errors='coerce').fillna(0).astype('int32')
            print(f"  ✓ {col}: int32")
    
    # DateTime column
    if 'date_utc' in df.columns:
        df['date_utc'] = pd.to_datetime(df['date_utc'], errors='coerce')
        print(f"  ✓ date_utc: datetime64")
    
    # String columns
    text_columns = [
        'competition_code', 'competition_name', 'season', 'stage', 'status',
        'referee', 'home_team', 'away_team', 'match_outcome'
    ]
    
    for col in text_columns:
        if col in df.columns:
            df[col] = df[col].astype('string')
            print(f"  ✓ {col}: string")
    
    return df


def upload_parquet_to_s3(df):
    """Convert DataFrame to Parquet and upload to S3"""
    print(f"\nCreating Parquet file...")
    
    try:
        # Convert to Parquet in memory
        parquet_buffer = BytesIO()
        df.to_parquet(parquet_buffer, compression='gzip', index=False)
        parquet_buffer.seek(0)
        
        parquet_key = 'parquet/football_data.parquet'
        file_size = len(parquet_buffer.getvalue()) / (1024 * 1024)
        
        # Upload to S3
        s3_client.put_object(
            Bucket=PROCESSED_BUCKET,
            Key=parquet_key,
            Body=parquet_buffer.getvalue(),
            ContentType='application/octet-stream'
        )
        
        print(f"✓ Parquet uploaded: {file_size:.2f} MB")
        print(f"  Location: s3://{PROCESSED_BUCKET}/{parquet_key}")
        
        return parquet_key
        
    except Exception as e:
        raise Exception(f"Failed to upload Parquet: {str(e)}")


def create_athena_table():
    """Create or replace Athena table"""
    print(f"\nCreating Athena table in {GLUE_DATABASE}.{GLUE_TABLE}...")
    
    create_table_sql = f"""
    DROP TABLE IF EXISTS {GLUE_DATABASE}.{GLUE_TABLE};
    
    CREATE EXTERNAL TABLE {GLUE_DATABASE}.{GLUE_TABLE}(
      match_id INT,
      competition_code STRING,
      competition_name STRING,
      season STRING,
      matchday INT,
      stage STRING,
      status STRING,
      date_utc TIMESTAMP,
      referee STRING,
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
      away_points INT,
      referee_id INT
    )
    ROW FORMAT SERDE 
      'org.apache.hadoop.hive.ql.io.parquet.serde.ParquetHiveSerDe'
    STORED AS INPUTFORMAT 
      'org.apache.hadoop.hive.ql.io.parquet.MapredParquetInputFormat'
    OUTPUTFORMAT 
      'org.apache.hadoop.hive.ql.io.parquet.MapredParquetOutputFormat'
    LOCATION
      's3://{PROCESSED_BUCKET}/parquet/'
    """
    
    try:
        response = athena_client.start_query_execution(
            QueryString=create_table_sql,
            QueryExecutionContext={'Database': GLUE_DATABASE},
            WorkGroup=ATHENA_WORKGROUP,
            ResultConfiguration={'OutputLocation': ATHENA_OUTPUT}
        )
        
        query_id = response['QueryExecutionId']
        print(f"✓ CREATE TABLE query started: {query_id}")
        
        # Wait for query completion
        wait_for_query(query_id)
        print(f"✓ Table {GLUE_TABLE} created successfully")
        
    except Exception as e:
        raise Exception(f"Failed to create Athena table: {str(e)}")


def verify_data():
    """Run verification query"""
    print(f"\nVerifying data in {GLUE_TABLE}...")
    
    verify_sql = f"""
    SELECT 
      COUNT(*) as total_rows,
      COUNT(DISTINCT match_id) as unique_matches,
      COUNT(DISTINCT home_team_id) as unique_teams,
      MIN(date_utc) as first_date,
      MAX(date_utc) as last_date
    FROM {GLUE_DATABASE}.{GLUE_TABLE}
    """
    
    try:
        response = athena_client.start_query_execution(
            QueryString=verify_sql,
            QueryExecutionContext={'Database': GLUE_DATABASE},
            WorkGroup=ATHENA_WORKGROUP,
            ResultConfiguration={'OutputLocation': ATHENA_OUTPUT}
        )
        
        query_id = response['QueryExecutionId']
        print(f"✓ Verification query started: {query_id}")
        
        # Wait for query completion
        wait_for_query(query_id)
        
        # Get results
        results = athena_client.get_query_results(QueryExecutionId=query_id)
        rows = results['ResultSet']['Rows']
        
        if len(rows) > 1:
            row = rows[1]['Data']
            print(f"✓ Verification Results:")
            print(f"  - Total rows: {row[0]['VarCharValue']}")
            print(f"  - Unique matches: {row[1]['VarCharValue']}")
            print(f"  - Unique teams: {row[2]['VarCharValue']}")
            print(f"  - Date range: {row[3]['VarCharValue']} to {row[4]['VarCharValue']}")
        
    except Exception as e:
        print(f"WARNING: Verification query failed (non-critical): {str(e)}")


def wait_for_query(query_id, max_attempts=60):
    """Wait for Athena query to complete"""
    for attempt in range(max_attempts):
        response = athena_client.get_query_execution(QueryExecutionId=query_id)
        status = response['QueryExecution']['Status']['State']
        
        if status in ['SUCCEEDED', 'FAILED', 'CANCELLED']:
            if status != 'SUCCEEDED':
                raise Exception(f"Query failed with status: {status}")
            return True
        
        print(f"  Waiting for query... (attempt {attempt + 1}/{max_attempts})")
        import time
        time.sleep(1)
    
    raise Exception(f"Query timed out after {max_attempts} attempts")
