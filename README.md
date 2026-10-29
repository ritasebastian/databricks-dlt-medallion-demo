# DLT / Lakeflow Orders Demo (SQL)

A complete Bronze → Silver → Gold Lakeflow Spark Declarative Pipelines learning demo for Unity Catalog-enabled Databricks workspaces.

## Requirements
- Workspace supports Lakeflow Pipelines and Unity Catalog.
- `main` catalog exists with permissions to create schema, volume and pipeline outputs.
- Pipeline compute is available (serverless where supported).
- This is a file-arrival demo (append-only orders), not an update/delete CDC pipeline.

## Run steps
1. In a normal Databricks SQL editor, run `sql/00_setup.sql`.
2. In Catalog Explorer, open `main.dlt_orders_demo.landing`, create the `orders` folder, and upload **only** `data/orders_001.csv` into it. The source path should be `/Volumes/main/dlt_orders_demo/landing/orders/orders_001.csv`.
3. Use **New → ETL pipeline** and name it `dlt_orders_pipeline`.
4. Set default catalog `main`, default schema `dlt_orders_demo`, SQL transformation files, and triggered mode. Select supported compute.
5. Add `sql/01_bronze.sql`, `sql/02_silver.sql`, and `sql/03_gold.sql` as three SQL transformation files. Do not add setup or validation SQL to the pipeline.
6. Click **Run pipeline**. Verify the graph and use `sql/04_validate.sql` in a normal Databricks SQL editor.
7. Upload `data/orders_002.csv` to the **same** source folder, with a distinct file name.
8. Click **Run pipeline** again (regular incremental update, **not** Full refresh). Re-run validation.

## Initial expectations
- Bronze: 8 rows.
- Silver: 5 rows (orders 101, 103, 104, 106, 108).
- Gold: 2026-10-28 USA 2 orders / 750; 2026-10-29 India 1 / 300; 2026-10-29 USA 2 / 275.

## After second file
- Bronze: 12 rows.
- Silver: 8 rows (new qualifying orders: 109, 110, 112).
- Gold adds 2026-10-30 India 1 / 200 and 2026-10-30 USA 2 / 575.

## Inspect metrics
In the pipeline UI, select the Silver table, view the pipeline event log/data-quality details, and inspect the `valid_amount` expectation. Invalid rows (amount <=100) were dropped by that expectation. Data quality metrics availability can depend on pipeline configuration.

## Notes
- Bronze deliberately leaves `order_id` as STRING, so malformed IDs can be captured without failing CSV parsing. Silver checks integer castability in its `valid_order_id` expectation, but keeps its order_id string; cast in downstream logic if an integer is needed.
- `TRY_CAST` prevents invalid source date/amount strings from failing ingestion; corresponding expectations exclude invalid values downstream.
- The `main` catalog name and paths are examples; update setup and Bronze SQL if your workspace uses another catalog.
- Do not upload both CSV files before the first run if you want to observe incremental updates.
- CSV order data should be append-only and order IDs unique; for record changes or deletes use CDC/AUTO CDC, not this streaming append-only pattern.
- Compute and feature availability varies, including on Free Edition.
