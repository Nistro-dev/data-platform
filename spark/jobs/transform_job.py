from pyspark.sql import SparkSession

spark = SparkSession.builder.appName("transform").getOrCreate()

df = spark.read.csv("/data/input.csv", header=True)
df_clean = df.dropna()
df_clean.write.mode("overwrite").parquet("/data/output")

spark.stop()
