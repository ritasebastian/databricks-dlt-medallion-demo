-- Lakeflow pipeline SQL source
CREATE OR REFRESH STREAMING TABLE orders_silver (
    CONSTRAINT valid_order_id EXPECT (TRY_CAST(order_id AS INT) IS NOT NULL) ON VIOLATION DROP ROW,
    CONSTRAINT valid_customer EXPECT (customer_id IS NOT NULL AND TRIM(customer_id) <> '') ON VIOLATION DROP ROW,
    CONSTRAINT valid_amount EXPECT (amount > 100) ON VIOLATION DROP ROW,
    CONSTRAINT valid_order_date EXPECT (order_date IS NOT NULL) ON VIOLATION DROP ROW
)
COMMENT 'Validated orders above 100 dollars'
AS
SELECT
    order_id, customer_id, order_date, country, amount,
    source_file, ingestion_timestamp
FROM STREAM(orders_bronze);
