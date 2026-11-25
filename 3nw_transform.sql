-- Active: 1795010243191@@127.0.0.1@5432@northwind_elt
\set ON_ERROR_STOP ON
\encoding UTF8

create schema if not exists gold;

create table gold.dim_shipper(
    shipper_id INT NOT NULL UNIQUE,
    shipper_name VARCHAR(30) NOT NULL
);

create table gold.dim_employee(
    employee_id INT NOT NULL UNIQUE,
    first_name VARCHAR(30) NOT NULL,
    last_name VARCHAR(30) NOT NULL,
    birth_date DATE
);

create table gold.dim_customer(
    customer_id INT NOT NULL UNIQUE,
    customer_name VARCHAR(50) NOT NULL,
    contact_name VARCHAR(50),
    address VARCHAR(60),
    city VARCHAR(30),
    postal_code VARCHAR(10),
    country VARCHAR(30) NOT NULL
);

create table gold.dim_product(
    product_id INT NOT NULL UNIQUE,
    product_name VARCHAR(50) NOT NULL,
    category_name VARCHAR(50) NOT NULL,
    supplier_name VARCHAR(50) NOT NULL,
    supplier_city VARCHAR(30),
    supplier_country VARCHAR(30) NOT NULL,
    unit VARCHAR(40),
    price NUMERIC(10, 2) NOT NULL
);

create table gold.dim_date(
    date_id INT PRIMARY KEY,
    order_date DATE NOT NULL UNIQUE,
    day INT NOT NULL,
    month INT NOT NULL,
    year INT NOT NULL,
    day_of_week INT NOT NULL,
    day_name VARCHAR(10) NOT NULL,
    week INT NOT NULL,
    month_name VARCHAR(10) NOT NULL,
    quarter INT NOT NULL
);

create table gold.dim_time(
    time_id INT PRIMARY KEY,
    order_time TIME NOT NULL UNIQUE,
    hour INT NOT NULL,
    minute INT NOT NULL,
    second INT NOT NULL,
    time_of_day VARCHAR(10) NOT NULL
);

create table gold.fact_order(
    order_detail_id INT PRIMARY KEY,
    order_id INT NOT NULL,
    customer_id INT NOT NULL REFERENCES gold.dim_customer (customer_id),
    product_id INT NOT NULL REFERENCES gold.dim_product (product_id),
    employee_id INT NOT NULL REFERENCES gold.dim_employee (employee_id),
    shipper_id INT NOT NULL REFERENCES gold.dim_shipper (shipper_id),
    date_id INT NOT NULL REFERENCES gold.dim_date (date_id),
    time_id INT NOT NULL REFERENCES gold.dim_time (time_id),
    quantity INT NOT NULL,
    order_price NUMERIC(12, 2) NOT NULL
);

create index on gold.fact_order (
    customer_id
);
create index on gold.fact_order (
    product_id
);
create index on gold.fact_order (
    employee_id
);
create index on gold.fact_order (
    shipper_id
);
create index on gold.fact_order (
    date_id
);
create index on gold.fact_order (
    time_id
);

-- psql -h localhost -p 5432 -U postgres -d northwind_elt -f 3nw_transform.sql

begin;

truncate gold.fact_order,
gold.dim_customer,
gold.dim_product,
gold.dim_employee,
gold.dim_shipper,
gold.dim_date,
gold.dim_time;

insert into gold.dim_shipper (
    shipper_id,
    shipper_name
)
select s.shipper_id, s.shipper_name
from silver.stg_shippers s order by s.shipper_id;

insert into gold.dim_employee (
    employee_id,
    first_name,
    last_name,
    birth_date
)
select e.employee_id, e.first_name, e.last_name, e.birth_date
from silver.stg_employees e order by e.employee_id;

insert into gold.dim_customer (
    customer_id,
    customer_name,
    contact_name,
    address,
    city,
    postal_code,
    country
)
select c.customer_id, c.customer_name, c.contact_name, c.address, c.city, c.postal_code,
coalesce(nullif(c.country, ''), 'unknown')
from silver.stg_customers c order by c.customer_id;

insert into gold.dim_product (
    product_id,
    product_name,
    category_name,
    supplier_name,
    supplier_city,
    supplier_country,
    unit,
    price
)
select p.product_id, p.product_name, coalesce(cat.category_name, 'unknown'), coalesce(s.supplier_name, 'unknown'),
s.city, coalesce(s.country, 'unknown'), p.unit, p.price
from silver.stg_products p
left outer join silver.stg_categories cat on cat.category_id = p.category_id
left outer join silver.stg_suppliers s on s.supplier_id = p.supplier_id
order by p.product_id;

insert into gold.dim_date (
    date_id,
    order_date,
    day,
    month,
    year,
    day_of_week,
    day_name,
    week,
    month_name,
    quarter
)
select to_char(d, 'YYYYMMDD')::INT, d, extract(day from d)::INT, extract(month from d)::INT, extract(year from d)::INT,
extract(isodow from d)::INT, to_char(d, 'FMDay'), extract(week from d)::INT, to_char(d, 'FMMonth'), extract(quarter from d)::INT
from (select distinct order_date::date as d from silver.stg_orders) x order by 1;

insert into gold.dim_time (
    time_id,
    order_time,
    hour,
    minute,
    second,
    time_of_day
)
select to_char(t, 'HH24MISS')::INT, t, extract(hour from t)::INT, extract(minute from t)::INT, extract(second from t)::INT,
case
    when extract(hour from t) < 6 then 'night'
    when extract(hour from t) < 12 then 'morning'
    when extract(hour from t) < 18 then 'afternoon'
    else 'evening'
end
from (select distinct order_date::time as t from silver.stg_orders) x order by 1;

insert into gold.fact_order (
    order_detail_id,
    order_id,
    customer_id,
    product_id,
    employee_id,
    shipper_id,
    date_id,
    time_id,
    quantity,
    order_price
)
select od.order_detail_id, od.order_id, o.customer_id, od.product_id, o.employee_id, o.shipper_id,
d.date_id, t.time_id, od.quantity, od.quantity * p.price
from silver.stg_orderdetails od
join silver.stg_orders o on o.order_id = od.order_id
join silver.stg_products p on p.product_id = od.product_id
join gold.dim_customer c on c.customer_id = o.customer_id
join gold.dim_product dp on dp.product_id = od.product_id
join gold.dim_employee e on e.employee_id = o.employee_id
join gold.dim_shipper s on s.shipper_id = o.shipper_id
join gold.dim_date d on d.order_date = o.order_date::date
join gold.dim_time t on t.order_time = o.order_date::time
order by od.order_detail_id;

commit;
