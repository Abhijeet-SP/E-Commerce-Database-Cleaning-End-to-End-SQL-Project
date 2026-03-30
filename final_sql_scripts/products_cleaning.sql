USE ecommerce_dirty;
SHOW FULL COLUMNS FROM raw_products; # all case insensitive
SHOW TABLE STATUS LIKE 'raw_products'; # 496 rows
SELECT * FROM raw_products;

SET SQL_SAFE_UPDATES = 0;

# Cleaning the column Catgeory
SELECT DISTINCT category COLLATE utf8mb4_bin FROM raw_products;
UPDATE raw_products
SET category = LOWER(TRIM(category)); -- nomralised the data 

UPDATE raw_products
SET category = 
CASE 
     WHEN category NOT LIKE '%&%' THEN 
          CONCAT(UPPER(SUBSTRING(category, 1, 1)), LOWER(SUBSTRING(category, 2)))
     WHEN category LIKE '%&%' THEN
     CONCAT(
           CONCAT(UPPER(SUBSTRING(SUBSTRING_INDEX(category, '&', 1), 1, 1)), SUBSTRING(SUBSTRING_INDEX(category, '&', 1), 2)), 
           '& ',
           CONCAT(UPPER(SUBSTRING(SUBSTRING_INDEX(category, '&', -1), 2, 1)), SUBSTRING(SUBSTRING_INDEX(category, '&', -1), 3)))
     ELSE category
END;

# Cleaning the column sub_catgeory
SELECT DISTINCT sub_category COLLATE utf8mb4_bin FROM raw_products;
UPDATE raw_products
SET sub_category = LOWER(TRIM(sub_category)); -- nomralised the data 

SELECT DISTINCT sub_category 
FROM raw_products 
WHERE 
     sub_category REGEXP '&' 
     OR sub_category REGEXP ' ' 
     OR sub_category REGEXP '-' 
ORDER BY sub_category;

UPDATE raw_products
SET sub_category = 
CASE 
     WHEN sub_category LIKE '%&%' THEN 
     CONCAT(
           CONCAT(UPPER(SUBSTRING(SUBSTRING_INDEX(sub_category, '&', 1), 1, 1)), SUBSTRING(SUBSTRING_INDEX(sub_category, '&', 1), 2)), 
           '& ',
           CONCAT(UPPER(SUBSTRING(SUBSTRING_INDEX(sub_category, '&', -1), 2, 1)), SUBSTRING(SUBSTRING_INDEX(sub_category, '&', -1), 3)))
     WHEN sub_category LIKE '%-%' THEN 
     CONCAT(
           CONCAT(UPPER(SUBSTRING(SUBSTRING_INDEX(sub_category, '-', 1), 1, 1)), SUBSTRING(SUBSTRING_INDEX(sub_category, '-', 1), 2)), 
           '-',
           CONCAT(UPPER(SUBSTRING(SUBSTRING_INDEX(sub_category, '-', -1), 1, 1)), SUBSTRING(SUBSTRING_INDEX(sub_category, '-', -1), 2)))
     WHEN sub_category LIKE '% %' THEN 
     CONCAT(
            CONCAT(UPPER(SUBSTRING(SUBSTRING_INDEX(sub_category, ' ', 1), 1, 1)), SUBSTRING(SUBSTRING_INDEX(sub_category, ' ', 1), 2)), 
            ' ',
            CONCAT(UPPER(SUBSTRING(SUBSTRING_INDEX(sub_category, ' ', -1), 1,1)), SUBSTRING(SUBSTRING_INDEX(sub_category, ' ', -1), 2)))
      WHEN sub_category LIKE '%%' THEN 
             CONCAT(UPPER(SUBSTRING(sub_category, 1, 1)), LOWER(SUBSTRING(sub_category, 2)))
     ELSE sub_category
END;

# Cleaning the column brand
SELECT DISTINCT brand COLLATE utf8mb4_bin FROM raw_products; -- No Need 

# Cleaning the numerical columns
UPDATE raw_products SET product_id = ABS(product_id);
UPDATE raw_products SET price = ROUND(ABS(price), 2);
UPDATE raw_products SET cost = ROUND(ABS(cost), 2);
UPDATE raw_products SET stock_quantity = ABS(stock_quantity);
UPDATE raw_products SET supplier_id = ABS(supplier_id);
    
# Cleaning the column created_at
SELECT created_at FROM raw_products LIMIT 100; 

UPDATE raw_products
SET 
created_at = REPLACE(REPLACE(LOWER(TRIM(created_at)), '/', '-'), ' ', '')
WHERE created_at IS NOT NULL; -- normalzing data

ALTER TABLE raw_products ADD COLUMN clean_date DATE;

UPDATE raw_products
SET clean_date = 
CASE 
    WHEN created_at REGEXP '^[0-9]{4}-[0-9]{2}-[0-9]{2}$' AND SUBSTRING(created_at, 6, 2) <= 12 THEN STR_TO_DATE(created_at, '%Y-%m-%d')
    WHEN created_at REGEXP '^[0-9]{4}-[0-9]{2}-[0-9]{2}$' AND SUBSTRING(created_at, 6, 2) > 12 THEN STR_TO_DATE(created_at, '%Y-%d-%m')
    WHEN created_at REGEXP '^[0-9]{2}-[0-9]{2}-[0-9]{4}$' AND SUBSTRING(created_at, 4, 2) <= 12 THEN STR_TO_DATE(created_at, '%d-%m-%Y')
    WHEN created_at REGEXP '^[0-9]{2}-[0-9]{2}-[0-9]{4}$' AND SUBSTRING(created_at, 4, 2) > 12 THEN STR_TO_DATE(created_at, '%m-%d-%Y')
    WHEN created_at REGEXP '^[0-9]{2}-[a-z]{3}-[0-9]{4}$' THEN STR_TO_DATE(created_at, '%d-%b-%Y')
    ELSE clean_date
END;

UPDATE raw_products
SET clean_date = NULL 
WHERE clean_date > current_date();

ALTER TABLE raw_products DROP COLUMN created_at;
ALTER TABLE raw_products RENAME COLUMN clean_date TO created_at;

SET SQL_SAFE_UPDATES = 1;
SELECT * FROM raw_products;