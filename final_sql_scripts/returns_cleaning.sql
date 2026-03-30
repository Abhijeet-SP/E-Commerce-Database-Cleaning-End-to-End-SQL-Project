USE ecommerce_dirty;
SHOW FULL COLUMNS FROM raw_returns; # all case insensitive
SHOW TABLE STATUS LIKE 'raw_returns'; # 2000 rows
SELECT * FROM raw_returns;

SET SQL_SAFE_UPDATES = 0;

# Cleaning the numerical columns
UPDATE raw_returns SET refund_amount = ROUND(ABS(refund_amount), 2) WHERE refund_amount < 0;
UPDATE raw_returns SET order_id = ABS(order_id) WHERE order_id < 0;
UPDATE raw_returns SET item_id = ABS(item_id) WHERE item_id < 0;
    
# Cleaning the column status
SELECT DISTINCT status COLLATE utf8mb4_bin FROM raw_returns; 
UPDATE raw_returns SET status = LOWER(TRIM(status)); -- nomralised the data
UPDATE raw_returns SET status = CONCAT(UPPER(SUBSTRING(status, 1, 1)), SUBSTRING(status, 2)); 
 
# Cleaning the column reason
SELECT reason COLLATE utf8mb4_bin FROM raw_returns; -- requires no cleaning

# Cleaning the column return_date
SELECT return_date FROM raw_returns LIMIT 100; 

UPDATE raw_returns
SET 
return_date = REPLACE(REPLACE(LOWER(TRIM(return_date)), '/', '-'), ' ', '')
WHERE return_date IS NOT NULL; -- normalzing data

ALTER TABLE raw_returns ADD COLUMN clean_date DATE;

UPDATE raw_returns
SET clean_date = 
CASE 
    WHEN return_date REGEXP '^[0-9]{4}-[0-9]{2}-[0-9]{2}$' AND SUBSTRING(return_date, 6, 2) <= 12 THEN STR_TO_DATE(return_date, '%Y-%m-%d')
    WHEN return_date REGEXP '^[0-9]{4}-[0-9]{2}-[0-9]{2}$' AND SUBSTRING(return_date, 6, 2) > 12 THEN STR_TO_DATE(return_date, '%Y-%d-%m')
    WHEN return_date REGEXP '^[0-9]{2}-[0-9]{2}-[0-9]{4}$' AND SUBSTRING(return_date, 4, 2) <= 12 THEN STR_TO_DATE(return_date, '%d-%m-%Y')
    WHEN return_date REGEXP '^[0-9]{2}-[0-9]{2}-[0-9]{4}$' AND SUBSTRING(return_date, 4, 2) > 12 THEN STR_TO_DATE(return_date, '%m-%d-%Y')
    WHEN return_date REGEXP '^[0-9]{2}-[a-z]{3}-[0-9]{4}$' THEN STR_TO_DATE(return_date, '%d-%b-%Y')
    ELSE clean_date
END;

UPDATE raw_returns
SET clean_date = NULL 
WHERE clean_date > current_date();

ALTER TABLE raw_returns DROP COLUMN return_date;
ALTER TABLE raw_returns RENAME COLUMN clean_date TO return_date;

SET SQL_SAFE_UPDATES = 1;
SELECT * FROM raw_returns;