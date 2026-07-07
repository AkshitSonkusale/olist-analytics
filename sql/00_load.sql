-- 00_load.sql — load raw Kaggle CSVs into the schema.
-- Run from the repo root with:   psql "<your_connection_string>" -f sql/00_load.sql
-- Assumes data/ contains the original Olist CSVs (see README: download from Kaggle).

\copy customers            FROM 'data/olist_customers_dataset.csv'          WITH (FORMAT csv, HEADER true);
\copy orders               FROM 'data/olist_orders_dataset.csv'             WITH (FORMAT csv, HEADER true);
\copy order_items          FROM 'data/olist_order_items_dataset.csv'        WITH (FORMAT csv, HEADER true);
\copy order_payments       FROM 'data/olist_order_payments_dataset.csv'     WITH (FORMAT csv, HEADER true);
\copy products             FROM 'data/olist_products_dataset.csv'           WITH (FORMAT csv, HEADER true);
\copy sellers              FROM 'data/olist_sellers_dataset.csv'            WITH (FORMAT csv, HEADER true);
\copy category_translation FROM 'data/product_category_name_translation.csv' WITH (FORMAT csv, HEADER true);

-- order_reviews is not required by the current views; load it if you extend the project:
-- CREATE TABLE order_reviews (...);  \copy order_reviews FROM 'data/olist_order_reviews_dataset.csv' WITH (FORMAT csv, HEADER true);

ANALYZE;
