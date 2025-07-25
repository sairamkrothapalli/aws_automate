#!/bin/bash
set -e

echo "🔍 Working directory: $(pwd)"
echo "📂 Listing files inside workspace:"
ls -R

CSV_FILE="data/raw/insurance_claims.csv"
SCRIPT_FILE="data/scripts/glue_transform.py"
BUCKET="aws--automate"
GLUE_JOB_NAME="insurance-etl-job"

# 📤 Upload CSV file to raw/
if [ -f "$CSV_FILE" ]; then
  echo "📤 Uploading $CSV_FILE to S3 bucket $BUCKET/raw/..."
  aws s3 cp "$CSV_FILE" s3://$BUCKET/raw/
else
  echo "❌ ERROR: CSV file not found at path: $CSV_FILE"
  exit 1
fi

# 📤 Upload Glue script to scripts/
if [ -f "$SCRIPT_FILE" ]; then
  echo "📤 Uploading $SCRIPT_FILE to S3 bucket $BUCKET/scripts/..."
  aws s3 cp "$SCRIPT_FILE" s3://$BUCKET/scripts/
else
  echo "❌ ERROR: Script file not found at path: $SCRIPT_FILE"
  exit 1
fi

# ✅ Trigger Glue Job only if no other run is active
RUNNING_JOB=$(aws glue get-job-runs --job-name "$GLUE_JOB_NAME" \
  --max-results 3 \
  --query 'JobRuns[?JobRunState==`RUNNING` && EndTime==`null`].Id' \
  --output text)

if [ -n "$RUNNING_JOB" ]; then
  echo "⚠️ A Glue job is already running (JobRunId: $RUNNING_JOB). Skipping new run."
  exit 0  # ✅ Don't fail Jenkins build
else
  echo "🚀 Triggering AWS Glue Job: $GLUE_JOB_NAME ..."
  job_run_id=$(aws glue start-job-run --job-name "$GLUE_JOB_NAME" --query 'JobRunId' --output text)
  echo "🆔 Triggered job with JobRunId: $job_run_id"
fi

# ⏳ Wait for the job to complete
echo "⌛ Waiting for AWS Glue job to complete..."
while true; do
  state=$(aws glue get-job-run --job-name "$GLUE_JOB_NAME" --run-id "$job_run_id" --query 'JobRun.JobRunState' --output text)
  echo "🔄 Current job state: $state"
  if [[ "$state" == "SUCCEEDED" ]]; then
    echo "✅ Glue job completed successfully!"
    exit 0
  elif [[ "$state" == "FAILED" || "$state" == "TIMEOUT" ]]; then
    echo "❌ Glue job failed with state: $state"
    exit 1
  fi
  sleep 15
done