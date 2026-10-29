-- Run in Databricks SQL editor (not inside a Lakeflow pipeline).
CREATE SCHEMA IF NOT EXISTS main.dlt_orders_demo;
CREATE VOLUME IF NOT EXISTS main.dlt_orders_demo.landing;
-- Upload only orders_001.csv to /Volumes/main/dlt_orders_demo/landing/orders/ to start.
