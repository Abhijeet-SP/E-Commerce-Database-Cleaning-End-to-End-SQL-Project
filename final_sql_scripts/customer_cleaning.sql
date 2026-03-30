USE ecommerce_dirty;
SHOW FULL COLUMNS FROM raw_customers; # all case insensitive
SHOW TABLE STATUS LIKE 'raw_customers'; # 5200 rows
SELECT * FROM raw_customers;

SET SQL_SAFE_UPDATES = 0;

# Cleanning all the numeric column 
UPDATE raw_customers 
SET 
customer_id = ABS(customer_id),
age = ABS(age); 

# Cleaning the column full_name
UPDATE raw_customers 
SET full_name = TRIM(LOWER(full_name));

UPDATE raw_customers
SET full_name = 
CONCAT(
       CONCAT(UPPER(SUBSTRING(SUBSTRING_INDEX(full_name, ' ', 1), 1, 1)), LOWER(SUBSTRING(SUBSTRING_INDEX(full_name, ' ', 1), 2))),
       ' ',
       CONCAT(UPPER(SUBSTRING(SUBSTRING_INDEX(full_name, ' ', -1), 1, 1)), LOWER(SUBSTRING(SUBSTRING_INDEX(full_name, ' ', -1), 2))));

UPDATE raw_customers
SET full_name = REPLACE(full_name, ',', '');

# Cleaning the column email
UPDATE raw_customers
SET email = LOWER(TRIM(email));

# Cleaning the column phone 
-- using the E.164 international format (e.g., +15551234567) (+[country_code][phone_number])
SELECT phone, LENGTH(phone) FROM raw_customers WHERE LENGTH(phone) < 10 or LENGTH(phone) > 15; -- no data entry discrepency
UPDATE raw_customers
SET phone = CONCAT('+', REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(TRIM(phone), '(', ')'), ')','+'), '+', '-'), '-', ' '), ' ', ''));

# Clenaing the column age
# Considering the age bracket b/w 10 to 100. 
SELECT DISTINCT country COLLATE utf8mb4_bin FROM raw_customers;

SELECT COUNT(*) AS 'total_count', age FROM raw_customers GROUP BY age ORDER BY total_count;
SELECT * FROM raw_customers WHERE age IS NULL;
DELETE FROM raw_customers WHERE age NOT BETWEEN 10 and 100;

# Clenaing the column gender
SELECT DISTINCT gender COLLATE utf8mb4_bin FROM raw_customers;
SELECT COUNT(*) AS 'total_count', gender FROM raw_customers GROUP BY gender ORDER BY total_count; 

UPDATE raw_customers SET gender = LOWER(TRIM(gender));
UPDATE raw_customers SET gender = REPLACE(gender, ' ', NULL) WHERE gender = ' ';

UPDATE raw_customers
SET gender = 
    CASE 
        WHEN gender IN ('male', 'm') THEN 'Male'
        WHEN gender IN ('female', 'f') THEN 'Female'
        WHEN gender = 'prefer not to say' THEN 'Prefer not to say'
        WHEN gender = 'non-binary' THEN 'Non-Binary'
        ELSE NULL
    END;
    
# Clenaing the column referral_source 
SELECT COUNT(*) AS 'total_count', referral_source FROM raw_customers GROUP BY referral_source ORDER BY total_count; 
# Requires no cleaning

# Cleaning the column loyalty_tier
SELECT DISTINCT loyalty_tier COLLATE utf8mb4_bin FROM raw_customers;

UPDATE raw_customers
SET loyalty_tier = UPPER(TRIM(loyalty_tier));

UPDATE raw_customers
SET loyalty_tier = 
    CASE 
        WHEN loyalty_tier IN ('PLATINUM', 'PLATIMUM') THEN 'Platinum'
        WHEN loyalty_tier = 'DIAMOND' THEN 'Diamond'
        WHEN loyalty_tier = 'GOLD' THEN 'Gold'
        WHEN loyalty_tier = 'SILVER' THEN 'Silver'
        WHEN loyalty_tier = 'BRONZE' THEN 'Bronze'
        ELSE NULL
    END;

# cleaning the column signup_date
SELECT signup_date FROM raw_customers LIMIT 100; 

UPDATE raw_customers
SET signup_date = REPLACE(REPLACE(LOWER(TRIM(signup_date)), '/', '-'), ' ', '')
WHERE signup_date IS NOT NULL; -- normalzing data

ALTER TABLE raw_customers ADD COLUMN clean_date DATE;

UPDATE raw_customers
SET clean_date = 
CASE 
    WHEN signup_date REGEXP '^[0-9]{4}-[0-9]{2}-[0-9]{2}$' AND SUBSTRING(signup_date, 6, 2) <= 12 THEN STR_TO_DATE(signup_date, '%Y-%m-%d')
    WHEN signup_date REGEXP '^[0-9]{4}-[0-9]{2}-[0-9]{2}$' AND SUBSTRING(signup_date, 6, 2) > 12 THEN STR_TO_DATE(signup_date, '%Y-%d-%m')
    WHEN signup_date REGEXP '^[0-9]{2}-[0-9]{2}-[0-9]{4}$' AND SUBSTRING(signup_date, 4, 2) <= 12 THEN STR_TO_DATE(signup_date, '%d-%m-%Y')
    WHEN signup_date REGEXP '^[0-9]{2}-[0-9]{2}-[0-9]{4}$' AND SUBSTRING(signup_date, 4, 2) > 12 THEN STR_TO_DATE(signup_date, '%m-%d-%Y')
    WHEN signup_date REGEXP '^[0-9]{2}-[a-z]{3}-[0-9]{4}$' THEN STR_TO_DATE(signup_date, '%d-%b-%Y')
    ELSE clean_date
END;

UPDATE raw_customers
SET clean_date = NULL
WHERE clean_date > current_date();

SELECT clean_date, signup_date FROM raw_customers;

ALTER TABLE raw_customers DROP COLUMN signup_date;
ALTER TABLE raw_customers RENAME COLUMN clean_date TO signup_date;


SELECT DISTINCT state COLLATE utf8mb4_bin FROM raw_customers;
SELECT DISTINCT city COLLATE utf8mb4_bin FROM raw_customers;
SELECT * FROM raw_customers;

# Cleaning the column country
SELECT DISTINCT country COLLATE utf8mb4_bin FROM raw_customers;
UPDATE raw_customers SET country = LOWER(TRIM(country));

UPDATE raw_customers
SET country =
    CASE
        WHEN country NOT IN ('usa','uk') THEN  CONCAT( UPPER(SUBSTRING(country, 1, 1)), SUBSTRING(country, 2))
        WHEN country IN ('usa','uk') THEN UPPER(country)
        ELSE country
    END;

# Cleaning the column city
SELECT DISTINCT city COLLATE utf8mb4_bin FROM raw_customers;
UPDATE raw_customers SET city = LOWER(TRIM(city));
UPDATE raw_customers
SET city =
CASE 
         WHEN city LIKE '% %' THEN
         CONCAT(
                CONCAT(UPPER(SUBSTRING(SUBSTRING_INDEX(city, ' ', 1), 1, 1)), SUBSTRING(SUBSTRING_INDEX(city, ' ', 1), 2)), 
                ' ',
                CONCAT(UPPER(SUBSTRING(SUBSTRING_INDEX(city, ' ', -1), 1,1)), SUBSTRING(SUBSTRING_INDEX(city, ' ', -1), 2)))
        WHEN city LIKE '%%' THEN
        CONCAT( UPPER(SUBSTRING(city, 1, 1)), SUBSTRING(city, 2))
        ELSE city
END;

SELECT DISTINCT city, state, country COLLATE utf8mb4_bin FROM raw_customers;

# Cleaning the column state
UPDATE raw_customers
SET state =
CASE

    -- USA
    WHEN country = 'USA' AND state = 'NY' THEN 'New York'
    WHEN country = 'USA' AND state = 'FL' THEN 'Florida'
    WHEN country = 'USA' AND state = 'MN' THEN 'Minnesota'
    WHEN country = 'USA' AND state = 'TN' THEN 'Tennessee'
    WHEN country = 'USA' AND state = 'TX' THEN 'Texas'
    WHEN country = 'USA' AND state = 'GA' THEN 'Georgia'
    WHEN country = 'USA' AND state = 'CA' THEN 'California'
    WHEN country = 'USA' AND state = 'OR' THEN 'Oregon'
    WHEN country = 'USA' AND state = 'AZ' THEN 'Arizona'
    WHEN country = 'USA' AND state = 'MA' THEN 'Massachusetts'
    WHEN country = 'USA' AND state = 'WA' THEN 'Washington'
    WHEN country = 'USA' AND state = 'PA' THEN 'Pennsylvania'
    WHEN country = 'USA' AND state = 'CO' THEN 'Colorado'
    WHEN country = 'USA' AND state = 'IL' THEN 'Illinois'

    -- Canada
    WHEN country = 'Canada' AND state = 'ON' THEN 'Ontario'
    WHEN country = 'Canada' AND state = 'QC' THEN 'Quebec'
    WHEN country = 'Canada' AND state = 'BC' THEN 'British Columbia'

    -- Australia
    WHEN country = 'Australia' AND state = 'VIC' THEN 'Victoria'
    WHEN country = 'Australia' AND state = 'NSW' THEN 'New South Wales'

    -- Already full → keep
    ELSE state

END;

SET SQL_SAFE_UPDATES = 1;
SELECT * FROM raw_customers;