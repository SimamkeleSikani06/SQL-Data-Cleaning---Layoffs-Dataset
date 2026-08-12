# Layoffs Data Cleaning & Exploratory Analysis

## Overview

This project demonstrates an end-to-end data cleaning workflow using MySQL on a layoffs dataset.

The project focuses on preparing raw, inconsistent data for reliable analysis by identifying duplicate records, standardising values, handling missing data, converting data types, and validating the results before exploratory analysis.

The project also demonstrates how data-cleaning decisions can directly affect analytical results.

---

## Business Objective

The objective of this project is to transform a raw layoffs dataset into a reliable dataset that can be used to investigate patterns and trends in employee layoffs.

The analysis will ultimately explore questions such as:

- How have layoffs changed over time?
- Which industries experienced the most layoffs?
- Which countries were most affected?
- Which companies recorded the largest layoffs?
- Which company stages experienced the greatest layoffs?
- Are there noticeable patterns in layoffs over time?

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

The original raw dataset is preserved in the `layoffs` table.

Working tables were created separately so that the original data could remain unchanged.

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
NULL / Blank Value Investigation
     ↓
Missing-Value Recovery
     ↓
Remove Unusable Records
     ↓
Validation
     ↓
Clean Dataset
     ↓
Exploratory Data Analysis
Key Cleaning Steps
1. Duplicate Detection

The dataset did not contain a dedicated unique identifier for reliably identifying duplicate records.

I used the ROW_NUMBER() window function together with a CTE to identify records with identical values across the relevant columns.

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

Records where row_num > 1 were treated as duplicate occurrences.

2. Data Standardisation

Several inconsistencies were identified and standardised.

Examples include:

Removing unnecessary whitespace from company names
Standardising cryptocurrency-related industry values to Crypto
Removing trailing punctuation from country values

Functions such as TRIM() and LIKE were used to identify and correct these inconsistencies.

3. Date Conversion

The original date column was stored as text.

The values were converted using:

STR_TO_DATE(`date`, '%m/%d/%Y')

The column was then changed to the MySQL DATE data type.

This allows reliable chronological sorting, filtering and time-based analysis.

4. Missing Values

Blank industry values were converted to NULL.

I then investigated whether missing industry values could be recovered from other records belonging to the same company.

A self-join was used to identify cases where:

One record had a missing industry
Another record for the same company contained a known industry

Where reliable information existed, the missing value was populated rather than unnecessarily deleting the record.

Important Data-Quality Issue Discovered

During validation, I discovered that my original cleaning logic was removing too many valid records.

The original condition was:

WHERE total_laid_off IS NULL
   OR percentage_laid_off IS NULL

This meant that a record was removed if either value was missing.

For example:

total_laid_off = NULL
percentage_laid_off = 50%

would have been deleted even though the record still contained useful information.

The logic was corrected to:

WHERE total_laid_off IS NULL
  AND percentage_laid_off IS NULL

This means that a record is removed only when both key layoff measures are missing.

Why this mattered

The original logic caused over-deletion of valid records and resulted in aggregate results that did not match the expected results.

Rather than modifying the analysis to compensate for the discrepancy, I traced the problem back to the data-cleaning pipeline, identified the incorrect condition, restarted from the raw dataset and re-ran the pipeline using the corrected logic.

This became an important validation step in the project.

Validation

The cleaning process was validated by comparing the resulting dataset and aggregate calculations against expected results.

The validation process was:

Clean Data
    ↓
Run Analysis
    ↓
Identify Mismatch
    ↓
Trace Result Back to Cleaning
    ↓
Identify Incorrect Logic
    ↓
Correct Cleaning Rule
    ↓
Restart From Raw Data
    ↓
Re-run Pipeline
    ↓
Validate Results

This demonstrated that data cleaning is an iterative process and that analytical results should not be trusted until the underlying dataset has been validated.

SQL Skills Demonstrated

This project demonstrates practical use of:

SELECT
WHERE
LIKE
DISTINCT
GROUP BY
ORDER BY
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
layoffs-data-analysis/
│
├── README.md
│
├── data_cleaning_notes.md
│
├── sql/
│   ├── data_cleaning.sql
│   └── exploratory_analysis.sql
│
└── data/
    └── README.md

The raw dataset is not included in this repository where licensing or redistribution restrictions apply.

Tools

Database: MySQL

Primary skills: SQL, Data Cleaning, Data Validation, Exploratory Data Analysis

What I Learned

This project reinforced that data analysis does not begin with writing analytical queries.

A reliable workflow starts with understanding the data and assessing its quality.

The main lesson from this project was that cleaning logic directly affects analytical results.

The OR versus AND issue demonstrated that a query can execute successfully while still producing an analytically incorrect dataset.

I therefore learned to:

Understand the structure of the dataset
Identify data-quality problems
Define a rule for addressing each problem
Apply transformations
Validate the resulting data
Investigate unexpected results
Trace discrepancies back to the transformation logic
Only then proceed with analysis
Next Step

The cleaned dataset will be used for exploratory data analysis.

The next stage of the project will focus on identifying trends, patterns and business insights from the cleaned layoffs data.

The overall project progression is:

Data Cleaning
      ↓
Data Validation
      ↓
Exploratory Data Analysis
      ↓
Business Insights
      ↓
Visualization
Author

Simamkele Sikani

Aspiring Junior Data Analyst focused on SQL, data cleaning, exploratory analysis and business-focused insights.


### One change I strongly recommend for your GitHub

Don't call the repository simply **`data-cleaning`**.

Use something more descriptive, for example:

```text
layoffs-data-cleaning-analysis

or, once the EDA is finished:

layoffs-data-analysis

The second is stronger for your portfolio because the project will eventually demonstrate the full workflow: cleaning → analysis → insights, rather than only cleaning.
