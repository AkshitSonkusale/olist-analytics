-- 03_cohort_and_kpis.sql — retention cohorts + dashboard feed views

-- Acquisition cohorts by first-purchase month; retention across month offsets.
DROP VIEW IF EXISTS v_cohort CASCADE;
CREATE VIEW v_cohort AS
WITH first_purchase AS (
    SELECT c.customer_unique_id,
           DATE_TRUNC('month', MIN(o.order_purchase_timestamp)) AS cohort_month
    FROM orders o
    JOIN customers c ON o.customer_id = c.customer_id
    WHERE o.order_status = 'delivered'
    GROUP BY c.customer_unique_id
),
activity AS (
    SELECT DISTINCT c.customer_unique_id,
           DATE_TRUNC('month', o.order_purchase_timestamp) AS activity_month
    FROM orders o
    JOIN customers c ON o.customer_id = c.customer_id
    WHERE o.order_status = 'delivered'
)
SELECT fp.cohort_month,
       (EXTRACT(YEAR  FROM a.activity_month) - EXTRACT(YEAR  FROM fp.cohort_month)) * 12
     + (EXTRACT(MONTH FROM a.activity_month) - EXTRACT(MONTH FROM fp.cohort_month)) AS month_offset,
       COUNT(DISTINCT fp.customer_unique_id) AS active_customers
FROM first_purchase fp
JOIN activity a ON fp.customer_unique_id = a.customer_unique_id
GROUP BY fp.cohort_month, month_offset;

-- Monthly revenue / orders / AOV
DROP VIEW IF EXISTS v_monthly_kpis CASCADE;
CREATE VIEW v_monthly_kpis AS
SELECT DATE_TRUNC('month', o.order_purchase_timestamp)        AS month,
       COUNT(DISTINCT o.order_id)                             AS orders,
       ROUND(SUM(oi.price + oi.freight_value), 2)             AS revenue,
       ROUND(SUM(oi.price + oi.freight_value)
             / COUNT(DISTINCT o.order_id), 2)                 AS aov
FROM orders o
JOIN order_items oi ON o.order_id = oi.order_id
WHERE o.order_status = 'delivered'
GROUP BY 1;

-- Revenue by product category (English names, product revenue only)
DROP VIEW IF EXISTS v_category_revenue CASCADE;
CREATE VIEW v_category_revenue AS
SELECT COALESCE(t.product_category_name_english, p.product_category_name, 'unknown') AS category,
       ROUND(SUM(oi.price), 2)         AS revenue,
       COUNT(DISTINCT oi.order_id)     AS orders
FROM order_items oi
JOIN orders o   ON oi.order_id = o.order_id AND o.order_status = 'delivered'
JOIN products p ON oi.product_id = p.product_id
LEFT JOIN category_translation t ON p.product_category_name = t.product_category_name
GROUP BY 1;
