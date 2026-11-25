-- Active: 1795010243191@@127.0.0.1@5432@northwind_elt
create schema if not exists silver;

create view silver.stg_categories as
    select category_id,
    trim(category_name) as category_name,
    trim(description) as description
    from bronze.categories;

create view silver.stg_customers as
    select customer_id,
    trim(customer_name) as customer_name,
    trim(contact_name) as contact_name,
    trim(address) as address,
    trim(city) as city,
    trim(postal_code) as postal_code,
    trim(country) as country
    from bronze.customers;

create view silver.stg_employees as
    select employee_id,
    trim(last_name) as last_name,
    trim(first_name) as first_name,
    birth_date,
    trim(photo) as photo,
    trim(notes) as notes
    from bronze.employees;

create view silver.stg_orders as
    select order_id,
    customer_id,
    employee_id,
    order_date,
    shipper_id
    from bronze.orders;

create view silver.stg_orderdetails as
    select order_detail_id,
    order_id,
    product_id,
    quantity
    from bronze.orderdetails;

create view silver.stg_products as
    select product_id,
    trim(product_name) as product_name,
    supplier_id,
    category_id,
    trim(unit) as unit,
    price
    from bronze.products;

create view silver.stg_shippers as
    select shipper_id,
    trim(shipper_name) as shipper_name,
    trim(phone) as phone
    from bronze.shippers;

create view silver.stg_suppliers as
    select supplier_id,
    trim(supplier_name) as supplier_name,
    trim(contact_name) as contact_name,
    trim(address) as address,
    trim(city) as city,
    trim(postal_code) as postal_code,
    trim(country) as country,
    trim(phone) as phone
    from bronze.suppliers;
