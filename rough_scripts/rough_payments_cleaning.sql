USE ecommerce_dirty;
SHOW FULL COLUMNS FROM raw_payments; # all case insensitive
SHOW TABLE STATUS LIKE 'raw_payments'; # 18000 rows
SELECT * FROM raw_payments;

SET SQL_SAFE_UPDATES = 0;

# cleaning the column payment_method
SELECT DISTINCT payment_method COLLATE utf8mb4_bin FROM raw_payments;
UPDATE raw_payments
SET payment_method = LOWER(TRIM(payment_method));

# approach 01 - hard coded brute force approach 
UPDATE raw_payments
SET payment_method =
CASE 
     WHEN payment_method = 'paypal' THEN 'PayPal'
     WHEN payment_method = 'cryptocurrency' THEN 'Cryptocurrency'
     WHEN payment_method IN ('debit card', 'apple pay') THEN CONCAT(UPPER(SUBSTRING(payment_method, 1, 1)), 
                                                                            SUBSTRING(payment_method, 2, 5), 
			                UPPER(SUBSTRING(payment_method, 7, 1)), 
                                                                            SUBSTRING(payment_method, 8))
     WHEN payment_method IN ('bank transfer', 'gift card') THEN CONCAT(UPPER(SUBSTRING(payment_method, 1, 1)), 
			SUBSTRING(payment_method, 2, 4), 
			UPPER(SUBSTRING(payment_method, 6, 1)), 
			SUBSTRING(payment_method, 7))
     WHEN payment_method IN ('google pay', 'credit card') THEN CONCAT(UPPER(SUBSTRING(payment_method, 1, 1)), 
			              SUBSTRING(payment_method, 2, 6), 
			              UPPER(SUBSTRING(payment_method, 7, 1)), 
			              SUBSTRING(payment_method, 8))
     ELSE payment_method
END;

# approach 2 - more general 
UPDATE raw_payments
SET payment_method =
CASE 
         WHEN payment_method NOT IN ('cryptocurrency', 'paypal') THEN
         CONCAT(
                CONCAT(UPPER(SUBSTRING(SUBSTRING_INDEX(payment_method, ' ', 1), 1, 1)), SUBSTRING(SUBSTRING_INDEX(payment_method, ' ', 1), 2)), 
                ' ',
                CONCAT(UPPER(SUBSTRING(SUBSTRING_INDEX(payment_method, ' ', -1), 1,1)), SUBSTRING(SUBSTRING_INDEX(payment_method, ' ', -1), 2)))
        WHEN payment_method = 'cryptocurrency' THEN 'Cryptocurrency'
        WHEN payment_method = 'paypal' THEN 'PayPal'
        ELSE payment_method
END;

# cleaning the column amounts
UPDATE raw_payments
SET amount = ROUND(ABS(amount), 2);

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

SET SQL_SAFE_UPDATES = 1;
SELECT * FROM raw_payments;