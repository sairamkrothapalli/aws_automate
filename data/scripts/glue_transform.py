import sys
from awsglue.transforms import *
from awsglue.utils import getResolvedOptions
from pyspark.context import SparkContext
from awsglue.context import GlueContext
from awsglue.job import Job

args = getResolvedOptions(sys.argv, ['JOB_NAME'])

sc = SparkContext()
glueContext = GlueContext(sc)
spark = glueContext.spark_session
job = Job(glueContext)
job.init(args['JOB_NAME'], args)

# Load data from raw S3
df = glueContext.create_dynamic_frame.from_options(
    connection_type="s3",
    connection_options={"paths": ["s3://aws--automate/raw/insurance_claims.csv"]},
    format="csv",
    format_options={"withHeader": True}
)

# Convert to DataFrame and transform
spark_df = df.toDF()
filtered_df = spark_df.filter(spark_df["ClaimStatus"] == "Approved")

# Save to curated folder
filtered_dynamic_df = DynamicFrame.fromDF(filtered_df, glueContext, "filtered_df")
glueContext.write_dynamic_frame.from_options(
    frame=filtered_dynamic_df,
    connection_type="s3",
    connection_options={"path": "s3://aws--automate/curated/"},
    format="csv"
)

job.commit()