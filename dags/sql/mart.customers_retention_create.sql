CREATE TABLE IF NOT EXISTS mart.customer_retention (
    new_customers_count integer,
    returning_customers_count integer,
    refunded_customer_count integer,
    period_name VARCHAR(6) default 'weekly',
    period_id integer not null,
    item_id integer not null,
    new_customers_revenue numeric(14, 2),
    returning_customers_revenue numeric(14, 2),
    customers_refunded integer
);