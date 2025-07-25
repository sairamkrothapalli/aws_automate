import sys
from awsglue.utils import getResolvedOptions
from pyspark.context import SparkContext
from awsglue.context import GlueContext
from awsglue.job import Job

# ✅ Initialize
args = getResolvedOptions(sys.argv, ['JOB_NAME'])
sc = SparkContext()
glueContext = GlueContext(sc)
spark = glueContext.spark_session
job = Job(glueContext)
job.init(args['JOB_NAME'], args)

# ✅ Read data from raw zone (CSV)
raw_path = "s3://aws--automate/raw/insurance_claims.csv"
datasource0 = glueContext.create_dynamic_frame.from_options(
    connection_type="s3",
    connection_options={"paths": [raw_path]},
    format="csv",
    format_options={"withHeader": True}
)

# ✅ Simple transformation (optional filtering can go here)
transformed_df = datasource0.toDF()
filtered_df = transformed_df.dropna()  # Drop null rows

# ✅ Convert back to DynamicFrame
from awsglue.dynamicframe import DynamicFrame
final_dyf = DynamicFrame.fromDF(filtered_df, glueContext, "final_dyf")

# ✅ Write to curated zone (Parquet)
glueContext.write_dynamic_frame.from_options(
    frame=final_dyf,
    connection_type="s3",
    connection_options={"path": "s3://aws--automate/curated/"},
    format="parquet"
)

job.commit()