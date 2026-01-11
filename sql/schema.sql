DROP DATABASE IF EXISTS "DataWarehouseAnalytics";

CREATE DATABASE "DataWarehouseAnalytics";

CREATE SCHEMA IF NOT EXISTS gold;

CREATE TABLE IF NOT EXISTS gold.dim_customers (
    customer_key      integer,
    customer_id       integer,
    customer_number   varchar(50),
    first_name        varchar(50),
    last_name         varchar(50),
    country           varchar(50),
    marital_status    varchar(50),
    gender            varchar(50),
    birthdate         date,
    create_date       date
);

CREATE TABLE IF NOT EXISTS gold.dim_products (
    product_key     integer,
    product_id      integer,
    product_number  varchar(50),
    product_name    varchar(50),
    category_id     varchar(50),
    category        varchar(50),
    subcategory     varchar(50),
    maintenance     varchar(50),
    cost            integer,
    product_line    varchar(50),
    start_date      date
);

CREATE TABLE IF NOT EXISTS gold.fact_sales (
    order_number   varchar(50),
    product_key    integer,
    customer_key   integer,
    order_date     date,
    shipping_date  date,
    due_date       date,
    sales_amount   integer,
    quantity       smallint,
    price          integer
);

TRUNCATE TABLE gold.dim_customers;
TRUNCATE TABLE gold.dim_products;
TRUNCATE TABLE gold.fact_sales;

ALTER TABLE dim_customers RENAME TO customers;
ALTER TABLE dim_products RENAME TO products;
ALTER TABLE fact_sales RENAME TO sales_fact;
