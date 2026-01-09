from airflow import DAG
from airflow.operators.bash import BashOperator
from datetime import datetime

with DAG(
    dag_id="data_pipeline",
    start_date=datetime(2024, 1, 1),
    schedule_interval="@daily",
    catchup=False,
) as dag:

    extract = BashOperator(
        task_id="extract",
        bash_command="echo 'Extract data from source'"
    )

    transform = BashOperator(
        task_id="transform",
        bash_command="spark-submit /opt/spark/jobs/transform_job.py"
    )

    load = BashOperator(
        task_id="load",
        bash_command="echo 'Load data to destination'"
    )

    extract >> transform >> load