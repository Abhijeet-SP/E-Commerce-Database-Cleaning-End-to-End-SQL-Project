# 🛒 E-Commerce Database Cleaning — End-to-End SQL Project

![SQL](https://img.shields.io/badge/SQL-MySQL-4479A1?style=flat&logo=mysql&logoColor=white)
![Status](https://img.shields.io/badge/Status-Complete-28a745?style=flat)
![Tables](https://img.shields.io/badge/Tables%20Cleaned-8-blueviolet?style=flat)
![Rows](https://img.shields.io/badge/Total%20Rows-~76K-orange?style=flat)

A production-style SQL data cleaning project performed entirely in **MySQL**, covering **8 raw tables** and approximately **76,000+ rows** of intentionally dirty e-commerce data. Every transformation is documented, justified, and structured to reflect real-world data engineering standards.

---

## 📁 Repository Structure

```
ecommerce-sql-cleaning/
│
├── README.md
│
├── data/
│   └── ecommerce_dirty.sql          # Raw source database dump (DDL + INSERT)
│
├── scripts/
│   ├── 01_customers_cleaning.sql
│   ├── 02_employees_cleaning.sql
│   ├── 03_products_cleaning.sql
│   ├── 04_orders_cleaning.sql
│   ├── 05_order_items_cleaning.sql
│   ├── 06_payments_cleaning.sql
│   ├── 07_returns_cleaning.sql
│   └── 08_reviews_cleaning.sql
│
├── exploration/
│   ├── rough_customers.sql          # Iterative exploration & prototyping
│   ├── rough_payments.sql
│   └── rough_reviews.sql
│
└── docs/
    └── cleaning_decisions.md        # Reasoning behind ambiguous decisions
```

> **Run order:** Execute scripts in numbered sequence (`01` → `08`) after loading `data/ecommerce_dirty.sql`.

---

## 🗂️ Dataset Overview

| Table | Rows | Key Columns |
|---|---|---|
| `raw_customers` | ~5,200 | customer_id, full_name, email, phone, age, gender, city, state, country, loyalty_tier, signup_date |
| `raw_employees` | ~200 | employee_id, full_name, department, status, salary, hire_date |
| `raw_products` | ~496 | product_id, category, sub_category, brand, price, cost, stock_quantity, created_at |
| `raw_orders` | ~20,150 | order_id, customer_id, status, total_amount, discount_pct, order_date, ship_date, delivery_date |
| `raw_order_items` | ~25,439 | order_id, product_id, quantity, unit_price, discount |
| `raw_payments` | ~17,320 | payment_id, order_id, payment_method, amount, status, transaction_ref, payment_date |
| `raw_returns` | ~2,000 | return_id, order_id, item_id, reason, status, refund_amount, return_date |
| `raw_reviews` | ~6,000 | review_id, product_id, customer_id, rating, review_text, helpful_votes, review_date |

**Total: ~76,800+ rows across 8 tables**

---

## 🔧 Cleaning Operations Performed

### 1. Numeric Columns
- Corrected negative IDs, amounts, quantities, and ratings using `ABS()`
- Rounded monetary values to 2 decimal places using `ROUND(ABS(col), 2)`
- Applied across: `customer_id`, `age`, `salary`, `price`, `cost`, `unit_price`, `discount`, `total_amount`, `refund_amount`, `rating`, `helpful_votes`

### 2. Text Standardization
- Trimmed whitespace and normalized casing across all string columns
- Used `TRIM()`, `LOWER()`, and `UPPER()` as preprocessing steps before any transformation
- Title-cased names (`full_name`, `city`, `shipping_city`) using `SUBSTRING_INDEX` + `CONCAT`

### 3. Email & Phone
- Emails normalized to lowercase
- Phone numbers reformatted to **E.164 international standard** (`+[country_code][number]`) using cascaded `REPLACE()` operations

### 4. Categorical Columns
- **Gender** — mapped variants (`m`, `male`, `f`, `female`, etc.) to a controlled vocabulary: `Male`, `Female`, `Non-Binary`, `Prefer not to say`
- **Loyalty Tier** — corrected typos (`PLATIMUM` → `Platinum`), enforced 5-tier standard: Bronze, Silver, Gold, Platinum, Diamond
- **Order Status** — corrected spell errors (`procesing`, `deliverd`, `canceld`) and standardized to Title Case
- **Payment Method** — standardized multi-word values (`Credit Card`, `Bank Transfer`, `Apple Pay`, `Google Pay`) using a general-purpose `SUBSTRING_INDEX` pattern
- **Department / Employee Status** — handled special abbreviations (`HR`, `IT`) alongside normal title-casing

### 5. Geographic Data
- Country names normalized; `USA` and `UK` explicitly uppercased, others title-cased
- Cities formatted to Title Case, supporting single-word and multi-word city names
- State abbreviations expanded to full names for **USA** (14 states), **Canada** (3 provinces), **Australia** (2 states), **UK**, and **Germany** using conditional `CASE` statements

### 6. Multi-Format Date Parsing (Core Challenge)
All date columns existed in 5 mixed formats across the same column:

| Format | Example | Strategy |
|---|---|---|
| `YYYY-MM-DD` | `2022-03-15` | Direct parse if month ≤ 12 |
| `YYYY-DD-MM` | `2022-25-03` | Swap day/month if middle part > 12 |
| `DD-MM-YYYY` | `15-03-2022` | Parse as DD-MM if middle part ≤ 12 |
| `MM-DD-YYYY` | `03-25-2022` | Parse as MM-DD if middle part > 12 |
| `DD-Mon-YYYY` | `15-Mar-2022` | `STR_TO_DATE` with `%d-%b-%Y` |

**Approach:**
1. Normalize separators (`/` → `-`, strip spaces)
2. Use `REGEXP` to detect the format pattern
3. Use `SUBSTRING()` to inspect the month/day position and resolve ambiguity
4. Parse using `STR_TO_DATE()` into a temporary `DATE` column
5. Nullify any future dates (`> CURDATE()`) as invalid
6. Drop the raw column and rename the clean one

This logic is applied consistently across 9 date columns spanning 5 tables.

### 7. Data Quality Filtering
- Deleted customer records where `age NOT BETWEEN 10 AND 100` (unrealistic entries)
- Future dates set to `NULL` across all date columns
- Invalid or out-of-range values set to `NULL` rather than deleted where row context was still useful

---

## 💡 Design Decisions & Tradeoffs

**Ambiguous dates:** When both numbers could be valid day/month (e.g., `05-06-2021`), the logic interprets as `DD-MM-YYYY`. This is a documented assumption; see `docs/cleaning_decisions.md`.

**REGEXP vs LIKE:** Both approaches were explored (see `exploration/` folder). Final scripts use `REGEXP` for precision; the `LIKE '__-__-____'` alternative was prototyped as a lighter-weight option.

**Phone formatting:** E.164 standardization was applied using nested `REPLACE()` chains since no external UDF was available. The approach handles `(`, `)`, `-`, `+`, and mixed spacing.

**NULL vs DELETE:** Invalid categoricals (e.g., unrecognizable gender values) are set to `NULL` to preserve the row for other analytics use — a deliberate choice over hard deletion.

**Safe Updates:** `SQL_SAFE_UPDATES` is disabled at the start of each script and re-enabled at the end — a safe, scoped pattern for bulk UPDATE/DELETE operations.

---

## 🛠️ How to Run

**Prerequisites:** MySQL 8.0+

```sql
-- Step 1: Load the raw data
SOURCE data/ecommerce_dirty.sql;

-- Step 2: Run cleaning scripts in order
SOURCE scripts/01_customers_cleaning.sql;
SOURCE scripts/02_employees_cleaning.sql;
SOURCE scripts/03_products_cleaning.sql;
SOURCE scripts/04_orders_cleaning.sql;
SOURCE scripts/05_order_items_cleaning.sql;
SOURCE scripts/06_payments_cleaning.sql;
SOURCE scripts/07_returns_cleaning.sql;
SOURCE scripts/08_reviews_cleaning.sql;
```

Or run them sequentially from the command line:
```bash
mysql -u root -p ecommerce_dirty < scripts/01_customers_cleaning.sql
```

---

## 📌 Key SQL Concepts Demonstrated

- `REGEXP` pattern matching for format detection
- `STR_TO_DATE()` with multi-format fallback logic
- `SUBSTRING_INDEX()` for multi-word string parsing
- `CASE WHEN` for controlled vocabulary mapping and conditional transformations
- `ALTER TABLE` — adding, dropping, and renaming columns as part of a cleaning pipeline
- Cascaded `REPLACE()` for multi-character normalization
- `ABS()` and `ROUND()` for numeric correction
- `TRIM()` + `LOWER()` + `UPPER()` composition patterns
- Safe update scoping with `SQL_SAFE_UPDATES`
- `COLLATE utf8mb4_bin` for case-sensitive `DISTINCT` audits

---

## 👤 Author

**[Your Name]**  
Aspiring Data Analyst | SQL · Python · Data Cleaning  
[LinkedIn](https://linkedin.com/in/yourprofile) · [GitHub](https://github.com/yourusername)
