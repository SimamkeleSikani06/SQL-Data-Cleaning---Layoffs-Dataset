# Layoffs Data Cleaning Project

## Project Overview

This project focuses on cleaning and preparing a layoffs dataset for future analysis using MySQL.

The objective of this project was to take a raw dataset, identify data-quality issues, apply appropriate cleaning techniques, and produce a more reliable dataset that can be used for exploratory data analysis.

This project currently focuses **only on data cleaning**. Exploratory analysis and visualization will be completed as the next stage.

---

## Objective

The goal of the cleaning process was to:

- Identify duplicate records
- Standardise inconsistent data
- Handle NULL and blank values
- Recover missing information where possible
- Convert columns to appropriate data types
- Remove records that could not support meaningful analysis
- Validate the cleaned dataset

---

## Dataset

The dataset contains information about company layoffs, including:

- Company
- Location
- Industry
- Total laid off
- Percentage laid off
- Date
- Company stage
- Country
- Funds raised

The original dataset was stored in the `layoffs` table.

I preserved the raw table and used separate working tables for the cleaning process.

---

## Data Cleaning Workflow

The cleaning process followed this workflow:

```text
Raw Dataset
     ↓
Data Inspection
     ↓
Duplicate Detection
     ↓
Duplicate Removal
     ↓
Data Standardisation
     ↓
Data-Type Conversion
     ↓
NULL / Blank Value Handling
     ↓
Missing-Value Recovery
     ↓
Remove Unusable Records
     ↓
Validation
     ↓
Clean Dataset
1. Duplicate Detection

The dataset did not contain a dedicated unique identifier that could reliably be used to identify duplicate records.

I used the ROW_NUMBER() window function together with a Common Table Expression (CTE) to identify duplicate records.

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

Records with a row_num greater than 1 were identified as duplicate occurrences.

A separate working table was used to store the generated row numbers so that duplicate records could be removed.

2. Data Standardisation

I identified and corrected inconsistencies in several columns.

Company Names

Unnecessary leading and trailing whitespace was removed using TRIM().

UPDATE data_cleaning2
SET company = TRIM(company);
Industry

Different variations of cryptocurrency-related industries were standardised to:

Crypto

using:

UPDATE data_cleaning2
SET industry = 'Crypto'
WHERE industry LIKE 'Crypto%';
Country

Trailing punctuation was removed from affected United States values.

UPDATE data_cleaning2
SET country = TRIM(TRAILING '.' FROM country)
WHERE country LIKE 'United States%';
3. Date Conversion

The date column was initially stored as text.

I converted the values into a proper MySQL DATE format using:

STR_TO_DATE(`date`, '%m/%d/%Y')

The column was then changed to the DATE data type.

This prepares the dataset for future time-based analysis.

4. NULL and Blank Values

I investigated missing and blank values in the dataset.

Blank industry values were converted to NULL so that missing information was represented consistently.

UPDATE data_cleaning2
SET industry = NULL
WHERE industry = '';
5. Recovering Missing Information

Before removing records with missing information, I investigated whether missing industry values could be recovered from other records.

Some companies appeared multiple times in the dataset.

Where another record belonging to the same company contained a valid industry value, I used a self-join to identify and populate the missing value.

UPDATE data_cleaning2 t1
JOIN data_cleaning2 t2
    ON t1.company = t2.company
SET t1.industry = t2.industry
WHERE t1.industry IS NULL
  AND t2.industry IS NOT NULL;

This allowed missing information to be recovered from existing data rather than being guessed or unnecessarily deleted.

6. Handling Records With Missing Layoff Information

During the cleaning process, I identified records where the two main layoff measures were missing:

total_laid_off
percentage_laid_off

An important correction was made during validation.

Original Logic

I initially used:

WHERE total_laid_off IS NULL
   OR percentage_laid_off IS NULL;

This was too aggressive because it removed records where only one of the two values was missing.

Corrected Logic

The condition was changed to:

WHERE total_laid_off IS NULL
  AND percentage_laid_off IS NULL;

This means that a record is removed only when both layoff measures are missing.

This correction prevented valid records from being unnecessarily deleted.

7. Validation

During validation, I discovered that my initial cleaning logic caused aggregate results to differ from expected results.

Instead of changing the analysis, I traced the discrepancy back to the cleaning process.

I identified the incorrect OR condition, corrected it to AND, restarted the cleaning process from the raw dataset, and re-ran the pipeline.

This demonstrated an important principle:

A successful SQL query does not necessarily mean that the resulting dataset is correct.

The cleaning process therefore included validation and revision rather than assuming that the first result was correct.

SQL Skills Demonstrated

This project demonstrates practical use of:

SELECT
WHERE
DISTINCT
LIKE
JOIN
Self-joins
Common Table Expressions (CTEs)
Window functions
ROW_NUMBER()
UPDATE
DELETE
ALTER TABLE
TRIM()
STR_TO_DATE()
NULL handling
Data-type conversion
Data standardisation
Data validation
Project Structure
layoffs-data-cleaning/
│
├── README.md
│
├── data_cleaning_notes.md
│
└── sql/
    └── data_cleaning.sql
Tools

Database: MySQL

Focus: Data Cleaning and Data Quality

Techniques: SQL, CTEs, Window Functions, Joins, Data Standardisation, NULL Handling

Current Project Status
Completed
 Raw data inspection
 Duplicate identification
 Duplicate removal
 Data standardisation
 Date conversion
 NULL and blank-value handling
 Missing-value recovery
 Data-quality validation
 Cleaning documentation
Next
 Exploratory Data Analysis
 Business questions
 Data analysis
 Business insights
 Data visualisation
Author

Simamkele Sikani
