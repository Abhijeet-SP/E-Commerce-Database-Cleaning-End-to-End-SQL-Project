# Cleaning Decisions & Assumptions

This document records all non-obvious decisions made during the cleaning process, so that any analyst or reviewer can understand the reasoning behind transformations that involve judgment calls.

---

## 1. Ambiguous Date Interpretation

**Problem:** Dates like `05-06-2021` are ambiguous — could be May 6 or June 5.

**Decision:** When the middle two digits are ≤ 12 (making both day-first and month-first valid), the format is interpreted as `DD-MM-YYYY`.

**Rationale:** The dataset originates from a multi-country e-commerce system. The majority of non-US countries use the DD-MM-YYYY convention. The US-style MM-DD-YYYY is only applied when the middle value exceeds 12 (i.e., it *must* be a day, not a month).

---

## 2. Future Dates Set to NULL

**Problem:** Several date columns contained future dates (e.g., `signup_date`, `order_date`), likely from data entry errors or system timestamp bugs.

**Decision:** Any date greater than `CURDATE()` is set to `NULL`.

**Rationale:** A customer cannot have signed up in the future. These values are invalid by definition. Setting to `NULL` preserves the row for analysis while flagging the date field as unknown.

---

## 3. Age Range: 10–100

**Problem:** The `age` column in `raw_customers` contained values outside any realistic range (including negatives, single digits, and values > 100).

**Decision:** Rows where `age NOT BETWEEN 10 AND 100` are deleted entirely.

**Rationale:** Unlike other invalid fields that can be NULLed, age is likely used in segmentation. A customer with `age = 3` or `age = 150` is a data entry error with no recoverable signal. The entire row is removed.

---

## 4. Gender → NULL for Unrecognized Values

**Problem:** Some gender values could not be mapped to any known category.

**Decision:** Unrecognized values are set to `NULL` (not deleted).

**Rationale:** Gender is one column among many. The rest of the row (purchase history, location, tier, etc.) retains analytical value. Soft-nulling preserves the row.

**Known categories:** `Male`, `Female`, `Non-Binary`, `Prefer not to say`

---

## 5. Phone Numbers — E.164 Format

**Problem:** Phone numbers were stored in inconsistent formats: `(555) 123-4567`, `+1-555-123-4567`, `555 123 4567`, etc.

**Decision:** All phones are reformatted to E.164 (`+[digits only]`) using cascaded `REPLACE()`.

**Rationale:** E.164 is the international standard for telephony and is compatible with SMS APIs, CRM imports, and analytics tools. No external UDF was available, so the transformation uses native MySQL string functions.

---

## 6. State Abbreviations — Explicit Mapping

**Problem:** State/province columns mixed abbreviations (`NY`, `CA`, `ON`) with full names (`New York`, `Ontario`).

**Decision:** A `CASE` statement explicitly maps all known abbreviations to full names. Unknown values are passed through unchanged (`ELSE state`).

**Rationale:** A regex-free, explicit mapping is preferred here for auditability. There is no ambiguity in the mapping (e.g., `GA` for Georgia, not Gabon), and the dataset's known country set is small and finite.

---

## 7. Loyalty Tier Typo — PLATIMUM

**Problem:** The value `PLATIMUM` appears in the `loyalty_tier` column — a clear misspelling of `PLATINUM`.

**Decision:** Both `PLATINUM` and `PLATIMUM` are mapped to `Platinum`.

**Rationale:** Single-character transposition typos during manual data entry are well-documented. No other tier name resembles `PLATIMUM`. The correction is unambiguous.

---

## 8. Order Status Spell Errors

**Problem:** Status values included `procesing`, `deliverd`, `canceld`, `ship`, `deliver`.

**Decision:** Each misspelling is explicitly mapped to its correct form in a `CASE` statement before the general title-casing transformation is applied.

**Rationale:** Applying title-casing first would have turned `procesing` into `Procesing` — still wrong. Spell-correction must precede formatting.

---

## 9. transaction_ref — Uppercase + Trim Only

**Problem:** `transaction_ref` values were mixed-case with occasional whitespace.

**Decision:** Apply `UPPER(TRIM(...))` only. No structural transformation.

**Rationale:** All `transaction_ref` values are exactly 12 characters in length (verified via `LENGTH()` audit). The format is a fixed alphanumeric code with no delimiters — uppercase normalization is sufficient for consistency.
