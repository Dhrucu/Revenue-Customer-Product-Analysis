CREATE OR REPLACE VIEW product_report AS
WITH base_sales AS (
    SELECT
        sf.product_key,
        DATE_TRUNC('quarter', sf.order_date)::date AS quarter,
        sf.sales_amount,
        sf.quantity,
        sf.price
    FROM sales_fact sf
    WHERE sf.order_date IS NOT NULL
),

product_base AS (
    SELECT
        p.product_key,
        p.category,
        p.subcategory,
        p.cost
    FROM products p
),

cost_percentiles AS (
    SELECT
        PERCENTILE_CONT(0.25) WITHIN GROUP (ORDER BY cost) AS cost_p25,
        PERCENTILE_CONT(0.75) WITHIN GROUP (ORDER BY cost) AS cost_p75
    FROM products
),

product_cost_tiers AS (
    SELECT
        pb.product_key,
        pb.category,
        pb.subcategory,
        pb.cost,
        CASE
            WHEN pb.cost <= cp.cost_p25 THEN 'low cost'
            WHEN pb.cost >= cp.cost_p75 THEN 'high cost'
            ELSE 'medium cost'
        END AS cost_tier
    FROM product_base pb
    CROSS JOIN cost_percentiles cp
),

category_price_percentiles AS (
    SELECT
        pb.category,
        PERCENTILE_CONT(0.25) WITHIN GROUP (ORDER BY bs.price) AS price_p25,
        PERCENTILE_CONT(0.75) WITHIN GROUP (ORDER BY bs.price) AS price_p75
    FROM base_sales bs
    JOIN product_base pb
        ON bs.product_key = pb.product_key
    GROUP BY
        pb.category
),

sales_with_price_tiers AS (
    SELECT
        bs.product_key,
        bs.quarter,
        bs.sales_amount,
        bs.quantity,
        bs.price,
        pb.category,
        CASE
            WHEN bs.price <= cpp.price_p25 THEN 'low price'
            WHEN bs.price >= cpp.price_p75 THEN 'high price'
            ELSE 'medium price'
        END AS price_tier
    FROM base_sales bs
    JOIN product_base pb
        ON bs.product_key = pb.product_key
    JOIN category_price_percentiles cpp
        ON pb.category = cpp.category
)

SELECT
    pct.category,
    pct.subcategory,
    pct.cost_tier,
    swpt.price_tier,
    swpt.quarter,
    SUM(swpt.sales_amount) AS total_sales,
    SUM(swpt.sales_amount - pct.cost * swpt.quantity) AS total_profit,
    ROUND(
        SUM(swpt.sales_amount - pct.cost * swpt.quantity)::numeric
        / NULLIF(SUM(swpt.sales_amount), 0),
        2
    ) AS margin
FROM sales_with_price_tiers swpt
JOIN product_cost_tiers pct
    ON swpt.product_key = pct.product_key
GROUP BY
    pct.category,
    pct.subcategory,
    pct.cost_tier,
    swpt.price_tier,
    swpt.quarter
ORDER BY
    swpt.quarter,
    total_sales DESC;

SELECT * FROM product_report;
