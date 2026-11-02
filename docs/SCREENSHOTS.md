# Screenshots and evidence

These screenshots were supplied by the project owner and demonstrate the initial run, not the later incremental test.

1. `01_unity_catalog.png`: Catalog `main`, schema `dlt_orders_demo`, three datasets, one landing volume.
2. `02_source_file.png`: `orders_001.csv` in landing/orders.
3. `03_gold_lineage.png`: Gold view lineage with Silver upstream.
4. `04_pipeline_success.png`: Successful initial run: Bronze 8 records, Silver 5 records, Gold 3 aggregated rows.

The pipeline screenshot shows 3 expectations met and 1 unmet (rule-level), not a dropped-record count.

## Still to capture

- Data quality details for Silver expectations.
- SQL query output for Gold totals.
- Incremental update after `orders_002.csv` (expected Bronze 12, Silver 8).
- Successful file-arrival-triggered run (only if trigger is supported and verified).

Review screenshots for sensitive data before making your repository public.
