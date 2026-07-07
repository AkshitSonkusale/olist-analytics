import duckdb, os, re
con = duckdb.connect(':memory:')
D = 'data'

con.execute(f"""
CREATE TABLE customers AS SELECT * FROM read_csv_auto('{D}/olist_customers_dataset.csv');
CREATE TABLE orders AS SELECT * FROM read_csv_auto('{D}/olist_orders_dataset.csv', timestampformat='%Y-%m-%d %H:%M:%S');
CREATE TABLE order_items AS SELECT * FROM read_csv_auto('{D}/olist_order_items_dataset.csv');
CREATE TABLE order_payments AS SELECT * FROM read_csv_auto('{D}/olist_order_payments_dataset.csv');
CREATE TABLE products AS SELECT * FROM read_csv_auto('{D}/olist_products_dataset.csv');
CREATE TABLE sellers AS SELECT * FROM read_csv_auto('{D}/olist_sellers_dataset.csv');
CREATE TABLE category_translation AS SELECT * FROM read_csv_auto('{D}/product_category_name_translation.csv');
""")

# Execute the ACTUAL delivered view SQL (Postgres dialect that is DuckDB-compatible).
for fn in ['sql/02_rfm.sql', 'sql/03_cohort_and_kpis.sql']:
    raw = open(fn).read()
    # remove full-line and trailing -- comments so ';' inside comments can't split statements
    sql = '\n'.join(re.sub(r'--.*$', '', line) for line in raw.splitlines())
    for stmt in [s for s in sql.split(';') if s.strip()]:
        con.execute(stmt)

def show(label, sql):
    print(f"\n=== {label} ===")
    print(con.execute(sql).fetchdf().to_string(index=False))

show("RFM segment distribution", """
SELECT segment, COUNT(*) customers,
       ROUND(100.0*COUNT(*)/SUM(COUNT(*)) OVER(),1) pct_customers,
       ROUND(SUM(monetary),2) revenue,
       ROUND(100.0*SUM(monetary)/SUM(SUM(monetary)) OVER(),1) pct_revenue,
       ROUND(AVG(monetary),2) avg_value
FROM v_rfm GROUP BY 1 ORDER BY revenue DESC;
""")

show("Repeat buyers punch above weight?", """
SELECT CASE WHEN frequency>=2 THEN 'Repeat (>=2)' ELSE 'One-time' END grp,
       COUNT(*) customers,
       ROUND(100.0*COUNT(*)/SUM(COUNT(*)) OVER(),2) pct_cust,
       ROUND(100.0*SUM(monetary)/SUM(SUM(monetary)) OVER(),2) pct_rev,
       ROUND(AVG(monetary),2) avg_ltv
FROM v_rfm GROUP BY 1;
""")

show("Cohort matrix (first 6 cohorts, offsets 0-3)", """
SELECT strftime(cohort_month,'%Y-%m') cohort, month_offset, active_customers
FROM v_cohort WHERE month_offset<=3
  AND cohort_month < DATE '2017-04-01'
ORDER BY cohort_month, month_offset;
""")

show("Monthly KPIs (sample)", """
SELECT strftime(month,'%Y-%m') AS ym, orders, revenue, aov
FROM v_monthly_kpis WHERE month BETWEEN DATE '2017-10-01' AND DATE '2018-03-01'
ORDER BY month;
""")

show("Top 8 categories by revenue", """
SELECT category, revenue, orders FROM v_category_revenue
ORDER BY revenue DESC LIMIT 8;
""")

# ---- Export Power BI-ready CSVs ----
os.makedirs('outputs', exist_ok=True)
exports = {
    'rfm_segments.csv': 'SELECT * FROM v_rfm',
    'cohort_matrix.csv': 'SELECT cohort_month, month_offset, active_customers FROM v_cohort ORDER BY cohort_month, month_offset',
    'monthly_kpis.csv': 'SELECT * FROM v_monthly_kpis ORDER BY month',
    'category_revenue.csv': 'SELECT * FROM v_category_revenue ORDER BY revenue DESC',
    'segment_summary.csv': """SELECT segment, COUNT(*) customers, ROUND(SUM(monetary),2) revenue,
                              ROUND(AVG(monetary),2) avg_value, ROUND(AVG(recency_days),0) avg_recency_days
                              FROM v_rfm GROUP BY 1 ORDER BY revenue DESC""",
}
for fname, sql in exports.items():
    con.execute(f"COPY ({sql}) TO 'outputs/{fname}' (HEADER, DELIMITER ',')")
print("\nExported:", ", ".join(exports))
con.close()
