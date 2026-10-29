# Architecture

```text
orders_001.csv / orders_002.csv
       |
       v
Unity Catalog volume: /Volumes/main/dlt_orders_demo/landing/orders/
       |  Auto Loader read_files(), streaming
       v
orders_bronze (streaming Delta table; raw source attributes)
       |  streaming read + expectations (DROP ROW)
       v
orders_silver (streaming Delta table; amount > 100)
       |  aggregate by order_date and country
       v
daily_sales_gold (materialized view)
```

This is **append-only file ingestion**, not a CDC/SCD demo.

## Capture your own evidence

Place screenshots here after the pipeline succeeds:

- `pipeline-graph.png`
- `silver-expectations.png`
- `bronze-silver-counts.png`
- `gold-after-incremental-update.png`

Do not commit tokens, private workspace URLs containing credentials, or real customer data.
