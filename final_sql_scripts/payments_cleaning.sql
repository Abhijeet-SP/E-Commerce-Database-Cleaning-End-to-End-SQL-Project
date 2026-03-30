USE ecommerce_dirty;
SHOW FULL COLUMNS FROM raw_payments; # all case insensitive
SHOW TABLE STATUS LIKE 'raw_payments'; # 17320 rows
SELECT * FROM raw_payments;

SET SQL_SAFE_UPDATES = 0;

# cleaning the column payment_method
SELECT DISTINCT payment_method COLLATE utf8mb4_bin FROM raw_payments;
UPDATE raw_payments
SET payment_method = LOWER(TRIM(payment_method));

UPDATE raw_payments
SET payment_method =
CASE 
         WHEN payment_method LIKE '% %' THEN
         CONCAT(
                CONCAT(UPPER(SUBSTRING(SUBSTRING_INDEX(payment_method, ' ', 1), 1, 1)), SUBSTRING(SUBSTRING_INDEX(payment_method, ' ', 1), 2)), 
                ' ',
                CONCAT(UPPER(SUBSTRING(SUBSTRING_INDEX(payment_method, ' ', -1), 1,1)), SUBSTRING(SUBSTRING_INDEX(payment_method, ' ', -1), 2)))
        WHEN payment_method LIKE '%%' THEN
        CONCAT( UPPER(SUBSTRING(payment_method, 1, 1)), SUBSTRING(payment_method, 2))
        ELSE payment_method
END;

# cleaning the column amounts
UPDATE raw_payments SET amount = ROUND(ABS(amount), 2);

# cleaning the column status
SELECT DISTINCT status COLLATE utf8mb4_bin FROM raw_payments;
UPDATE raw_payments
SET status = CONCAT(UPPER(SUBSTRING(TRIM(status), 1, 1)), LOWER(SUBSTRING(TRIM(status), 2)));

# cleaning the column transaction_ref
SELECT 
transaction_ref,
LENGTH(transaction_ref)
FROM raw_payments
WHERE LENGTH(transaction_ref) > 12 OR LENGTH(transaction_ref) < 12
ORDER BY LENGTH(transaction_ref) DESC;

-- all transction_ref are of length 12
-- just to be safe 
UPDATE raw_payments
SET transaction_ref = UPPER(TRIM(transaction_ref));

# cleaning the column payment_date
SELECT payment_date FROM raw_payments LIMIT 100; 

UPDATE raw_payments
SET payment_date = REPLACE(REPLACE(LOWER(TRIM(payment_date)), '/', '-'), ' ', '')
WHERE payment_date IS NOT NULL; -- normalzing data

ALTER TABLE raw_payments ADD COLUMN clean_date DATE;

UPDATE raw_payments
SET clean_date = 
CASE 
    WHEN payment_date REGEXP '^[0-9]{4}-[0-9]{2}-[0-9]{2}$' AND SUBSTRING(payment_date, 6, 2) <= 12 THEN STR_TO_DATE(payment_date, '%Y-%m-%d')
    WHEN payment_date REGEXP '^[0-9]{4}-[0-9]{2}-[0-9]{2}$' AND SUBSTRING(payment_date, 6, 2) > 12 THEN STR_TO_DATE(payment_date, '%Y-%d-%m')
    WHEN payment_date REGEXP '^[0-9]{2}-[0-9]{2}-[0-9]{4}$' AND SUBSTRING(payment_date, 4, 2) <= 12 THEN STR_TO_DATE(payment_date, '%d-%m-%Y')
    WHEN payment_date REGEXP '^[0-9]{2}-[0-9]{2}-[0-9]{4}$' AND SUBSTRING(payment_date, 4, 2) > 12 THEN STR_TO_DATE(payment_date, '%m-%d-%Y')
    WHEN payment_date REGEXP '^[0-9]{2}-[a-z]{3}-[0-9]{4}$' THEN STR_TO_DATE(payment_date, '%d-%b-%Y')
    ELSE clean_date
END;

UPDATE raw_payments 
SET clean_date = NULL
WHERE clean_date > current_date();

SELECT clean_date, payment_date FROM raw_payments;

ALTER TABLE raw_payments DROP COLUMN payment_date;
ALTER TABLE raw_payments RENAME COLUMN clean_date TO payment_date;

SET SQL_SAFE_UPDATES = 1;
SELECT * FROM raw_payments;