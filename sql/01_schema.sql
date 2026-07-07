-- Olist Retail Analytics — PostgreSQL schema
-- Grain notes:
--   customers.customer_id       -> one row PER ORDER (not a person)
--   customers.customer_unique_id-> the true customer identity (join through this)

DROP TABLE IF EXISTS order_reviews, order_payments, order_items, orders,
                     products, sellers, customers, category_translation CASCADE;

CREATE TABLE customers (
    customer_id              TEXT PRIMARY KEY,
    customer_unique_id       TEXT NOT NULL,
    customer_zip_code_prefix TEXT,
    customer_city            TEXT,
    customer_state           TEXT
);

CREATE TABLE orders (
    order_id                      TEXT PRIMARY KEY,
    customer_id                   TEXT REFERENCES customers(customer_id),
    order_status                  TEXT,
    order_purchase_timestamp      TIMESTAMP,
    order_approved_at             TIMESTAMP,
    order_delivered_carrier_date  TIMESTAMP,
    order_delivered_customer_date TIMESTAMP,
    order_estimated_delivery_date TIMESTAMP
);

CREATE TABLE order_items (
    order_id           TEXT REFERENCES orders(order_id),
    order_item_id      INT,
    product_id         TEXT,
    seller_id          TEXT,
    shipping_limit_date TIMESTAMP,
    price              NUMERIC(10,2),
    freight_value      NUMERIC(10,2),
    PRIMARY KEY (order_id, order_item_id)
);

CREATE TABLE order_payments (
    order_id           TEXT,
    payment_sequential INT,
    payment_type       TEXT,
    payment_installments INT,
    payment_value      NUMERIC(10,2)
);

CREATE TABLE products (
    product_id           TEXT PRIMARY KEY,
    product_category_name TEXT,
    product_name_lenght   INT,
    product_description_lenght INT,
    product_photos_qty    INT,
    product_weight_g      INT,
    product_length_cm     INT,
    product_height_cm     INT,
    product_width_cm      INT
);

CREATE TABLE sellers (
    seller_id              TEXT PRIMARY KEY,
    seller_zip_code_prefix TEXT,
    seller_city            TEXT,
    seller_state           TEXT
);

CREATE TABLE category_translation (
    product_category_name         TEXT PRIMARY KEY,
    product_category_name_english TEXT
);

CREATE INDEX idx_orders_customer ON orders(customer_id);
CREATE INDEX idx_orders_purchase ON orders(order_purchase_timestamp);
CREATE INDEX idx_items_order      ON order_items(order_id);
CREATE INDEX idx_items_product    ON order_items(product_id);
