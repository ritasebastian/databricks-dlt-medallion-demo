# File-arrival job (optional automated mode)

The pipeline itself uses Auto Loader to process files whenever it runs. `resources/file_arrival_job.yml` configures a Lakeflow Job to start an incremental update on new files in the Unity Catalog Volume. This is separate from the pipeline's source file discovery.

## Setup

1. Run `sql/00_setup.sql` in SQL Editor and create `landing/orders/`.
2. Upload **only** `orders_001.csv` initially.
3. `databricks auth login --host https://dbc-431999de-fcdd.cloud.databricks.com --profile medallion-demo`.
4. `export DATABRICKS_CONFIG_PROFILE=medallion-demo`.
5. `databricks bundle validate -t dev` and `databricks bundle deploy -t dev`.
6. Check the job's **Schedules & Triggers** settings, including **Test connection** to the volume.
7. For a manual baseline if required, run `databricks bundle run dlt_orders_pipeline -t dev`.
8. Upload `orders_002.csv` as a **new file** and check the triggered Job Runs. Do not run a full refresh.
9. Validate with `sql/04_validate.sql`: expected 12 Bronze and 8 Silver rows from both sample files.

File arrival detection may not start instantly. The trigger requires permissions and workspace feature support; Databricks Free Edition has restrictions. If validation or deployment rejects this trigger, temporarily move `resources/file_arrival_job.yml` outside `resources/`, revalidate, and deploy only the pipeline, then run it manually. Do not claim that event automation is working until an automatically triggered job run has succeeded.

Databricks reference: https://docs.databricks.com/aws/en/jobs/file-arrival-triggers
