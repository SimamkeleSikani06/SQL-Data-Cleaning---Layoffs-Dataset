# Data Cleaning Notes — Layoffs Dataset

## Project Overview

This project focuses on cleaning and preparing a layoffs dataset for further exploratory data analysis using MySQL.

The original dataset was stored in the `layoffs` table. I preserved the raw data and created separate working tables for the cleaning process.

The purpose of the cleaning process was to identify and resolve data-quality issues before performing analysis.

### Cleaning workflow

1. Inspect the raw dataset
2. Identify duplicate records
3. Create a working table
4. Remove duplicate records
5. Standardise inconsistent values
6. Convert incorrect data types
7. Identify NULL and blank values
8. Recover missing values where reliable information existed
9. Remove records that could not support meaningful analysis
10. Remove temporary columns
11. Validate the cleaned dataset

---

# 1. Raw Dataset

The original dataset was stored in the `layoffs` table.

```sql
SELECT *
FROM layoffs;
````

The raw table was kept unchanged so that it could be used as the source for restarting the cleaning process if an error was discovered.

The working process followed this structure:

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

Keeping the raw data separate from the working tables made it possible to reproduce the cleaning process.

---

# 2. Duplicate Detection

The dataset did not contain a dedicated unique identifier that could reliably be used to identify duplicate records.

I therefore used the `ROW_NUMBER()` window function to identify records that contained the same values across the relevant columns.

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

`ROW_NUMBER()` assigns a sequential number to records within each group of matching values.

For example:

```text
Company A | Tech | 100 | 1
Company A | Tech | 100 | 2
Company A | Tech | 100 | 3
```

The first record is retained while records with `row_num > 1` can be treated as duplicate occurrences.

---

# 3. Creating a Working Table

The window function was useful for identifying duplicates, but I needed the generated `row_num` value to be stored as a column so that the duplicate records could be removed.

I therefore created `data_cleaning2` containing the calculated row number.

This allowed the duplicate ranking to become stored data rather than a temporary window-function result.

The duplicates were then removed using:

```sql
DELETE
FROM data_cleaning2
WHERE row_num > 1;
```

The first occurrence of each duplicate group was retained.

---

# 4. Data Standardisation

After duplicate removal, I moved to standardising inconsistent values.

I checked the columns individually and applied transformations where inconsistencies were identified.

---

## 4.1 Company Names

I checked company names for unnecessary whitespace:

```sql
SELECT DISTINCT
    company,
    TRIM(company)
FROM data_cleaning2;
```

I then removed leading and trailing whitespace:

```sql
UPDATE data_cleaning2
SET company = TRIM(company);
```

This prevents whitespace differences from causing otherwise identical company names to be treated as different values.

---

## 4.2 Industry

The dataset contained multiple variations of cryptocurrency-related industries.

I first inspected the values:

```sql
SELECT DISTINCT industry
FROM data_cleaning2
WHERE industry LIKE 'Crypto%';
```

The values were standardised to:

```text
Crypto
```

using:

```sql
UPDATE data_cleaning2
SET industry = 'Crypto'
WHERE industry LIKE 'Crypto%';
```

This makes grouping and aggregation more reliable.

---

## 4.3 Country

I identified variations of `United States` containing trailing punctuation.

I inspected the values using:

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

This standardised the country values without changing the underlying meaning.

---

# 5. Date Conversion

The `date` column was initially stored as text.

I first tested the conversion:

```sql
SELECT
    `date`,
    STR_TO_DATE(`date`, '%m/%d/%Y')
FROM data_cleaning2;
```

The values were then converted:

```sql
UPDATE data_cleaning2
SET `date` = STR_TO_DATE(`date`, '%m/%d/%Y');
```

Finally, the column was changed to the MySQL `DATE` data type:

```sql
ALTER TABLE data_cleaning2
MODIFY `date` DATE;
```

### Why this was necessary

Storing dates using the appropriate `DATE` data type makes it easier to:

* Sort records chronologically
* Filter by date
* Extract years and months
* Perform time-based analysis
* Compare dates correctly

---

# 6. NULL and Blank Values

I then investigated missing and blank values.

For the `industry` column:

```sql
SELECT *
FROM data_cleaning2
WHERE industry IS NULL
   OR industry = '';
```

Blank strings were converted to `NULL`:

```sql
UPDATE data_cleaning2
SET industry = NULL
WHERE industry = '';
```

This provided a consistent representation for missing industry information.

---

# 7. Recovering Missing Industry Values

Before removing records with missing information, I investigated whether the missing values could be recovered from other records in the dataset.

Some companies appeared multiple times, and some records contained an industry value while other records for the same company did not.

I identified these cases using a self-join:

```sql
SELECT *
FROM data_cleaning2 t1
JOIN data_cleaning2 t2
    ON t1.company = t2.company
WHERE t1.industry IS NULL
  AND t2.industry IS NOT NULL;
```

Where a reliable industry value existed for the same company, I used that information to populate the missing value:

```sql
UPDATE data_cleaning2 t1
JOIN data_cleaning2 t2
    ON t1.company = t2.company
SET t1.industry = t2.industry
WHERE t1.industry IS NULL
  AND t2.industry IS NOT NULL;
```

### Reasoning

I did not manually guess the missing industry.

Instead, I used information already present in the dataset to recover the value.

This reduced unnecessary data loss while keeping the cleaning process evidence-based.

---

# 8. Corrected Missing-Value Logic

During validation, I discovered a problem in my original cleaning logic.

The original deletion condition was:

```sql
WHERE total_laid_off IS NULL
   OR percentage_laid_off IS NULL;
```

This was too aggressive.

Using `OR` meant that a record was deleted if **either** of the two columns was missing.

For example:

```text
total_laid_off       = NULL
percentage_laid_off  = 50%
```

The record would have been deleted even though it still contained useful layoff information.

Similarly:

```text
total_laid_off       = 100
percentage_laid_off  = NULL
```

would also have been deleted.

This resulted in valid records being removed and caused aggregate results to differ from the expected results.

---

## Corrected Logic

The correct condition was:

```sql
WHERE total_laid_off IS NULL
  AND percentage_laid_off IS NULL;
```

This means that a record is removed only when **both** layoff measures are missing.

The logic therefore becomes:

```text
total_laid_off | percentage_laid_off | Action
------------------------------------------------
NULL           | 50%                  | Keep
100            | NULL                 | Keep
NULL           | NULL                 | Remove
100            | 50%                  | Keep
```

This was an important validation finding because it demonstrated that data-cleaning logic can directly affect downstream analysis.

After identifying the issue, I restarted the cleaning process from the raw `layoffs` table and re-ran the pipeline using the corrected logic.

---

# 9. Why the Correction Matters

The difference between `OR` and `AND` is significant when handling missing data.

### Using OR

```sql
WHERE A IS NULL OR B IS NULL
```

means:

> Remove the record if either A or B is missing.

### Using AND

```sql
WHERE A IS NULL AND B IS NULL
```

means:

> Remove the record only when both A and B are missing.

For this dataset, the second rule was more appropriate because either `total_laid_off` or `percentage_laid_off` could still provide useful information for analysis.

---

# 10. Removing Unusable Records

After correcting the missing-value logic and re-running the cleaning pipeline, records where both key layoff measures were unavailable could be removed.

The purpose was not simply to reduce the dataset size.

The goal was to remove records that could not provide meaningful information for the intended analysis.

This is an important distinction:

> Data cleaning should remove information because there is a justified data-quality or analytical reason, not simply because the data is inconvenient.

---

# 11. Removing Temporary Columns

The `row_num` column was created specifically for duplicate detection.

Once duplicate records had been removed, the column was no longer required.

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

# 12. Validation

After completing the cleaning process, I validated the results rather than immediately moving to analysis.

The mismatch between my aggregates and expected results initially revealed that the cleaning logic had removed too many records.

I traced the discrepancy back to the NULL-handling condition.

This led to the following validation process:

```text
Clean dataset
      ↓
Run aggregate analysis
      ↓
Compare results
      ↓
Identify mismatch
      ↓
Investigate cleaning logic
      ↓
Find incorrect OR condition
      ↓
Replace with AND
      ↓
Restart from raw data
      ↓
Re-run cleaning pipeline
      ↓
Re-validate results
```

This was an important part of the project because it demonstrated that cleaning is an iterative process rather than a single execution of SQL statements.

---

# 13. SQL Concepts Demonstrated

This project demonstrates practical use of:

* SELECT
* WHERE
* DISTINCT
* LIKE
* TRIM
* STR_TO_DATE
* UPDATE
* DELETE
* ALTER TABLE
* INNER JOIN
* Self-joins
* Common Table Expressions (CTEs)
* Window functions
* ROW_NUMBER()
* NULL handling
* Data-type conversion
* Data standardisation
* Data validation

---

# 14. Data Cleaning Workflow

The final workflow can be summarised as:

```text
RAW DATA
   ↓
Inspect dataset
   ↓
Create working copy
   ↓
Identify duplicates
   ↓
ROW_NUMBER() + Window Function
   ↓
Store duplicate ranking
   ↓
Remove duplicates
   ↓
Standardise values
   ↓
Convert data types
   ↓
Identify NULL / blank values
   ↓
Recover missing values where possible
   ↓
Apply validated missing-data rules
   ↓
Remove genuinely unusable records
   ↓
Remove temporary columns
   ↓
Validate results
   ↓
CLEAN DATASET
```

---

# 15. Key Learning

The most important lesson from this project was that **data cleaning decisions directly affect analytical results**.

A technically valid SQL query can still produce an incorrect analytical dataset if the underlying business/data-quality rule is wrong.

The `OR` versus `AND` issue demonstrated this clearly.

I initially produced a cleaned dataset that appeared reasonable, but the aggregate results did not match the expected results. Instead of changing the analysis to force the numbers to match, I traced the discrepancy back through the cleaning pipeline and identified the incorrect filtering condition.

I then restarted from the raw dataset and corrected the logic.

This reinforced an important analytical principle:

> **Validate the data before trusting the analysis.**

---

# 16. Next Step

The cleaned dataset will now be used for exploratory data analysis.

The next stage will focus on answering business questions such as:

* How have layoffs changed over time?
* Which industries experienced the greatest number of layoffs?
* Which countries were most affected?
* Which companies recorded the largest layoffs?
* Which funding stages experienced the most layoffs?
* Are there identifiable patterns in layoffs over time?

The objective is to move from:

**Data Cleaning → Data Validation → Exploratory Data Analysis → Business Insights**

rather than treating data cleaning as the final objective of the project.
