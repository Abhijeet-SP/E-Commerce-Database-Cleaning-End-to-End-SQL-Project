USE ecommerce_dirty;
SHOW FULL COLUMNS FROM raw_orders; # all case insensitive
SHOW TABLE STATUS LIKE 'raw_orders'; # 20150 rows
SELECT * FROM raw_orders;

SET SQL_SAFE_UPDATES = 0;

# cleaning the column status
SELECT DISTINCT status COLLATE utf8mb4_bin FROM raw_orders;
UPDATE raw_orders SET status = LOWER(TRIM(status)); -- normalzing 

-- spell errors 
UPDATE raw_orders
SET status =
CASE
    WHEN status IN ('procesing', 'processing') THEN 'processing'
    WHEN status IN ('ship', 'shipped') THEN 'shipped'
    WHEN status IN ('deliver', 'deliverd', 'delivered') THEN 'delivered'
    WHEN status IN ('canceld', 'cancelled') THEN 'cancelled'
    ELSE status
END;

# Approach 2 - general one but there are many spell errors 
UPDATE raw_orders
SET status = 
CASE 
    WHEN status LIKE '% %' THEN 
    CONCAT(
           CONCAT(UPPER(SUBSTRING(SUBSTRING_INDEX(status, ' ', 1), 1, 1)), SUBSTRING(SUBSTRING_INDEX(status, ' ', 1), 2)), 
           ' ',
           CONCAT(UPPER(SUBSTRING(SUBSTRING_INDEX(status, ' ', -1), 1,1)), SUBSTRING(SUBSTRING_INDEX(status, ' ', -1), 2)))
    WHEN status NOT LIKE '% %' THEN
    CONCAT( UPPER(SUBSTRING(status, 1, 1)), SUBSTRING(status, 2))
    ELSE status
END;

# cleaning the column shipping_city
SELECT DISTINCT shipping_city COLLATE utf8mb4_bin FROM raw_orders;
UPDATE raw_orders SET shipping_city = LOWER(TRIM(shipping_city)); -- nomrmalized the data 

UPDATE raw_orders
SET shipping_city = 
CASE 
    WHEN shipping_city LIKE '% %' THEN 
    CONCAT(
           CONCAT(UPPER(SUBSTRING(SUBSTRING_INDEX(shipping_city, ' ', 1), 1, 1)), SUBSTRING(SUBSTRING_INDEX(shipping_city, ' ', 1), 2)), 
           ' ',
           CONCAT(UPPER(SUBSTRING(SUBSTRING_INDEX(shipping_city, ' ', -1), 1,1)), SUBSTRING(SUBSTRING_INDEX(shipping_city, ' ', -1), 2)))
    WHEN shipping_city NOT LIKE '% %' THEN
    CONCAT( UPPER(SUBSTRING(shipping_city, 1, 1)), SUBSTRING(shipping_city, 2))
    ELSE shipping_city
END;


# cleaning the column shipping_country
SELECT DISTINCT shipping_country COLLATE utf8mb4_bin FROM raw_orders;
UPDATE raw_orders
SET shipping_country = LOWER(TRIM(shipping_country));

UPDATE raw_orders
SET shipping_country =
    CASE
        WHEN shipping_country NOT IN ('usa','uk') THEN  CONCAT( UPPER(SUBSTRING(shipping_country, 1, 1)), SUBSTRING(shipping_country, 2))
        WHEN shipping_country IN ('usa','uk') THEN UPPER(shipping_country)
        ELSE shipping_country
    END;

# cleaning the columns numeric_columns
UPDATE raw_orders SET total_amount = ROUND(ABS(total_amount), 2);
UPDATE raw_orders SET discount_pct = ROUND(ABS(discount_pct), 2);
UPDATE raw_orders SET order_id = ABS(order_id);
UPDATE raw_orders SET customer_id = ABS(order_id);
UPDATE raw_orders SET employee_id = ABS(order_id);

# cleaning the dates column
SELECT order_date, ship_date, delivery_date FROM raw_payments LIMIT 100; 

-- normalzing data
UPDATE raw_orders SET order_date = REPLACE(REPLACE(LOWER(TRIM(order_date)), '/', '-'), ' ', '') WHERE ship_date IS NOT NULL; 
UPDATE raw_orders SET ship_date = REPLACE(REPLACE(LOWER(TRIM(ship_date)), '/', '-'), ' ', '') WHERE ship_date IS NOT NULL; 
UPDATE raw_orders SET delivery_date = REPLACE(REPLACE(LOWER(TRIM(delivery_date)), '/', '-'), ' ', '') WHERE delivery_date IS NOT NULL; 

ALTER TABLE raw_orders 
ADD COLUMN clean_date_o DATE,
ADD COLUMN clean_date_s DATE,
ADD COLUMN clean_date_d DATE;

UPDATE raw_orders
SET clean_date_o = 
CASE 
    WHEN order_date REGEXP '^[0-9]{4}-[0-9]{2}-[0-9]{2}$' AND SUBSTRING(order_date, 6, 2) <= 12 THEN STR_TO_DATE(order_date, '%Y-%m-%d')
    WHEN order_date REGEXP '^[0-9]{4}-[0-9]{2}-[0-9]{2}$' AND SUBSTRING(order_date, 6, 2) > 12 THEN STR_TO_DATE(order_date, '%Y-%d-%m')
    WHEN order_date REGEXP '^[0-9]{2}-[0-9]{2}-[0-9]{4}$' AND SUBSTRING(order_date, 4, 2) <= 12 THEN STR_TO_DATE(order_date, '%d-%m-%Y')
    WHEN order_date REGEXP '^[0-9]{2}-[0-9]{2}-[0-9]{4}$' AND SUBSTRING(order_date, 4, 2) > 12 THEN STR_TO_DATE(order_date, '%m-%d-%Y')
    WHEN order_date REGEXP '^[0-9]{2}-[a-z]{3}-[0-9]{4}$' THEN STR_TO_DATE(order_date, '%d-%b-%Y')
    ELSE clean_date_o
END;

UPDATE raw_orders
SET clean_date_s = 
CASE 
    WHEN ship_date REGEXP '^[0-9]{4}-[0-9]{2}-[0-9]{2}$' AND SUBSTRING(ship_date, 6, 2) <= 12 THEN STR_TO_DATE(ship_date, '%Y-%m-%d')
    WHEN ship_date REGEXP '^[0-9]{4}-[0-9]{2}-[0-9]{2}$' AND SUBSTRING(ship_date, 6, 2) > 12 THEN STR_TO_DATE(ship_date, '%Y-%d-%m')
    WHEN ship_date REGEXP '^[0-9]{2}-[0-9]{2}-[0-9]{4}$' AND SUBSTRING(ship_date, 4, 2) <= 12 THEN STR_TO_DATE(ship_date, '%d-%m-%Y')
    WHEN ship_date REGEXP '^[0-9]{2}-[0-9]{2}-[0-9]{4}$' AND SUBSTRING(ship_date, 4, 2) > 12 THEN STR_TO_DATE(ship_date, '%m-%d-%Y')
    WHEN ship_date REGEXP '^[0-9]{2}-[a-z]{3}-[0-9]{4}$' THEN STR_TO_DATE(ship_date, '%d-%b-%Y')
    ELSE clean_date_s
END;

UPDATE raw_orders
SET clean_date_d = 
CASE 
    WHEN delivery_date REGEXP '^[0-9]{4}-[0-9]{2}-[0-9]{2}$' AND SUBSTRING(delivery_date, 6, 2) <= 12 THEN STR_TO_DATE(delivery_date, '%Y-%m-%d')
    WHEN delivery_date REGEXP '^[0-9]{4}-[0-9]{2}-[0-9]{2}$' AND SUBSTRING(delivery_date, 6, 2) > 12 THEN STR_TO_DATE(delivery_date, '%Y-%d-%m')
    WHEN delivery_date REGEXP '^[0-9]{2}-[0-9]{2}-[0-9]{4}$' AND SUBSTRING(delivery_date, 4, 2) <= 12 THEN STR_TO_DATE(delivery_date, '%d-%m-%Y')
    WHEN delivery_date REGEXP '^[0-9]{2}-[0-9]{2}-[0-9]{4}$' AND SUBSTRING(delivery_date, 4, 2) > 12 THEN STR_TO_DATE(delivery_date, '%m-%d-%Y')
    WHEN delivery_date REGEXP '^[0-9]{2}-[a-z]{3}-[0-9]{4}$' THEN STR_TO_DATE(delivery_date, '%d-%b-%Y')
    ELSE clean_date_d
END;

SELECT order_date, clean_date_o ,ship_date, clean_date_s ,delivery_date, clean_date_d FROM raw_orders;

UPDATE raw_orders SET clean_date_o = NULL WHERE clean_date_o > current_date();
UPDATE raw_orders SET clean_date_s = NULL WHERE clean_date_s > current_date();
UPDATE raw_orders SET clean_date_d = NULL WHERE clean_date_d > current_date();

ALTER TABLE raw_orders 
DROP COLUMN order_date, 
DROP COLUMN ship_date, 
DROP COLUMN delivery_date;

ALTER TABLE raw_orders 
RENAME COLUMN clean_date_o TO order_date,
RENAME COLUMN clean_date_s TO ship_date,
RENAME COLUMN clean_date_d TO delivery_date;

# cleaning the column shipping_state
SELECT DISTINCT shipping_state, shipping_country COLLATE utf8mb4_bin FROM raw_orders;
UPDATE raw_orders
SET shipping_state =
CASE 

        -- USA
        WHEN shipping_country = 'USA' AND shipping_state = 'NY' THEN 'New York'
        WHEN shipping_country = 'USA' AND shipping_state = 'FL' THEN 'Florida'
        WHEN shipping_country = 'USA' AND shipping_state = 'MN' THEN 'Minnesota'
        WHEN shipping_country = 'USA' AND shipping_state = 'TN' THEN 'Tennessee'
        WHEN shipping_country = 'USA' AND shipping_state = 'TX' THEN 'Texas'
        WHEN shipping_country = 'USA' AND shipping_state = 'GA' THEN 'Georgia'
        WHEN shipping_country = 'USA' AND shipping_state = 'CA' THEN 'California'
        WHEN shipping_country = 'USA' AND shipping_state = 'OR' THEN 'Oregon'
        WHEN shipping_country = 'USA' AND shipping_state = 'AZ' THEN 'Arizona'
        WHEN shipping_country = 'USA' AND shipping_state = 'MA' THEN 'Massachusetts'
        WHEN shipping_country = 'USA' AND shipping_state = 'WA' THEN 'Washington'
        WHEN shipping_country = 'USA' AND shipping_state = 'PA' THEN 'Pennsylvania'
        WHEN shipping_country = 'USA' AND shipping_state = 'CO' THEN 'Colorado'
        WHEN shipping_country = 'USA' AND shipping_state = 'IL' THEN 'Illinois'

        -- Canada
        WHEN shipping_country = 'Canada' AND shipping_state = 'ON' THEN 'Ontario'
        WHEN shipping_country = 'Canada' AND shipping_state = 'QC' THEN 'Quebec'
        WHEN shipping_country = 'Canada' AND shipping_state = 'BC' THEN 'British Columbia'

        -- Australia
        WHEN shipping_country = 'Australia' AND shipping_state = 'VIC' THEN 'Victoria'
        WHEN shipping_country = 'Australia' AND shipping_state = 'NSW' THEN 'New South Wales'

        -- UK
        WHEN shipping_country = 'UK' AND shipping_state = 'England' THEN 'England'

        -- Germany
        WHEN shipping_country = 'Germany' AND shipping_state = 'Berlin' THEN 'Berlin'
        WHEN shipping_country = 'Germany' AND shipping_state = 'Bavaria' THEN 'Bavaria'

        ELSE shipping_state

END;

SET SQL_SAFE_UPDATES = 1;
SELECT * FROM raw_orders;