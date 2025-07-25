#!/bin/bash
set -e

echo "🔍 Current Directory: $(pwd)"
echo "📂 Listing current contents:"
ls -R

echo "📤 Uploading CSV file to S3..."
aws s3 cp data/raw/insurance_claims.csv s3://aws--automate/raw/