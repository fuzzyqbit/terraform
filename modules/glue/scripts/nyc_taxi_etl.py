import sys
from awsglue.transforms import *
from awsglue.utils import getResolvedOptions
from pyspark.context import SparkContext
from awsglue.context import GlueContext
from awsglue.job import Job
from pyspark.sql.functions import col, year, month, dayofmonth, hour, round as spark_round
from datetime import datetime

# Get job parameters
args = getResolvedOptions(sys.argv, [
    'JOB_NAME',
    'SOURCE_BUCKET',
    'TARGET_BUCKET',
    'DATABASE_NAME'
])

# Initialize Glue context
sc = SparkContext()
glueContext = GlueContext(sc)
spark = glueContext.spark_session
job = Job(glueContext)
job.init(args['JOB_NAME'], args)

print(f"Starting ETL job: {args['JOB_NAME']}")
print(f"Source bucket: {args['SOURCE_BUCKET']}")
print(f"Target bucket: {args['TARGET_BUCKET']}")
print(f"Database: {args['DATABASE_NAME']}")

# Read data from S3
source_path = f"s3://{args['SOURCE_BUCKET']}/nyc-taxi/"
print(f"Reading data from: {source_path}")

# Create DynamicFrame from catalog
try:
    datasource = glueContext.create_dynamic_frame.from_catalog(
        database=args['DATABASE_NAME'],
        table_name="nyc_taxi",
        transformation_ctx="datasource"
    )
    
    # Convert to Spark DataFrame for easier transformations
    df = datasource.toDF()
    
    print(f"Record count: {df.count()}")
    print("Schema:")
    df.printSchema()
    
    # Data transformations
    print("Performing transformations...")
    
    # 1. Clean data - remove nulls and invalid values
    df_clean = df.filter(
        (col("passenger_count") > 0) &
        (col("trip_distance") > 0) &
        (col("fare_amount") > 0) &
        (col("total_amount") > 0)
    )
    
    # 2. Add derived columns
    df_transformed = df_clean \
        .withColumn("pickup_year", year(col("tpep_pickup_datetime"))) \
        .withColumn("pickup_month", month(col("tpep_pickup_datetime"))) \
        .withColumn("pickup_day", dayofmonth(col("tpep_pickup_datetime"))) \
        .withColumn("pickup_hour", hour(col("tpep_pickup_datetime"))) \
        .withColumn("fare_per_mile", spark_round(col("fare_amount") / col("trip_distance"), 2)) \
        .withColumn("tip_percentage", spark_round((col("tip_amount") / col("fare_amount")) * 100, 2))
    
    # 3. Create aggregations
    print("Creating aggregations...")
    
    # Aggregation by hour
    hourly_stats = df_transformed.groupBy(
        "pickup_year", "pickup_month", "pickup_day", "pickup_hour"
    ).agg({
        "trip_distance": "avg",
        "fare_amount": "avg",
        "total_amount": "sum",
        "passenger_count": "sum",
        "vendorid": "count"
    }).withColumnRenamed("count(vendorid)", "trip_count") \
      .withColumnRenamed("avg(trip_distance)", "avg_distance") \
      .withColumnRenamed("avg(fare_amount)", "avg_fare") \
      .withColumnRenamed("sum(total_amount)", "total_revenue") \
      .withColumnRenamed("sum(passenger_count)", "total_passengers")
    
    # Write transformed data to S3 (partitioned by year and month)
    target_path = f"s3://{args['TARGET_BUCKET']}/nyc-taxi-processed/detailed/"
    print(f"Writing detailed data to: {target_path}")
    
    df_transformed.write \
        .mode("overwrite") \
        .partitionBy("pickup_year", "pickup_month") \
        .parquet(target_path)
    
    # Write aggregated data
    agg_target_path = f"s3://{args['TARGET_BUCKET']}/nyc-taxi-processed/hourly_stats/"
    print(f"Writing aggregated data to: {agg_target_path}")
    
    hourly_stats.write \
        .mode("overwrite") \
        .partitionBy("pickup_year", "pickup_month") \
        .parquet(agg_target_path)
    
    print("ETL job completed successfully")
    print(f"Processed records: {df_clean.count()}")
    
except Exception as e:
    print(f"Error during ETL processing: {str(e)}")
    raise e

job.commit()