-- Run these in Databricks SQL editor AFTER pipeline run.
SELECT COUNT(*) AS bronze_count FROM main.dlt_orders_demo.orders_bronze;
SELECT COUNT(*) AS silver_count FROM main.dlt_orders_demo.orders_silver;
SELECT * FROM main.dlt_orders_demo.daily_sales_gold ORDER BY order_date, country;
SELECT order_id, customer_id, amount FROM main.dlt_orders_demo.orders_silver ORDER BY TRY_CAST(order_id AS INT);
