-- Active: 1795010243191@@127.0.0.1@5432@northwind_elt
--create database northwind_elt;
\set ON_ERROR_STOP ON
\encoding UTF8

create schema if not exists bronze;

create table if not exists bronze.categories(
    category_id INT,
    category_name VARCHAR(50),
    description VARCHAR(200),
    _source_file TEXT DEFAULT 'categories.csv',
    _loaded_at TIMESTAMPTZ DEFAULT now()
);

create table if not exists bronze.customers(
    customer_id INT,
    customer_name VARCHAR(50),
    contact_name VARCHAR(50),
    address VARCHAR(60),
    city VARCHAR(30),
    postal_code VARCHAR(10),
    country VARCHAR(30),
    _source_file TEXT DEFAULT 'customers.csv',
    _loaded_at TIMESTAMPTZ DEFAULT now()
);

create table if not exists bronze.employees(
    employee_id INT,
    last_name VARCHAR(30),
    first_name VARCHAR(30),
    birth_date DATE,
    photo VARCHAR(20),
    notes TEXT,
    _source_file TEXT DEFAULT 'employees.csv',
    _loaded_at TIMESTAMPTZ DEFAULT now()
);

create table if not exists bronze.orders(
    order_id INT,
    customer_id INT,
    employee_id INT,
    order_date TIMESTAMP,
    shipper_id INT,
    _source_file TEXT DEFAULT 'orders.csv',
    _loaded_at TIMESTAMPTZ DEFAULT now()
);

create table if not exists bronze.orderdetails(
    order_detail_id INT,
    order_id INT,
    product_id INT,
    quantity INT,
    _source_file TEXT DEFAULT 'orderdetails.csv',
    _loaded_at TIMESTAMPTZ DEFAULT now()
);

create table if not exists bronze.products(
    product_id INT,
    product_name VARCHAR(50),
    supplier_id INT,
    category_id INT,
    unit VARCHAR(40),
    price NUMERIC(10, 2),
    _source_file TEXT DEFAULT 'products.csv',
    _loaded_at TIMESTAMPTZ DEFAULT now()
);

create table if not exists bronze.shippers(
    shipper_id INT,
    shipper_name VARCHAR(30),
    phone VARCHAR(30),
    _source_file TEXT DEFAULT 'shippers.csv',
    _loaded_at TIMESTAMPTZ DEFAULT now()
);

create table if not exists bronze.suppliers(
    supplier_id INT,
    supplier_name VARCHAR(50),
    contact_name VARCHAR(40),
    address VARCHAR(60),
    city VARCHAR(30),
    postal_code VARCHAR(10),
    country VARCHAR(30),
    phone VARCHAR(30),
    _source_file TEXT DEFAULT 'suppliers.csv',
    _loaded_at TIMESTAMPTZ DEFAULT now()
);

begin;
truncate bronze.categories,
bronze.customers,
bronze.employees,
bronze.orderdetails,
bronze.orders,
bronze.products,
bronze.shippers,
bronze.suppliers;
\copy bronze.categories (category_id, category_name, description) from 'data/categories.csv' with (format csv, header true, delimiter ';');
\copy bronze.customers (customer_id, customer_name, contact_name, address, city, postal_code, country) from 'data/customers.csv' with (format csv, header true, delimiter ';');
\copy bronze.employees (employee_id, last_name, first_name, birth_date, photo, notes) from 'data/employees.csv' with (format csv, header true, delimiter ';');
\copy bronze.orders (order_id, customer_id, employee_id, order_date, shipper_id) from 'data/orders.csv' with (format csv, header true, delimiter ';');
\copy bronze.orderdetails (order_detail_id, order_id, product_id, quantity) from 'data/orderdetails.csv' with (format csv, header true, delimiter ';');
\copy bronze.products (product_id, product_name, supplier_id, category_id, unit, price) from 'data/products.csv' with (format csv, header true, delimiter ';');
\copy bronze.shippers (shipper_id, shipper_name, phone) from 'data/shippers.csv' with (format csv, header true, delimiter ';');
\copy bronze.suppliers (supplier_id, supplier_name, contact_name, address, city, postal_code, country, phone) from 'data/suppliers.csv' with (format csv, header true, delimiter ';');
commit;
