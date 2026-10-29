-- Lakeflow pipeline SQL source
CREATE OR REFRESH STREAMING TABLE orders_bronze
COMMENT 'Raw orders ingested using Auto Loader'
AS
SELECT
    order_id,
    customer_id,
    TRY_CAST(order_date AS DATE) AS order_date,
    country,
    TRY_CAST(amount AS DECIMAL(10,2)) AS amount,
    _metadata.file_name AS source_file,
    CURRENT_TIMESTAMP() AS ingestion_timestamp
FROM STREAM read_files(
    '/Volumes/main/dlt_orders_demo/landing/orders/',
    format => 'csv',
    header => true,
    schema => '
        order_id STRING,
        customer_id STRING,
        order_date STRING,
        country STRING,
        amount STRING
    '
);
