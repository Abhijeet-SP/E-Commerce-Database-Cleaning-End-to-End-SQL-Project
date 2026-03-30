USE ecommerce_dirty;
SHOW FULL COLUMNS FROM raw_employees; # all case insensitive
SHOW TABLE STATUS LIKE 'raw_employees'; # 200 entries
SELECT * FROM raw_employees;

SET SQL_SAFE_UPDATES = 0;

# cleaning the numeric columns 

UPDATE raw_employees 
SET 
employee_id = ABS(employee_id),
manager_id = ABS(manager_id),
salary = ROUND(ABS(salary), 2);

# Cleaning the column full_name
UPDATE raw_employees SET full_name = LOWER(TRIM(full_name));

UPDATE raw_employees
SET full_name = 
CONCAT(
       CONCAT(UPPER(SUBSTRING(SUBSTRING_INDEX(full_name, ' ', 1), 1, 1)), LOWER(SUBSTRING(SUBSTRING_INDEX(full_name, ' ', 1), 2))),
       ' ',
       CONCAT(UPPER(SUBSTRING(SUBSTRING_INDEX(full_name, ' ', -1), 1, 1)), LOWER(SUBSTRING(SUBSTRING_INDEX(full_name, ' ', -1), 2))));

# Cleaning the column email
-- requires a REGEXP expression for filtering 
UPDATE raw_employees
SET email = LOWER(TRIM(email));

# Cleaning the column department
SELECT DISTINCT department COLLATE utf8mb4_bin FROM raw_employees;
UPDATE raw_employees
SET department = LOWER(TRIM(department));

UPDATE raw_employees
SET department =
    CASE
        WHEN department = 'hr' THEN 'HR'
        WHEN department = 'it' THEN 'IT'
        WHEN department NOT IN ('it', 'hr') THEN CONCAT( UPPER(SUBSTRING(department,1,1)), SUBSTRING(department,2))
        ELSE department
    END;

# cleaning the column status
SELECT DISTINCT status COLLATE utf8mb4_bin FROM raw_employees;
UPDATE raw_employees
SET status = LOWER(TRIM(status));

UPDATE raw_employees
SET status = 
CASE 
     WHEN status != 'on leave'
         THEN CONCAT(UPPER(SUBSTRING(status, 1,1)), SUBSTRING(LOWER(status), 2))
     WHEN status = 'on leave' THEN 'On Leave'
     ELSE status
END;

# cleaning the column hire_date
SELECT hire_date FROM raw_employees LIMIT 100; 

UPDATE raw_employees
SET hire_date = REPLACE(REPLACE(LOWER(TRIM(hire_date)), '/', '-'), ' ', '')
WHERE hire_date IS NOT NULL; -- normalzing data

ALTER TABLE raw_employees ADD COLUMN clean_date DATE;

UPDATE raw_employees
SET clean_date = 
CASE 
    WHEN hire_date REGEXP '^[0-9]{4}-[0-9]{2}-[0-9]{2}$' AND SUBSTRING(hire_date, 6, 2) <= 12 THEN STR_TO_DATE(hire_date, '%Y-%m-%d')
    WHEN hire_date REGEXP '^[0-9]{4}-[0-9]{2}-[0-9]{2}$' AND SUBSTRING(hire_date, 6, 2) > 12 THEN STR_TO_DATE(hire_date, '%Y-%d-%m')
    WHEN hire_date REGEXP '^[0-9]{2}-[0-9]{2}-[0-9]{4}$' AND SUBSTRING(hire_date, 4, 2) <= 12 THEN STR_TO_DATE(hire_date, '%d-%m-%Y')
    WHEN hire_date REGEXP '^[0-9]{2}-[0-9]{2}-[0-9]{4}$' AND SUBSTRING(hire_date, 4, 2) > 12 THEN STR_TO_DATE(hire_date, '%m-%d-%Y')
    WHEN hire_date REGEXP '^[0-9]{2}-[a-z]{3}-[0-9]{4}$' THEN STR_TO_DATE(hire_date, '%d-%b-%Y')
    ELSE clean_date
END;

UPDATE raw_employees
SET clean_date = NULL
WHERE clean_date > current_date();

SELECT clean_date, hire_date FROM raw_employees;

ALTER TABLE raw_employees DROP COLUMN hire_date;
ALTER TABLE raw_employees RENAME COLUMN clean_date TO hire_date;

SET SQL_SAFE_UPDATES = 1;
SELECT * FROM raw_employees;