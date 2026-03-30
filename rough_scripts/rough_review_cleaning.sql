USE ecommerce_dirty;
SHOW FULL COLUMNS FROM raw_reviews; # all case insensitive
SHOW TABLE STATUS LIKE 'raw_reviews'; # 6014 rows
SELECT @@collation_database;
SELECT @@collation_server;
SELECT * FROM raw_reviews;

SET SQL_SAFE_UPDATES = 0;

# Cleaning the numerical columns
UPDATE raw_reviews
SET helpful_votes = ABS(helpful_votes),
    product_id = ABS(product_id),
    customer_id = ABS(customer_id)
WHERE 
    helpful_votes < 0 
    OR product_id < 0 
    OR customer_id < 0;
    
# Cleaning the column rating
SELECT DISTINCT rating FROM raw_reviews; -- considering the rating out of 10 and people can't give -ve rating
UPDATE raw_reviews
SET rating = ABS(rating)
WHERE rating < 0;

# Cleaning the column review_text
SELECT DISTINCT review_text FROM raw_reviews; -- requires no cleaning. 

# Cleaning the column review_date
SELECT review_date FROM raw_reviews LIMIT 100; 
UPDATE raw_reviews
SET 
review_date = REPLACE(REPLACE(LOWER(TRIM(review_date)), '/', '-'), ' ', '')
WHERE review_date IS NOT NULL; -- normalzing data

ALTER TABLE raw_reviews ADD COLUMN clean_date DATE;
ALTER TABLE raw_reviews ADD COLUMN clean_date1 DATE;

# Appraoch 01 - Totally Brute force over enginered but doesn't fail any case.
/*
Making condition 
1. YYYY-MM-DD -> REGEXP '^[0-9]{4}-[0-9]{2}-[0-9]{2}$' AND SUBSTRING(review_date, 6, 2) < 12. STR_TO_DATE(review_date, '%Y-%m-%d')
2. YYYY-DD-MM -> REGEXP '^[0-9]{4}-[0-9]{2}-[0-9]{2}$' AND SUBSTRING(review_date, 6, 2) > 12. STR_TO_DATE(review_date, '%Y-%d-%m')
3. DD-MM-YYYY -> REGEXP '^[0-9]{2}-[0-9]{2}-[0-9]{4}$' AND SUBSTRING(review_date, 4, 2) < 12. STR_TO_DATE(review_date, '%d-%m-%Y')
4. MM-DD-YYYY -> REGEXP '^[0-9]{2}-[0-9]{2}-[0-9]{4}$' AND SUBSTRING(review_date, 4, 2) > 12. STR_TO_DATE(review_date, '%m-%d-%Y')
5. DD-mmm-YYYY -> REGEXP '^[0-9]{2}-[a-z]{3}-[0-9]{4}$'. STR_TO_DATE(review_date, '%d-%b-%Y')
*/

-- Checking multiple formats
SELECT 
review_date
FROM raw_reviews 
WHERE 
     review_date NOT REGEXP '^[0-9]{2}-[a-z]{3}-[0-9]{4}$' AND 
     review_date NOT REGEXP '^[0-9]{4}-[0-9]{2}-[0-9]{2}$' AND
     review_date NOT REGEXP '^[0-9]{2}-[0-9]{2}-[0-9]{4}$';

UPDATE raw_reviews
SET clean_date1 = 
CASE 
    WHEN review_date REGEXP '^[0-9]{4}-[0-9]{2}-[0-9]{2}$' AND SUBSTRING(review_date, 6, 2) <= 12 THEN STR_TO_DATE(review_date, '%Y-%m-%d')
    WHEN review_date REGEXP '^[0-9]{4}-[0-9]{2}-[0-9]{2}$' AND SUBSTRING(review_date, 6, 2) > 12 THEN STR_TO_DATE(review_date, '%Y-%d-%m')
    WHEN review_date REGEXP '^[0-9]{2}-[0-9]{2}-[0-9]{4}$' AND SUBSTRING(review_date, 4, 2) <= 12 THEN STR_TO_DATE(review_date, '%d-%m-%Y')
    WHEN review_date REGEXP '^[0-9]{2}-[0-9]{2}-[0-9]{4}$' AND SUBSTRING(review_date, 4, 2) > 12 THEN STR_TO_DATE(review_date, '%m-%d-%Y')
    WHEN review_date REGEXP '^[0-9]{2}-[a-z]{3}-[0-9]{4}$' THEN STR_TO_DATE(review_date, '%d-%b-%Y')
    ELSE clean_date1
END;

# Approach 02 - more lighter as the REGEXP is expensive 
UPDATE raw_reviews
SET clean_date = 
CASE 
    WHEN review_date LIKE '____-__-__' AND SUBSTRING(review_date, 6, 2) <= 12 THEN STR_TO_DATE(review_date, '%Y-%m-%d')
    WHEN review_date LIKE '____-__-__' AND SUBSTRING(review_date, 6, 2) > 12 THEN STR_TO_DATE(review_date, '%Y-%d-%m')
    WHEN review_date LIKE '__-__-____' AND SUBSTRING(review_date, 4, 2) <= 12 THEN STR_TO_DATE(review_date, '%d-%m-%Y')
    WHEN review_date LIKE '__-__-____' AND SUBSTRING(review_date, 4, 2) > 12 THEN STR_TO_DATE(review_date, '%m-%d-%Y')
    WHEN review_date LIKE '__-___-____' THEN STR_TO_DATE(review_date, '%d-%b-%Y')
    ELSE clean_date
END;


SELECT review_date FROM raw_reviews WHERE review_date LIKE '__-__-____' ;
/*Not much useful beacause of STR_TO_DATE lenient parser
UPDATE raw_reviews
SET clean_date = COALESCE(
    STR_TO_DATE(review_date, '%Y-%m-%d'),
    STR_TO_DATE(review_date, '%d-%m-%Y'),
    STR_TO_DATE(review_date, '%m-%d-%Y'),
    STR_TO_DATE(review_date, '%Y-%d-%m'),
    STR_TO_DATE(review_date, '%d-%b-%Y')
) WHERE clean_date IS NULL;*/


SELECT review_date, clean_date, clean_date1 FROM raw_reviews;


UPDATE raw_reviews
SET clean_date = NULL;

UPDATE raw_reviews
SET clean_date1 = NULL;

UPDATE raw_reviews
SET review_date2 = NULL 
WHERE review_date2 > current_date(); -- to remove invalid dates
-- NOTE:- Even if we are comparing string value for the month condition, the logic is mae as numerical comparison 

ALTER TABLE raw_reviews DROP COLUMN review_date;
ALTER TABLE raw_reviews RENAME COLUMN review_date2 TO review_date;

SET SQL_SAFE_UPDATES = 1;
SELECT * FROM raw_reviews;