#!/usr/bin/env python3
"""List all S3 buckets to see what exists"""

import boto3

s3_client = boto3.client('s3', region_name='eu-west-1')

try:
    response = s3_client.list_buckets()
    buckets = response.get('Buckets', [])
    
    print("📦 S3 Buckets in your account:\n")
    if buckets:
        for bucket in buckets:
            print(f"  - {bucket['Name']}")
    else:
        print("  (no buckets found)")
        
except Exception as e:
    print(f"❌ Error listing buckets: {e}")
