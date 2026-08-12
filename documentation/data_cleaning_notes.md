# Data Cleaning Notes — Layoffs Dataset

## Project Overview

This project focuses on cleaning and preparing a layoffs dataset for further analysis using MySQL.

The original dataset was stored in the `layoffs` table. A separate working table was created so that the original raw data remained unchanged during the cleaning process.

The overall cleaning workflow was:

1. Inspect the raw data
2. Identify duplicate records
3. Create a working copy
4. Detect and remove duplicates
5. Standardise inconsistent values
6. Convert data types
7. Handle NULL and blank values
8. Repopulate missing values where reliable information existed
9. Remove records that could not support meaningful analysis
10. Remove temporary columns
11. Validate the cleaned dataset

---

## 1. Raw Data

The original data was stored in:

```sql
SELECT * FROM layoffs;
```

The `layoffs` table was treated as the raw source.

I avoided modifying the raw table directly so that the original dataset could be preserved and compared against the cleaned version if necessary.

A working table named `data_cleaning` was created from the raw data.

The cleaned data was subsequently manipulated in `data_cleaning2`.

The structure was therefore:

```text
layoffs
   ↓
data_cleaning
   ↓
duplicate detection
   ↓
data_cleaning2
   ↓
cleaned dataset
```

---

# 2. Duplicate Detection

One of the first data-quality issues was that the dataset did not contain a dedicated unique row identifier that could be used to identify duplicate records.

To identify potential duplicates, I used the `ROW_NUMBER()` window function.

```sql
WITH view_duplicatesCTE AS (
    SELECT *,
        ROW_NUMBER() OVER (
            PARTITION BY
                company,
                location,
                industry,
                total_laid_off,
                percentage_laid_off,
                `date`,
                stage,
                country,
                funds_raised_millions
        ) AS row_num
    FROM data_cleaning
)
SELECT *
FROM view_duplicatesCTE
WHERE row_num > 1;
```

### Why `ROW_NUMBER()` was used

The window function assigns a sequential number to rows that contain the same values across the selected columns.

For example:

```text
company | location | industry | row_num
----------------------------------------
Company A | New York | Tech | 1
Company A | New York | Tech | 2
Company A | New York | Tech | 3
```

Rows with `row_num > 1` were treated as duplicate occurrences.

The first occurrence was retained.

---

# 3. Creating a Working Table for Duplicate Removal

The duplicate detection query allowed me to identify duplicate rows, but I needed a table containing the generated row number in order to permanently remove the duplicate records.

A second working table was therefore created with the `row_num` column.

The window function was inserted into this table so that the generated row number became stored data rather than a temporary calculation.

The duplicate records could then be removed using:

```sql
DELETE
FROM data_cleaning2
WHERE row_num > 1;
```

This retained the first occurrence of each duplicate group and removed subsequent occurrences.

The original `layoffs` table remained untouched.

---

# 4. Data Standardisation

After removing duplicates, I moved to standardising inconsistent values.

The approach was to inspect columns for inconsistent representations and then apply targeted transformations.

---

## Company Names

Whitespace was removed from company names using `TRIM()`.

First, the values were inspected:

```sql
SELECT DISTINCT
    company,
    TRIM(company)
FROM data_cleaning2;
```

Then the transformation was applied:

```sql
UPDATE data_cleaning2
SET company = TRIM(company);
```

This ensured that unnecessary leading and trailing whitespace did not cause the same company to appear as different values.

---

## Industry

The industry column contained several variations beginning with `Crypto`.

I first investigated the values:

```sql
SELECT DISTINCT industry
FROM data_cleaning2
WHERE industry LIKE 'Crypto%';
```

The variations were standardised to a single value:

```sql
UPDATE data_cleaning2
SET industry = 'Crypto'
WHERE industry LIKE 'Crypto%';
```

This makes aggregation and filtering more reliable because different representations of the same industry are treated consistently.

---

## Country

The country column contained values such as variations of `United States` with trailing punctuation.

I inspected the affected values:

```sql
SELECT DISTINCT
    country,
    TRIM(TRAILING '.' FROM country)
FROM data_cleaning2
WHERE country LIKE 'United States%';
```

The trailing period was removed:

```sql
UPDATE data_cleaning2
SET country = TRIM(TRAILING '.' FROM country)
WHERE country LIKE 'United States%';
```

This standardised the country values without changing the actual country information.

---

# 5. Date Conversion

The `date` column was initially stored as text.

I first checked how the existing values could be converted:

```sql
SELECT
    `date`,
    STR_TO_DATE(`date`, '%m/%d/%Y')
FROM data_cleaning2;
```

The text values were then converted:

```sql
UPDATE data_cleaning2
SET `date` = STR_TO_DATE(`date`, '%m/%d/%Y');
```

Finally, the column was changed to the appropriate MySQL `DATE` data type:

```sql
ALTER TABLE data_cleaning2
MODIFY `date` DATE;
```

### Why this was important

Dates should be stored as dates rather than strings because this makes operations such as:

- filtering by date
- sorting chronologically
- extracting years
- calculating date differences
- performing time-based analysis

more reliable.

---

# 6. NULL and Blank Values

After standardisation, I investigated missing values.

The first check focused on the `industry` column:

```sql
SELECT *
FROM data_cleaning2
WHERE industry IS NULL
   OR industry = '';
```

This revealed records where industry information was either missing or represented as a blank string.

Blank values were converted to `NULL`:

```sql
UPDATE data_cleaning2
SET industry = NULL
WHERE industry = '';
```

This created a consistent representation for missing industry information.

---

# 7. Repopulating Missing Industry Values

Rather than immediately removing rows with missing industry information, I investigated whether the missing values could be recovered from other records.

I identified companies with missing industry information:

```sql
SELECT *
FROM data_cleaning2
WHERE company IN (
    'Airbnb',
    "Bally's Interactive",
    'Carvana',
    'Juul'
);
```

I then joined the table to itself to find records where the same company had a known industry value:

```sql
SELECT *
FROM data_cleaning2 t1
JOIN data_cleaning2 t2
    ON t1.company = t2.company
WHERE t1.industry IS NULL
  AND t2.industry IS NOT NULL;
```

This allowed existing information within the dataset to be used to populate missing values.

The missing industry values were updated using:

```sql
UPDATE data_cleaning2 t1
JOIN data_cleaning2 t2
    ON t1.company = t2.company
SET t1.industry = t2.industry
WHERE t1.industry IS NULL
  AND t2.industry IS NOT NULL;
```

### Reasoning

I did not randomly infer the missing industry.

Instead, I used another record belonging to the same company where the industry was already available.

This provided an internal source of evidence for the missing value.

---

# 8. Removing Records That Could Not Support Analysis

After attempting to recover missing information, I identified records where important analytical fields were still missing.

The dataset contained two particularly important measures:

- `total_laid_off`
- `percentage_laid_off`

Records where both measures were unavailable could not provide useful information for many of the intended layoffs analyses.

These records were therefore removed:

```sql
DELETE
FROM data_cleaning2
WHERE (total_laid_off IS NULL OR total_laid_off = '')
   OR (percentage_laid_off IS NULL OR percentage_laid_off = '');
```

### Reasoning

These records were considered analytical dead ends because they lacked the core layoff measurements required for meaningful analysis.

Keeping large numbers of unusable records would add noise without providing useful analytical value.

---

# 9. Removing Temporary Columns

The `row_num` column was only required for the duplicate-removal process.

Once duplicates had been removed, the column no longer served a purpose.

It was therefore removed:

```sql
ALTER TABLE data_cleaning2
DROP COLUMN row_num;
```

The final dataset was then inspected:

```sql
SELECT *
FROM data_cleaning2;
```

---

# 10. Cleaning Workflow Summary

The final cleaning workflow was:

```text
Raw Data
   ↓
Inspect Dataset
   ↓
Create Working Copy
   ↓
Identify Duplicates
   ↓
ROW_NUMBER() Window Function
   ↓
Store Duplicate Ranking
   ↓
Remove Duplicate Rows
   ↓
Standardise Company Names
   ↓
Standardise Industry Values
   ↓
Standardise Country Values
   ↓
Convert Date From Text → DATE
   ↓
Identify NULL / Blank Values
   ↓
Recover Missing Industry Values
   ↓
Remove Records Without Useful Layoff Measures
   ↓
Remove Temporary row_num Column
   ↓
Validate Clean Dataset
```

---

# 11. SQL Techniques Demonstrated

This project demonstrates practical use of several MySQL concepts:

- `SELECT`
- `WHERE`
- `LIKE`
- `DISTINCT`
- `TRIM()`
- `STR_TO_DATE()`
- `UPDATE`
- `DELETE`
- `ALTER TABLE`
- `JOIN`
- Self-joins
- Common Table Expressions (CTEs)
- Window functions
- `ROW_NUMBER()`
- Conditional filtering
- NULL handling
- Data-type conversion

---

# 12. Key Data-Quality Decisions

The main decisions made during cleaning were:

### Duplicate records

Duplicate rows were identified using multiple attributes rather than assuming that the dataset already contained a reliable unique identifier.

### Inconsistent formatting

Values such as company names, industries and countries were standardised to improve consistency.

### Missing values

Missing industry values were investigated before deletion. Where another record for the same company contained a reliable industry value, that information was used to populate the missing field.

### Unusable records

Records without meaningful layoff measurements were removed because they could not support the intended analysis.

### Raw-data preservation

The original `layoffs` table was preserved while separate working tables were used for transformation and cleaning.

---

# 13. Limitations and Further Improvements

This project was primarily focused on developing and demonstrating SQL data-cleaning skills.

There are areas that could be improved in a production environment.

For example, instead of manually checking individual columns one at a time, a more systematic data-quality assessment could be performed before transformation.

A production workflow could include:

- NULL-rate analysis for every column
- Duplicate-rate analysis
- Data-type validation
- Range checks
- Outlier detection
- Referential-integrity checks
- Automated validation queries
- Before-and-after row counts
- Data-quality logging

The next stage of this project would be to use the cleaned dataset for exploratory analysis and business-focused questions.

---

# Conclusion

This project demonstrates how I approached an unfamiliar dataset from a data-quality perspective before performing analysis.

The main objective was not simply to remove incorrect records. The objective was to understand the structure of the data, identify quality problems, determine which issues could be corrected using evidence within the dataset, and remove information that could not support meaningful analysis.

The cleaned dataset provides a more reliable foundation for subsequent exploratory analysis and visualization.