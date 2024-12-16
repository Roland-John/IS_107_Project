-- Step 1: Create Temporary Table to Load CSV Data
DROP TABLE IF EXISTS temp_csv;

CREATE TEMP TABLE temp_csv (
    invoiceno VARCHAR(20),
    stockcode VARCHAR(20),
    description TEXT,
    quantity INTEGER,
    invoicedate TIMESTAMP,
    unitprice NUMERIC(10,2),
    customerid NUMERIC,
    country VARCHAR(100)
);

-- Step 2: Load CSV Data into Temporary Table
COPY temp_csv (invoiceno, stockcode, description, quantity, invoicedate, unitprice, customerid, country)
FROM 'C:\Users\Alicia\Desktop\IS_107_P_C\cleaned_online_retail.csv'
DELIMITER ',' 
CSV HEADER;

-- Step 3: Create Dimension Tables if Not Exist (Example)
-- Create dimcustomer table
CREATE TABLE IF NOT EXISTS public.dimcustomer (
    customer_id serial PRIMARY KEY,
    customer_number INTEGER,
    country VARCHAR(100)
);

-- Create dimproduct table
CREATE TABLE IF NOT EXISTS public.dimproduct (
    product_id serial PRIMARY KEY,
    stock_code VARCHAR(20),
    description TEXT
);

-- Create dimtime table
CREATE TABLE IF NOT EXISTS public.dimtime (
    time_id serial PRIMARY KEY,
    invoice_date TIMESTAMP,
    day INTEGER,
    month INTEGER,
    year INTEGER,
    weekday VARCHAR(20)
);

-- Step 4: Create Fact Table (factsales)
CREATE TABLE IF NOT EXISTS public.factsales (
    sales_id serial PRIMARY KEY,
    invoice_no VARCHAR(20),
    product_id INTEGER REFERENCES public.dimproduct(product_id),
    customer_id INTEGER REFERENCES public.dimcustomer(customer_id),
    time_id INTEGER REFERENCES public.dimtime(time_id),
    quantity INTEGER,
    unit_price NUMERIC(10,2)
);

-- Step 5: Populate Dimension Tables

-- Populate dimcustomer table
INSERT INTO public.dimcustomer (customer_number, country)
SELECT DISTINCT 
    customerid::INTEGER, 
    country
FROM temp_csv
WHERE customerid IS NOT NULL;

-- Populate dimproduct table
INSERT INTO public.dimproduct (stock_code, description)
SELECT DISTINCT 
    stockcode, 
    description
FROM temp_csv
WHERE stockcode IS NOT NULL 
  AND description IS NOT NULL;

-- Populate dimtime table
INSERT INTO public.dimtime (invoice_date, day, month, year, weekday)
SELECT DISTINCT 
    invoicedate,
    EXTRACT(DAY FROM invoicedate) AS day,
    EXTRACT(MONTH FROM invoicedate) AS month,
    EXTRACT(YEAR FROM invoicedate) AS year,
    TO_CHAR(invoicedate, 'Day') AS weekday
FROM temp_csv
WHERE invoicedate IS NOT NULL;

-- Step 6: Populate Fact Table

INSERT INTO public.factsales (invoice_no, product_id, customer_id, time_id, quantity, unit_price)
SELECT 
    tc.invoiceno,
    dp.product_id,
    dc.customer_id,
    dt.time_id,
    tc.quantity,
    tc.unitprice
FROM temp_csv tc
LEFT JOIN public.dimproduct dp ON tc.stockcode = dp.stock_code
LEFT JOIN public.dimcustomer dc ON tc.customerid::INTEGER = dc.customer_number
LEFT JOIN public.dimtime dt ON tc.invoicedate = dt.invoice_date;

-- Optional: Drop the temporary table after loading data
DROP TABLE IF EXISTS temp_csv;
