USE ecommerce_dirty;
SHOW FULL COLUMNS FROM raw_reviews; # all case insensitive
SHOW TABLE STATUS LIKE 'raw_reviews'; # 6000 rows
SELECT * FROM raw_reviews;

SET SQL_SAFE_UPDATES = 0;

# Cleaning the numerical columns
UPDATE raw_reviews SET review_id = ABS(review_id) WHERE review_id< 0;
UPDATE raw_reviews SET product_id = ABS(product_id) WHERE product_id < 0;
UPDATE raw_reviews SET customer_id = ABS(customer_id) WHERE customer_id < 0;
UPDATE raw_reviews SET helpful_votes = ABS(helpful_votes) WHERE helpful_votes < 0;
    
# Cleaning the column rating
SELECT DISTINCT rating FROM raw_reviews; -- considering the rating out of 10 and people can't give -ve rating
UPDATE raw_reviews SET rating = ABS(rating) WHERE rating < 0;

# Cleaning the column review_text
SELECT DISTINCT review_text FROM raw_reviews; -- requires no cleaning. 

# Cleaning the column review_date
SELECT review_date FROM raw_reviews LIMIT 100; 
UPDATE raw_reviews
SET 
review_date = REPLACE(REPLACE(LOWER(TRIM(review_date)), '/', '-'), ' ', '')
WHERE review_date IS NOT NULL; -- normalzing data

ALTER TABLE raw_reviews ADD COLUMN clean_date DATE;

UPDATE raw_reviews
SET clean_date = 
CASE 
    WHEN review_date REGEXP '^[0-9]{4}-[0-9]{2}-[0-9]{2}$' AND SUBSTRING(review_date, 6, 2) <= 12 THEN STR_TO_DATE(review_date, '%Y-%m-%d')
    WHEN review_date REGEXP '^[0-9]{4}-[0-9]{2}-[0-9]{2}$' AND SUBSTRING(review_date, 6, 2) > 12 THEN STR_TO_DATE(review_date, '%Y-%d-%m')
    WHEN review_date REGEXP '^[0-9]{2}-[0-9]{2}-[0-9]{4}$' AND SUBSTRING(review_date, 4, 2) <= 12 THEN STR_TO_DATE(review_date, '%d-%m-%Y')
    WHEN review_date REGEXP '^[0-9]{2}-[0-9]{2}-[0-9]{4}$' AND SUBSTRING(review_date, 4, 2) > 12 THEN STR_TO_DATE(review_date, '%m-%d-%Y')
    WHEN review_date REGEXP '^[0-9]{2}-[a-z]{3}-[0-9]{4}$' THEN STR_TO_DATE(review_date, '%d-%b-%Y')
    ELSE clean_date
END;

UPDATE raw_reviews
SET clean_date = NULL
WHERE clean_date > current_date(); -- to remove invalid dates

ALTER TABLE raw_reviews DROP COLUMN review_date;
ALTER TABLE raw_reviews RENAME COLUMN clean_date TO review_date;

SET SQL_SAFE_UPDATES = 1;
SELECT * FROM raw_reviews;