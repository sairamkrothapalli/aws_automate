#!/bin/bash
set -e

echo "🔍 Working directory: $(pwd)"
echo "📂 Listing files inside workspace:"
ls -R

CSV_FILE="data/raw/insurance_claims.csv"
SCRIPT_FILE="data/scripts/glue_transform.py"
BUCKET="aws--automate"

# Upload CSV file to raw/
if [ -f "$CSV_FILE" ]; then
  echo "📤 Uploading $CSV_FILE to S3 bucket $BUCKET/raw/..."
  aws s3 cp "$CSV_FILE" s3://$BUCKET/raw/
else
  echo "❌ ERROR: CSV file not found at path: $CSV_FILE"
  exit 1
fi

# Upload Glue script to scripts/
if [ -f "$SCRIPT_FILE" ]; then
  echo "📤 Uploading $SCRIPT_FILE to S3 bucket $BUCKET/scripts/..."
  aws s3 cp "$SCRIPT_FILE" s3://$BUCKET/scripts/
else
  echo "❌ ERROR: Script file not found at path: $SCRIPT_FILE"
  exit 1
fi
# ✅ Trigger Glue Job
echo "🚀 Triggering AWS Glue Job: $GLUE_JOB_NAME ..."
aws glue start-job-run --job-name "$GLUE_JOB_NAME"

echo "✅ Glue job triggered successfully!"