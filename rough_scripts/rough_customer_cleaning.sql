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
UPDATE raw_customers SET gender = REPLACE(gender, ' ', NULL);
UPDATE raw_customers
SET gender = 
    CASE 
        WHEN UPPER(TRIM(gender)) IN ('MALE', 'M') THEN 'Male'
        WHEN UPPER(TRIM(gender)) IN ('FEMALE', 'F') THEN 'Female'
        WHEN UPPER(TRIM(gender)) = 'PREFER NOT TO SAY' THEN 'Prefer not to say'
        WHEN UPPER(TRIM(gender)) = 'NON-BINARY' THEN 'Non-Binary'
        ELSE NULL
    END;
SET SQL_SAFE_UPDATES = 1;

# Cleaning the column signup_date
-- ISO 8601 standard, is YYYY-MM-DD
-- Deciding to go with DD-MM-YYYY interpretation for any ambigious data
SELECT COUNT(*) AS 'total_count', signup_date FROM raw_customers GROUP BY signup_date ORDER BY total_count DESC; # Count all null values
SELECT * FROM raw_customers WHERE signup_date = '31-Mar-2018';
/*
Dates format 4 types 
1. YYYY-MM-DD    -- no problem for conversion
2. DD-month-YYYY -- safe conversion no problem
3. MM-DD-YYYY    -- considering this format for ambigious data with -XX-, XX>12 
4. DD-MM-YYYY    -- for all other dates
*/
SELECT * FROM raw_customers;

ALTER TABLE raw_customers ADD COLUMN dates2 DATE;
SET SQL_SAFE_UPDATES = 0;
UPDATE raw_customers
SET signup_date = REPLACE(REPLACE(TRIM(signup_date), '/', '-'), ' ', '');

/*
WHEN signup_date = signup_date REGEXP '^[0-9]{4}-[0-9]{2}-[0-9]{2}$' AND SUBSTRING(signup_date, 6,7) > 12 THEN STR_TO_DATE(signup_date, '%Y-%d-%m')
WHEN signup_date = signup_date REGEXP '^[0-9]{2}-[0-9]{2}-[0-9]{4}$' AND SUBSTRING(signup_date, 4,5) < 12 THEN STR_TO_DATE(signup_date, '%d-%m-%Y')
WHEN signup_date = signup_date REGEXP '^[0-9]{2}-[0-9]{2}-[0-9]{4}$' AND SUBSTRING(signup_date, 4,5) > 12 THEN STR_TO_DATE(signup_date, '%m-%d-%y')
*/

UPDATE raw_customers
SET dates2 = 
CASE 
    WHEN signup_date = signup_date REGEXP '^[0-9]{4}-[0-9]{2}-[0-9]{2}$' AND SUBSTRING(signup_date, 6,7) < 12 THEN STR_TO_DATE(signup_date, '%Y-%m-%d') = dates2
    ELSE dates2
END;
ALTER TABLE raw_customers DROP COLUMN dates;
ALTER TABLE raw_customers DROP COLUMN dates2;

SELECT 
TRIM(signup_date) AS dates,
REPLACE(REPLACE(TRIM(signup_date), '/', '-'), ' ', '')
FROM raw_customers
WHERE REPLACE(REPLACE(TRIM(signup_date), '/', '-'), ' ', '') REGEXP '^[0-9]{4}-[0-9]{2}-[0-9]{2}$';

SELECT 
STR_TO_DATE(t.Final_dates, '%m-%d-%Y'),
t.Final_dates
FROM
    (SELECT 
     TRIM(signup_date) AS dates,
     REPLACE(REPLACE(TRIM(signup_date), '/', '-'), ' ', '') AS Final_dates
     FROM raw_customers
     WHERE 
          REPLACE(REPLACE(TRIM(signup_date), '/', '-'), ' ', '') REGEXP '^[0-9]{2}-[0-9]{2}-[0-9]{4}$' 
          AND 
          SUBSTRING(REPLACE(REPLACE(TRIM(signup_date), '/', '-'), ' ', ''), 4,5) > 12) AS t;

SELECT 
     TRIM(signup_date) AS dates,
     REPLACE(REPLACE(TRIM(signup_date), '/', '-'), ' ', '') AS Final_dates
     FROM raw_customers
     WHERE 
          REPLACE(REPLACE(TRIM(signup_date), '/', '-'), ' ', '') REGEXP '^[0-9]{2}-[0-9]{2}-[0-9]{4}$' 
          AND 
          SUBSTRING(REPLACE(REPLACE(TRIM(signup_date), '/', '-'), ' ', ''), 4,5) > 12;
SELECT * FROM raw_customers;


# Cleaning the column loyalty_tier
SELECT COUNT(*) AS 'total_count', loyalty_tier FROM raw_customers GROUP BY loyalty_tier ORDER BY total_count; -- Count all null values
SET SQL_SAFE_UPDATES = 0;
UPDATE raw_customers
SET loyalty_tier = 
    CASE 
        WHEN UPPER(TRIM(loyalty_tier)) IN ('PLATINUM', 'PLATIMUM') THEN 'Platinum'
        WHEN UPPER(TRIM(loyalty_tier)) = 'DIAMOND' THEN 'Diamond'
        WHEN UPPER(TRIM(loyalty_tier)) = 'GOLD' THEN 'Gold'
        WHEN UPPER(TRIM(loyalty_tier)) = 'SILVER' THEN 'Silver'
        WHEN UPPER(TRIM(loyalty_tier)) = 'BRONZE' THEN 'Bronze'
        ELSE NULL
    END;
SET SQL_SAFE_UPDATES = 1;
                    
# Clenaing the column referral_source 
SELECT COUNT(*) AS 'total_count', referral_source FROM raw_customers GROUP BY referral_source ORDER BY total_count; 
# Requires no cleaning


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

# cleaning the column city
SELECT COUNT(*) AS 'total_count', state FROM raw_customers GROUP BY state ORDER BY total_count;
UPDATE raw_customers
SET state = 
    CASE 
        -- USA
        WHEN country = 'USA' AND state = 'MN' THEN 'Minnesota'
        WHEN country = 'USA' AND state = 'OR' THEN 'Oregon'
        WHEN country = 'USA' AND state = 'MA' THEN 'Massachusetts'
        WHEN country = 'USA' AND state = 'FL' THEN 'Florida'
        WHEN country = 'USA' AND state = 'IL' THEN 'Illinois'
        WHEN country = 'USA' AND state = 'AZ' THEN 'Arizona'
        WHEN country = 'USA' AND state = 'GA' THEN 'Georgia'
        WHEN country = 'USA' AND state = 'PA' THEN 'Pennsylvania'
        WHEN country = 'USA' AND state = 'CO' THEN 'Colorado'
        WHEN country = 'USA' AND state = 'TN' THEN 'Tennessee'

        -- Canada
        WHEN country = 'Canada' AND state = 'ON' THEN 'Ontario'
        WHEN country = 'Canada' AND state = 'QC' THEN 'Quebec'
        WHEN country = 'Canada' AND state = 'BC' THEN 'British Columbia'

        -- Australia
        WHEN country = 'Australia' AND state = 'NSW' THEN 'New South Wales'
        WHEN country = 'Australia' AND state = 'VIC' THEN 'Victoria'

        -- Germany
        WHEN country = 'Germany' AND state = 'Bavaria' THEN 'Bavaria'
        WHEN country = 'Germany' AND state = 'Berlin' THEN 'Berlin'

        -- UK
        WHEN country = 'UK' AND state = 'England' THEN 'England'

        ELSE state
    END;
SET SQL_SAFE_UPDATES = 1;

# Cleaning the column state
SELECT DISTINCT state COLLATE utf8mb4_bin FROM raw_customers;

DROP TABLE raw_customers;
