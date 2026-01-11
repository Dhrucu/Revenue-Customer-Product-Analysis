CREATE OR REPLACE VIEW customer_report AS
WITH base_query AS (
    SELECT
        sf.order_number,
        sf.order_date,
        sf.sales_amount,
        sf.quantity,
        sf.product_key,
        c.customer_key,
        c.customer_number,
        CONCAT(c.first_name, ' ', c.last_name) AS customer_name,
        EXTRACT(YEAR FROM AGE(CURRENT_DATE, c.birthdate)) AS customer_age
    FROM sales_fact sf
    LEFT JOIN customers c
        ON sf.customer_key = c.customer_key
    WHERE sf.order_date IS NOT NULL
),

customer_aggregation AS (
    SELECT
        customer_key,
        customer_number,
        customer_name,
        customer_age,
        COUNT(DISTINCT order_number) AS total_orders,
        SUM(sales_amount) AS total_sales,
        SUM(quantity) AS total_quantity,
        COUNT(DISTINCT product_key) AS total_products,
        MIN(order_date) AS first_order,
        MAX(order_date) AS last_order,
        (
            EXTRACT(YEAR FROM AGE(MAX(order_date), MIN(order_date))) * 12
          + EXTRACT(MONTH FROM AGE(MAX(order_date), MIN(order_date)))
          + 1
        ) AS active_months
    FROM base_query
    GROUP BY
        customer_key,
        customer_number,
        customer_name,
        customer_age
),

sales_percentiles AS (
    SELECT
        PERCENTILE_CONT(0.80) WITHIN GROUP (ORDER BY total_sales) AS vip_sales_threshold
    FROM customer_aggregation
)

SELECT
    ca.customer_key,
    ca.customer_number,
    ca.customer_name,
    ca.customer_age,
    CASE
        WHEN ca.total_sales >= sp.vip_sales_threshold
             AND ca.active_months >= 12 THEN 'VIP'
        WHEN ca.active_months >= 6 THEN 'REGULAR'
        ELSE 'NEW'
    END AS customer_type,
    ca.active_months,
    ca.total_sales,
    ca.total_quantity,
    ca.last_order,
    EXTRACT(DAY FROM AGE(CURRENT_DATE, ca.last_order)) AS days_since_last_order,
    ROUND(ca.total_sales::numeric / NULLIF(ca.total_orders, 0), 2) AS average_order_value,
    ROUND(
        CASE
            WHEN ca.active_months = 0 THEN ca.total_sales
            ELSE ca.total_sales / ca.active_months
        END,
        2
    ) AS average_monthly_spend
FROM customer_aggregation ca
CROSS JOIN sales_percentiles sp;
