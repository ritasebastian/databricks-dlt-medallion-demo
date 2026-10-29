-- Lakeflow pipeline SQL source
CREATE OR REFRESH MATERIALIZED VIEW daily_sales_gold
COMMENT 'Daily sales by country'
AS
SELECT
    order_date,
    country,
    COUNT(*) AS total_orders,
    SUM(amount) AS total_sales,
    ROUND(AVG(amount), 2) AS average_order_value
FROM orders_silver
GROUP BY order_date, country;
