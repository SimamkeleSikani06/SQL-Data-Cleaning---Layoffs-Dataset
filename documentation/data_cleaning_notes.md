# Data Cleaning Documentation

## Project: Layoffs Data Analysis

**Author:** Simamkele Sikani  
**Tool:** MySQL  
**Dataset:** Layoffs Dataset

---

# 1. Purpose of the Data Cleaning Process

The purpose of this cleaning process was to transform the original layoffs dataset into a more reliable dataset that could be used for exploratory data analysis.

The raw dataset contained several issues, including:

- Duplicate records
- Inconsistent text formatting
- Inconsistent industry names
- Inconsistent country names
- Dates stored as text
- NULL values
- Blank values
- Missing industry information
- Records without sufficient information for layoffs analysis

The objective was not simply to remove problematic records, but to investigate the problems first and determine whether the information could be corrected or recovered.

---

# 2. Original Data Structure

The original dataset was stored in:

```text
layoffs

This table was treated as the raw source data.

I kept the raw table unchanged so that the original dataset would remain available for comparison and so that the cleaning process could be reproduced if necessary.

The cleaning workflow created additional tables:

layoffs
    ↓
data_cleaning
    ↓
data_cleaning2

The purpose of these tables was to separate the original data from the working versions used during the cleaning process.

3. Data Cleaning Workflow

The cleaning process followed this general sequence:

Raw Data
   ↓
Inspect Dataset
   ↓
Identify Duplicates
   ↓
Create Row Numbers
   ↓
Remove Duplicates
   ↓
Standardize Values
   ↓
Investigate NULL / Blank Values
   ↓
Recover Missing Information Where Possible
   ↓
Remove Records With Insufficient Information
   ↓
Final Clean Dataset
4. Duplicate Detection
Problem

The dataset did not contain a reliable unique identifier that could be used to determine whether two records represented the same event.

Because of this, I needed to identify duplicate records using a combination of columns.

The columns used to identify duplicates were:

company
location
industry
total_laid_off
percentage_laid_off
date
stage
country
funds_raised_millions
5. Using ROW_NUMBER()

I used the ROW_NUMBER() window function to assign a number to records that had identical values across the selected columns.

The logic was:

ROW_NUMBER() OVER (
    PARTITION BY
        company,
        location,
        industry,
        total_laid_off,
        percentage_laid_off,
        date,
        stage,
        country,
        funds_raised_millions
)

This allowed identical records to be grouped together and numbered.

For example:

Company A → row_num = 1
Company A → row_num = 2
Company A → row_num = 3

The first record could be retained while records with:

row_num > 1

could be treated as duplicates.

6. Using a CTE to Inspect Duplicates

I created a Common Table Expression (CTE) to make the duplicate identification process easier to inspect.

The CTE generated the row numbers and then allowed me to filter for:

WHERE row_num > 1

This was useful because the window function itself was being used to generate the row number.

The CTE therefore acted as an intermediate result that allowed me to inspect the records produced by the window function.

7. Creating a Working Table

The next step was creating a working table containing the generated row numbers.

The reason for this was practical:

I needed to manipulate the results of the window function and delete duplicate records.

The working table allowed the generated row_num value to become an actual column that could be used during the deletion process.

The workflow was therefore:

Raw table
   ↓
Create working table
   ↓
Generate row_num
   ↓
Identify row_num > 1
   ↓
Delete duplicates
8. Removing Duplicate Records

Once duplicate records had been identified, records where:

row_num > 1

were deleted.

DELETE
FROM data_cleaning2
WHERE row_num > 1;

This retained the first occurrence and removed subsequent duplicate records.

After the deletion, the temporary row_num column was no longer required and was removed.

9. Data Standardization

After duplicate removal, I moved to standardizing the dataset.

The purpose of standardization was to ensure that values representing the same thing were stored consistently.

This is important because inconsistent values can produce incorrect results during aggregation.

For example:

Crypto
Crypto Currency
Crypto...

could potentially be interpreted as different industries.

10. Standardizing Company Names

Whitespace was removed from company names using:

TRIM(company)

The update was applied to the working table.

This prevents values such as:

"Airbnb"
" Airbnb "

from being treated as different values.

11. Standardizing Industry Values

The industry column contained multiple values beginning with Crypto.

I investigated these values using:

SELECT DISTINCT industry
FROM data_cleaning2
WHERE industry LIKE 'Crypto%';

After confirming the inconsistent values, they were standardized to:

Crypto

This was done using:

UPDATE data_cleaning2
SET industry = 'Crypto'
WHERE industry LIKE 'Crypto%';

The purpose was to ensure that all Crypto-related records were grouped consistently during analysis.

12. Standardizing Country Values

Some country values contained trailing punctuation.

For example, the United States appeared with an unnecessary trailing period.

I first inspected the values using:

SELECT DISTINCT country,
       TRIM(TRAILING '.' FROM country)
FROM data_cleaning2
WHERE country LIKE 'United States%';

The unnecessary punctuation was then removed.

UPDATE data_cleaning2
SET country = TRIM(TRAILING '.' FROM country)
WHERE country LIKE 'United States%';

This ensured that the country values could be grouped consistently.

13. Converting the Date Column

The original date column was stored as text.

This presented a problem because date operations such as:

YEAR()
MONTH()
date comparisons
chronological sorting

are more reliable when the column is stored as a proper date data type.

I first converted the text values using:

STR_TO_DATE(date, '%m/%d/%Y')

The column was then changed to the MySQL DATE data type.

This allowed the date column to be used properly during exploratory analysis.

14. NULL and Blank Value Investigation

After standardization, I investigated NULL and blank values.

For example:

SELECT *
FROM data_cleaning2
WHERE industry IS NULL
   OR industry = '';

This allowed me to determine whether missing information existed and whether it could be recovered.

An important principle I followed was:

Missing data should be investigated before it is deleted.

A NULL value does not automatically mean that the record should be removed.

15. Recovering Missing Industry Values

The industry column contained some missing values.

I investigated whether the same company appeared elsewhere in the dataset with a valid industry value.

The logic was:

Company has missing industry
        ↓
Search for another record for the same company
        ↓
Another record contains a valid industry
        ↓
Use that value to populate the missing field

I used a self-join to identify these cases.

Conceptually:

FROM data_cleaning2 t1
JOIN data_cleaning2 t2
    ON t1.company = t2.company

The first table represented the record with the missing value, while the second represented another record for the same company.

The missing industry was then populated using the valid value from the matching record.

This was preferable to deleting the record because the missing value could be reasonably recovered from existing data.

16. Handling Blank Industry Values

Blank industry values were first converted to NULL:

UPDATE data_cleaning2
SET industry = NULL
WHERE industry = '';

This made the missing-value state consistent.

Instead of having both:

''
NULL

representing missing information, the dataset used:

NULL

for missing industry values.

17. Removing Records With Insufficient Information

After investigating missing values, I evaluated whether some records contained enough information to support the intended analysis.

The two most important fields for the layoffs analysis were:

total_laid_off
percentage_laid_off

If both values were unavailable, the record could not provide meaningful information about the scale of the layoff.

Therefore, records where both fields were missing were removed.

The corrected logic is:

DELETE
FROM data_cleaning2
WHERE total_laid_off IS NULL
  AND percentage_laid_off IS NULL;
Important Correction

During the initial cleaning process, I used:

WHERE total_laid_off IS NULL
   OR percentage_laid_off IS NULL;

This was too aggressive.

Using OR removed records where only one of the two fields was missing.

For example:

total_laid_off = 500
percentage_laid_off = NULL

would have been deleted even though the record still contained useful information.

The corrected condition uses AND:

WHERE total_laid_off IS NULL
  AND percentage_laid_off IS NULL;

This removes only records where both measures are unavailable.

This correction was important because over-deleting records can change aggregate results and produce discrepancies during analysis.

18. Final Cleaning Step

After completing the cleaning process, the temporary row_num column was removed.

ALTER TABLE data_cleaning2
DROP COLUMN row_num;

The resulting table:

data_cleaning2

was then used as the cleaned dataset for exploratory data analysis.

19. Data Quality Principles Applied

The cleaning process followed several principles.

1. Preserve the raw data

The original table was not modified.

layoffs

remained available as the source dataset.

2. Investigate before deleting

Missing or inconsistent values were investigated before deciding whether they should be removed.

3. Standardize before analyzing

Text values and dates were standardized before aggregation.

4. Recover information where possible

Missing industry values were populated using valid information from other records for the same company.

5. Avoid unnecessary deletion

Records were only removed when they lacked sufficient information for the intended analysis.

6. Validate cleaning decisions

Cleaning decisions were checked against the resulting dataset and aggregate results.

20. Lessons Learned

This project taught me that data cleaning is not simply about removing NULL values and duplicates.

The main challenge is deciding what should happen to problematic data.

For example:

NULL

does not automatically mean:

DELETE

Instead, the analyst should ask:

Why is the value missing?
Can the value be recovered?
Does the record still provide analytical value?
Will deleting it introduce bias?

I also learned that cleaning logic can directly affect analytical results.

An incorrect condition such as:

WHERE A IS NULL OR B IS NULL

can remove significantly more data than intended.

Therefore, cleaning must be treated as an analytical process rather than simply a technical preprocessing step.

21. Relationship Between Cleaning and EDA

The cleaned dataset produced by this process was used for exploratory data analysis.

The workflow was:

Raw Dataset
      ↓
Data Quality Assessment
      ↓
Cleaning
      ↓
Validation
      ↓
Clean Dataset
      ↓
Exploratory Data Analysis
      ↓
Business Insights

The exploratory analysis investigated:

Total layoffs
Companies with the highest layoffs
Layoffs by year
Layoffs by month
Layoffs by industry
Layoffs by country
Layoffs by company stage
Companies with 100% workforce layoffs
Yearly company rankings
Cumulative layoffs over time
22. SQL Skills Demonstrated

This project demonstrates practical use of:

SELECT
WHERE
GROUP BY
ORDER BY
JOIN
UPDATE
DELETE
ALTER TABLE
TRIM
STR_TO_DATE
SUBSTRING
YEAR
LIKE
CASE
Aggregate functions
Common Table Expressions
Window functions
ROW_NUMBER()
DENSE_RANK()
PARTITION BY
Rolling calculations
Self-joins
23. Final Outcome

The final result is a cleaned layoffs dataset suitable for exploratory analysis.

The project demonstrates an end-to-end SQL workflow:

Raw Data
    ↓
Data Quality Investigation
    ↓
Duplicate Detection
    ↓
Duplicate Removal
    ↓
Standardization
    ↓
Missing Value Investigation
    ↓
Missing Value Recovery
    ↓
Incomplete Record Removal
    ↓
Validation
    ↓
Clean Dataset
    ↓
Exploratory Data Analysis

The cleaned dataset is now ready for further analysis and visualization using tools such as Excel or Tableau.
