-- 02_rfm.sql  — RFM per TRUE customer (customer_unique_id), delivered orders only.
--
-- DATA-DRIVEN DESIGN DECISION:
--   Olist is ~97% one-time buyers, so a textbook Frequency quintile is degenerate
--   (almost every customer has frequency = 1). We therefore:
--     (a) still compute R, F, M quintiles to demonstrate the technique, but
--     (b) drive SEGMENTS off Recency x Monetary for the 97% one-timers, and
--     (c) isolate the rare repeat buyers (frequency >= 2) as their own segment,
--         since in this business they are the genuinely high-value cohort.

DROP VIEW IF EXISTS v_rfm CASCADE;
CREATE VIEW v_rfm AS
WITH order_values AS (
    SELECT o.customer_id, o.order_id, o.order_purchase_timestamp,
           SUM(oi.price + oi.freight_value) AS order_value
    FROM orders o
    JOIN order_items oi ON o.order_id = oi.order_id
    WHERE o.order_status = 'delivered'
    GROUP BY o.customer_id, o.order_id, o.order_purchase_timestamp
),
customer_rfm AS (
    SELECT c.customer_unique_id,
           MAX(ov.order_purchase_timestamp)   AS last_purchase,
           COUNT(DISTINCT ov.order_id)         AS frequency,
           ROUND(SUM(ov.order_value), 2)       AS monetary
    FROM order_values ov
    JOIN customers c ON ov.customer_id = c.customer_id
    GROUP BY c.customer_unique_id
),
snapshot AS (SELECT MAX(last_purchase) + INTERVAL '1 day' AS snap FROM customer_rfm),
scored AS (
    SELECT cr.customer_unique_id,
           (s.snap::date - cr.last_purchase::date)::INT AS recency_days,
           cr.frequency,
           cr.monetary,
           NTILE(5) OVER (ORDER BY cr.last_purchase) AS r,  -- most recent -> 5
           NTILE(5) OVER (ORDER BY cr.frequency)     AS f,
           NTILE(5) OVER (ORDER BY cr.monetary)      AS m
    FROM customer_rfm cr CROSS JOIN snapshot s
)
SELECT customer_unique_id, recency_days, frequency, monetary, r, f, m,
       CASE
           WHEN frequency >= 2            THEN 'Repeat Buyers'
           WHEN r >= 4 AND m >= 4         THEN 'Recent High-Value'
           WHEN r >= 4 AND m <= 2         THEN 'Recent Low-Value'
           WHEN r <= 2 AND m >= 4         THEN 'Lapsed High-Value'
           WHEN r <= 2 AND m <= 2         THEN 'Hibernating'
           ELSE 'Mid-Tier'
       END AS segment
FROM scored;
