#!/bin/bash
set -e

echo "🔍 Working directory: $(pwd)"
echo "📂 Listing files inside workspace:"
ls -R

FILE_PATH="data/raw/insurance_claims.csv"
BUCKET="aws--automate"

if [ -f "$FILE_PATH" ]; then
  echo "📤 Uploading $FILE_PATH to S3 bucket $BUCKET..."
  aws s3 cp "$FILE_PATH" s3://$BUCKET/raw/
else
  echo "❌ ERROR: File not found at path: $FILE_PATH"
  exit 1
fi