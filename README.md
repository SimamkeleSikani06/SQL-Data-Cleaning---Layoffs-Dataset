# SQL Data Cleaning — Layoffs Dataset

## Project Overview

This project demonstrates a practical data-cleaning workflow using MySQL.

The objective was to take a raw layoffs dataset, identify data-quality issues, clean and standardize the data, handle missing values where possible, remove records that were not suitable for further analysis, and produce a cleaner dataset for exploratory analysis.

This project focuses specifically on the **data preparation stage of the analytical workflow**.

The project was completed as a practical exercise to strengthen my SQL and data-quality skills as I develop toward a Junior Data Analyst role.

---

## Dataset

The dataset contains information about company layoffs, including:

* Company
* Location
* Industry
* Total employees laid off
* Percentage of employees laid off
* Date
* Company stage
* Country
* Funds raised in millions

The original dataset was preserved in the `layoffs` table and was not directly modified during the cleaning process.

---

## Project Structure

```text
sql-data-cleaning-layoffs/
│
├── README.md
│
├── data/
│   └── layoffs.csv
│
├── sql/
│   └── data_cleaning.sql
│
└── documentation/
    └── data_cleaning_notes.md
```

---

## Data Cleaning Workflow

The cleaning process followed this general workflow:

```text
Raw Data
   ↓
Duplicate Identification
   ↓
Duplicate Removal
   ↓
Data Standardization
   ↓
Missing / NULL Value Investigation
   ↓
Missing Value Recovery
   ↓
Removal of Unusable Records
   ↓
Clean Dataset
```

---

## 1. Preserving the Raw Data

The original dataset was stored in the `layoffs` table.

I kept this table unchanged so that the original data remained available as a reference throughout the cleaning process.

I then created working tables for the cleaning process rather than modifying the raw dataset directly.

The workflow was:

```text
layoffs
   ↓
data_cleaning
   ↓
data_cleaning2
```

`data_cleaning` was used to investigate the dataset and identify duplicate records.

`data_cleaning2` was used as the main table for the subsequent cleaning and transformation operations.

---

## 2. Identifying Duplicate Records

The dataset did not contain a dedicated unique row identifier that could be used to immediately identify duplicate records.

I therefore used the SQL `ROW_NUMBER()` window function.

The records were partitioned using the combination of:

* Company
* Location
* Industry
* Total laid off
* Percentage laid off
* Date
* Stage
* Country
* Funds raised

This allowed identical records to be grouped and assigned sequential row numbers.

For example:

```sql
ROW_NUMBER() OVER (
    PARTITION BY company,
                 location,
                 industry,
                 total_laid_off,
                 percentage_laid_off,
                 `date`,
                 stage,
                 country,
                 funds_raised_millions
)
```

Records with:

```text
row_num = 1
```

were treated as the first occurrence.

Records with:

```text
row_num > 1
```

were identified as duplicate occurrences.

A CTE was used to make the window-function result available for filtering.

---

## 3. Removing Duplicates

After identifying the duplicate records, the row-numbering result was persisted in the working table.

This allowed records where:

```sql
row_num > 1
```

to be removed.

The original `layoffs` table remained unchanged.

This separation helped reduce the risk of accidentally modifying the source data.

---

## 4. Standardizing the Data

After duplicate removal, I investigated the consistency of the categorical and text-based columns.

### Company Names

Leading and trailing whitespace was removed using:

```sql
TRIM(company)
```

This ensured that values containing unnecessary whitespace were standardized.

### Industry

Different variations of cryptocurrency-related industry values were identified.

Values matching:

```text
Crypto%
```

were standardized to:

```text
Crypto
```

This reduces unnecessary category fragmentation during future analysis.

### Country

Some records contained:

```text
United States.
```

while others contained:

```text
United States
```

The trailing period was removed to standardize the country value.

---

## 5. Standardizing Dates

The original date values were stored as text.

They were converted into MySQL `DATE` values using:

```sql
STR_TO_DATE(`date`, '%m/%d/%Y')
```

The column was then changed to the `DATE` data type.

This makes the column more suitable for:

* Date filtering
* Sorting
* Time-based analysis
* Year/month extraction
* Date comparisons

---

## 6. Handling NULL and Blank Values

I investigated missing and blank values rather than immediately deleting them.

For example, blank industry values were identified using:

```sql
WHERE industry IS NULL
   OR industry = ''
```

Blank strings were first converted to `NULL` to create a consistent representation of missing information.

I then investigated whether the missing industry information could be recovered from other records belonging to the same company.

Where another record for the same company contained a known industry, that existing information was used to populate the missing value.

This approach avoided simply replacing missing values with assumptions or arbitrary categories.

---

## 7. Removing Records With Insufficient Information

After investigating the missing values, I removed records where both:

* `total_laid_off`
* `percentage_laid_off`

were unavailable.

These fields are important measures for analysing the scale of layoffs.

Records missing both measures therefore provided insufficient information for the intended analysis.

The decision was based on **analytical usefulness**, rather than simply removing every row containing a NULL value.

---

## 8. Removing Temporary Columns

The `row_num` column was created specifically to support duplicate identification and removal.

Once duplicate records had been handled, the temporary column was no longer required.

It was therefore removed from the final cleaned dataset.

---

## SQL Techniques Used

This project used several SQL techniques that are relevant to practical data analysis and data preparation:

* `SELECT`
* `WHERE`
* `JOIN`
* `DELETE`
* `UPDATE`
* `ALTER TABLE`
* `TRIM()`
* `STR_TO_DATE()`
* `LIKE`
* `IS NULL`
* Common Table Expressions (CTEs)
* Window functions
* `ROW_NUMBER()`
* Data type conversion

---

## Data Quality Issues Identified

The cleaning process identified several types of data-quality issues:

| Issue                               | Treatment                                   |
| ----------------------------------- | ------------------------------------------- |
| Duplicate records                   | Identified using `ROW_NUMBER()` and removed |
| Extra whitespace                    | Removed using `TRIM()`                      |
| Inconsistent industry values        | Standardized                                |
| Inconsistent country values         | Standardized                                |
| Dates stored as text                | Converted to `DATE`                         |
| Blank industry values               | Converted to `NULL` and investigated        |
| Recoverable missing industry values | Populated using existing company records    |
| Records missing key layoff measures | Removed                                     |
| Temporary `row_num` column          | Removed after duplicate processing          |

---

## Key Data-Cleaning Principles Applied

### Preserve the raw data

The original dataset was kept unchanged so that the cleaning process could always be traced back to the source.

### Investigate before modifying

Potential problems were investigated before applying `UPDATE` or `DELETE` operations.

### Do not automatically delete missing data

Missing values were assessed based on whether they affected the intended analysis.

### Use existing information where possible

Missing industry values were recovered where reliable information for the same company existed elsewhere in the dataset.

### Standardize before analysis

Inconsistent categories and formats can produce misleading results during aggregation and exploratory analysis.

---

## What I Learned

This project helped me move beyond writing SQL queries for individual questions and start thinking about SQL as part of a broader analytical workflow.

The main lessons were:

1. Data analysis should begin with understanding the quality of the underlying data.
2. Duplicate detection can require window functions when a dataset does not provide a convenient unique identifier.
3. CTEs can make intermediate analytical results easier to inspect and filter.
4. Missing data should be investigated before deciding whether it should be removed.
5. Data standardization is important before performing categorical analysis.
6. Cleaning decisions should be based on the intended use of the data.
7. Preserving the original dataset is important when performing destructive transformations.
8. SQL is not only used to retrieve data; it can also be used to prepare data for analysis.

---

## Limitations

The cleaning decisions in this project were based on the structure and values available in the dataset.

Some missing values could be recovered from other records, while others could not.

The project does not attempt to determine whether every unusual value represents a genuine business event or a data-entry error. Further validation against the original source system would be required for production use.

---

## Next Step

The cleaned dataset can now be used for exploratory analysis and visualization.

Potential next analyses include:

* Layoffs by year
* Layoffs by industry
* Layoffs by country
* Companies with the largest layoffs
* Layoff trends over time
* Relationship between company stage and layoffs
* Total layoffs by industry

---

## Skills Demonstrated

**SQL**

* Data cleaning
* Data transformation
* Data-quality assessment
* Duplicate detection
* Window functions
* CTEs
* Joins
* Conditional filtering
* String manipulation
* Date transformation
* NULL handling
* Table modification

**Analytical Skills**

* Data-quality investigation
* Problem solving
* Transformation reasoning
* Assumption identification
* Analytical decision-making
* Reproducible data preparation

---

## Author

**Simamkele Sikani**

Junior Data Analyst | SQL | Python | Data Analysis

This project is part of my practical data analytics portfolio, where I am developing my ability to work with real-world datasets from data preparation through analysis and reporting.
