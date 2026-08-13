# Global Layoffs — Data Cleaning & Exploratory Data Analysis

## Project Overview

This project demonstrates an end-to-end SQL data analysis workflow using a global layoffs dataset.

The project focuses on two major stages of the data analysis process:

1. Data Cleaning
2. Exploratory Data Analysis (EDA)

The objective was to take a raw dataset, identify and resolve data-quality issues, prepare the data for analysis, and then use SQL to explore patterns and trends in global layoffs.

This project was completed using MySQL.

---

## Business Objective

The objective of this analysis is to understand patterns in company layoffs across different:

- Companies
- Industries
- Countries
- Company stages
- Years
- Months

The analysis also investigates which companies experienced the highest layoffs and how layoffs changed over time.

---

## Dataset

The dataset contains information about company layoffs, including:

- Company
- Location
- Industry
- Total employees laid off
- Percentage of employees laid off
- Date
- Company stage
- Country
- Funds raised

The original raw data was preserved separately before cleaning.

---

# Project Workflow

The project follows this workflow:

```text
Raw Data
   ↓
Data Quality Assessment
   ↓
Duplicate Identification
   ↓
Duplicate Removal
   ↓
Data Standardization
   ↓
NULL / Blank Value Handling
   ↓
Removal of Unusable Records
   ↓
Data Validation
   ↓
Exploratory Data Analysis
   ↓
Business Insights
1. Data Cleaning

The first stage of the project focused on preparing the raw dataset for analysis.

Raw Data

The original dataset was stored in the layoffs table.

I preserved the raw data so that the cleaning process could be performed without modifying the original source.

Working Tables

Additional tables were created during the cleaning process:

data_cleaning
data_cleaning2

These tables were used to perform and validate the transformation process.

Duplicate Identification

The dataset did not contain a unique row identifier that could be used to directly identify duplicate records.

To solve this, I used a combination of columns to determine whether records represented duplicate observations.

I used the ROW_NUMBER() window function:

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

This generated a row number for records sharing the same values across the selected columns.

Records with:

row_num > 1

were treated as duplicates.

A CTE was initially used to inspect these records before permanently removing them from the working table.

Data Standardization

After removing duplicates, I standardized inconsistent values.

Company Names

Leading and trailing whitespace was removed using:

TRIM(company)
Industry

Different variations of cryptocurrency-related industry values were standardized into:

Crypto
Country

Trailing periods were removed from country names such as:

United States.

so that they became:

United States
Date

The original date values were stored as text.

They were converted into proper MySQL DATE values using:

STR_TO_DATE(date, '%m/%d/%Y')

The column was then converted to the DATE data type.

NULL and Blank Values

The dataset contained missing and blank values.

I first identified records where the industry column was either:

industry IS NULL

or:

industry = ''

Blank industry values were converted to NULL.

I then used a self-join to identify companies where one record contained a missing industry while another record for the same company contained the correct industry.

This allowed missing industry values to be repopulated from existing records rather than guessing the missing information.

Removing Unusable Records

Some records did not contain enough information to support meaningful analysis.

Records where both the number of employees laid off and the percentage laid off were unavailable were removed.

The purpose was to prevent incomplete records from affecting the analysis.

Data Validation

After cleaning, I reviewed the resulting dataset to ensure that:

Duplicate records had been removed.
Company names were standardized.
Industry values were standardized.
Country names were standardized.
Dates were converted into the correct data type.
Missing industry values that could be reasonably recovered were populated.
Records without meaningful layoff information were removed.
2. Exploratory Data Analysis

After completing the cleaning process, I used the cleaned dataset for exploratory analysis.

The EDA was designed to answer questions about the scale, distribution, and timing of layoffs.

Maximum Layoffs

I identified the maximum:

Total number of employees laid off in a single record
Percentage of employees laid off

This provides an initial understanding of the most severe individual layoff events.

Companies With 100% Layoffs

I identified companies where:

percentage_laid_off = 1

These records represent companies that reported layoffs equivalent to 100% of their workforce.

The results were ordered by funds raised to provide additional context.

Companies With the Highest Total Layoffs

I grouped layoffs by company and calculated the total number of employees laid off.

This identifies companies that experienced the largest overall workforce reductions in the dataset.

Annual Company Layoff Analysis

I grouped layoffs by:

Company
Year

and calculated total layoffs for each company-year combination.

A DENSE_RANK() window function was then used to identify the top five companies by layoffs for each year.

This allows the analysis to compare the largest layoff events across different years.

Industry Analysis

Layoffs were grouped by industry to identify which industries experienced the highest total number of layoffs.

Country Analysis

Layoffs were grouped by country to identify geographic patterns in workforce reductions.

Yearly Layoff Trends

The total number of layoffs was grouped by year to identify changes in layoffs over time.

Company Stage Analysis

Layoffs were grouped by company stage to investigate whether certain stages of company development were associated with higher numbers of layoffs.

Monthly Layoff Trends

The dataset was also analyzed at the monthly level.

The date was converted into a:

YYYY-MM

format and total layoffs were calculated for each month.

This makes it possible to identify periods with unusually high layoff activity.

Rolling Layoff Analysis

A Common Table Expression was used to prepare monthly layoff totals.

A window function was then used to calculate a cumulative total over time:

SUM(total_laid_off)
OVER (
    ORDER BY month
)

This provides a running total of layoffs throughout the dataset's timeline.

SQL Concepts Demonstrated

This project demonstrates practical use of the following MySQL concepts:

SELECT
WHERE
GROUP BY
ORDER BY
HAVING
Aggregate functions
JOIN
Self joins
CASE
String functions
Date functions
STR_TO_DATE()
TRIM()
SUBSTRING()
Common Table Expressions (CTEs)
Window functions
ROW_NUMBER()
DENSE_RANK()
SUM() OVER()
Data type conversion
UPDATE
DELETE
ALTER TABLE
Key Skills Demonstrated
Data Cleaning
Identifying duplicate records
Removing duplicates
Standardizing inconsistent values
Handling NULL and blank values
Recovering missing information using existing records
Converting data types
Removing unusable records
Validating cleaned data
Data Analysis
Aggregation
Grouping
Ranking
Trend analysis
Time-based analysis
Industry analysis
Geographic analysis
Company-level analysis
Cumulative analysis
SQL

The project demonstrates how SQL can be used throughout the analytical workflow, from raw data preparation through exploratory analysis.

Project Structure
layoffs-data-analysis/
│
├── README.md
│
├── data/
│   └── README.md
│
├── sql/
│   ├── 01_data_cleaning.sql
│   └── 02_exploratory_data_analysis.sql
│
└── documentation/
    └── data_cleaning_notes.md
Tools Used
MySQL
MySQL Workbench
Git
GitHub
What I Learned

This project helped me understand that data analysis does not begin with immediately querying the data for insights.

The process begins with understanding the dataset and assessing its quality.

The workflow I followed was:

Understand the data
       ↓
Assess data quality
       ↓
Clean the data
       ↓
Validate the data
       ↓
Explore the data
       ↓
Identify patterns
       ↓
Generate insights

I also gained practical experience using CTEs and window functions to solve problems that would be difficult to solve using basic aggregation alone.

Future Improvements

The next stage of this project will focus on presenting the findings visually.

Planned improvements include:

Exporting relevant analytical results
Building visualizations
Creating a dashboard
Adding deeper time-series analysis
Investigating relationships between funding and layoffs
Exploring additional business questions
Author

Simamkele Sikani

Aspiring Junior Data Analyst focused on SQL, data cleaning, exploratory analysis, Python, Excel, and data visualization.

GitHub: SimamkeleSikani06


### One important portfolio decision

I would **keep the repository exactly as one project** and eventually turn it into:

**Raw Data → SQL Cleaning → SQL EDA → Excel/Tableau Visualization → Business Insights**

That is much more compelling for a junior data analyst portfolio than having a repository that only says *"I know SQL."*

It shows that you can take a messy dataset and actually **work with it from beginning to end**.
Today 6:23 PM
give me readme

Absolutely. Since you’re keeping data cleaning + exploratory data analysis in one repository, that is the better structure for this project. It tells a complete analyst story:

Raw data → Cleaning → Validation → Exploration → Insights

Here is a README ready to copy and paste:

# Layoffs Data Analysis — MySQL

## Project Overview

This project demonstrates an end-to-end data analysis workflow using MySQL, starting with raw layoffs data, cleaning and standardizing the dataset, and then performing exploratory data analysis (EDA).

The purpose of the project is to demonstrate practical SQL skills and show how raw data can be transformed into a reliable dataset that can be used to investigate business questions and identify patterns.

The project currently focuses on two stages:

1. **Data Cleaning**
2. **Exploratory Data Analysis**

The cleaned dataset will later be used for visualization and further analysis.

---

## Business Objective

The objective of this project is to clean and explore layoffs data to understand patterns in layoffs across:

- Companies
- Industries
- Countries
- Company stages
- Years
- Months
- Funding levels

The analysis also investigates companies with the highest layoffs and identifies yearly and monthly patterns in layoffs.

---

## Dataset

The project uses a layoffs dataset containing information about companies and employee layoffs.

The main fields include:

| Column | Description |
|---|---|
| `company` | Company name |
| `location` | Company location |
| `industry` | Industry of the company |
| `total_laid_off` | Number of employees laid off |
| `percentage_laid_off` | Percentage of workforce laid off |
| `date` | Date of the layoff event |
| `stage` | Company funding/business stage |
| `country` | Country |
| `funds_raised_millions` | Funds raised by the company in millions |

---

# Project Workflow

The project follows this workflow:

```text
Raw Data
   ↓
Data Inspection
   ↓
Duplicate Detection
   ↓
Duplicate Removal
   ↓
Data Standardization
   ↓
NULL / Blank Value Handling
   ↓
Invalid / Incomplete Row Removal
   ↓
Clean Dataset
   ↓
Exploratory Data Analysis
   ↓
Pattern & Trend Identification
   ↓
Future Visualization
1. Data Cleaning

The original raw dataset is stored separately from the cleaned working table.

Raw Table
layoffs

This table represents the original dataset and is preserved so that the cleaning process can be reproduced.

Cleaning Tables
data_cleaning
data_cleaning2

The cleaning process involved several stages.

1.1 Duplicate Detection

The dataset did not contain a reliable unique identifier for every row.

To identify duplicate records, I used a combination of columns and the ROW_NUMBER() window function.

ROW_NUMBER() OVER (
    PARTITION BY company,
                 location,
                 industry,
                 total_laid_off,
                 percentage_laid_off,
                 date,
                 stage,
                 country,
                 funds_raised_millions
)

This generated a row number for records containing identical values across the selected columns.

A CTE was then used to identify records where:

row_num > 1

This allowed duplicate records to be identified before removal.

1.2 Duplicate Removal

After identifying duplicates, the records with a row number greater than 1 were removed.

DELETE
FROM data_cleaning2
WHERE row_num > 1;

The first occurrence of each duplicated record was retained.

1.3 Data Standardization

The dataset contained inconsistent formatting that needed to be standardized.

Company Names

Whitespace was removed using:

TRIM(company)
Industry

Industry values beginning with Crypto were standardized to:

Crypto
Country

Trailing periods were removed from country names such as:

United States.

so that they were consistently represented as:

United States
Dates

The original date values were converted into MySQL DATE format using:

STR_TO_DATE(date, '%m/%d/%Y')

The column was then changed to the DATE data type.

1.4 NULL and Blank Values

NULL and blank values were investigated after standardization.

For the industry column, blank values were converted to NULL.

Where another record for the same company contained a valid industry value, that information was used to populate the missing value.

This was achieved using a self-join.

The logic was:

Same company
      ↓
One record has missing industry
      ↓
Another record has a valid industry
      ↓
Use the valid industry value

This allowed missing information to be recovered without manually entering values.

1.5 Removing Incomplete Records

Rows without sufficient layoff information were removed.

The final cleaning logic removes records where both:

total_laid_off

and

percentage_laid_off

are unavailable.

These records do not provide enough information for meaningful layoffs analysis.

2. Exploratory Data Analysis

After cleaning the dataset, I used SQL to investigate patterns and relationships within the data.

The exploratory analysis focused on several areas.

2.1 Maximum Layoffs

I identified the maximum values for:

Total employees laid off
Percentage of workforce laid off

This establishes the upper limits of the dataset.

2.2 Companies With 100% Workforce Layoffs

Companies where:

percentage_laid_off = 1

were investigated.

These represent companies that reported laying off their entire workforce.

The results were ordered by funds raised to provide additional context.

2.3 Companies With the Highest Total Layoffs

The total number of layoffs was aggregated by company.

SUM(total_laid_off)

This was used to identify companies associated with the highest total number of layoffs.

2.4 Yearly Company Rankings

I calculated total layoffs by company and year.

A DENSE_RANK() window function was then used to identify the top five companies by layoffs for each year.

This analysis demonstrates the use of:

CTEs
Aggregation
DENSE_RANK()
PARTITION BY
Window functions
2.5 Date Range

The minimum and maximum dates in the dataset were identified to understand the period covered by the data.

2.6 Layoffs by Industry

Total layoffs were grouped by industry to determine which industries experienced the largest number of reported layoffs.

2.7 Layoffs by Country

Total layoffs were grouped by country to identify the countries with the highest reported layoffs.

2.8 Layoffs by Company Stage

Layoffs were grouped by company stage to investigate whether certain stages of companies experienced higher levels of layoffs.

2.9 Monthly Layoff Trends

Layoffs were aggregated by month to identify changes over time.

The analysis used the date field to extract:

YYYY-MM

and calculate total layoffs for each month.

2.10 Rolling Total

A cumulative rolling total of layoffs was calculated using a window function:

SUM(total_laid_off)
OVER (
    ORDER BY month
)

This shows how total reported layoffs accumulated over time.

SQL Concepts Demonstrated

This project demonstrates practical use of the following MySQL concepts:

Data Retrieval
SELECT
WHERE
ORDER BY
GROUP BY
HAVING
Data Transformation
TRIM
STR_TO_DATE
SUBSTRING
YEAR
Aggregation
SUM()
AVG()
MIN()
MAX()
COUNT()
Data Cleaning
UPDATE
DELETE
ALTER TABLE
NULL handling
Blank-value handling
Duplicate detection
Data standardization
Advanced SQL
CTEs
Window functions
ROW_NUMBER()
DENSE_RANK()
PARTITION BY
Rolling calculations
Self-joins
Key Learning Outcomes

Through this project, I practiced the complete SQL workflow from raw data to exploratory analysis.

The main lessons were:

Data analysis should begin by understanding the structure and quality of the dataset.
Duplicate records can be identified using window functions when a unique identifier is unavailable.
Data standardization is necessary before aggregation and analysis.
Missing values should be investigated before being removed.
Existing records can sometimes be used to recover missing information.
Incomplete records should only be removed when they cannot support the intended analysis.
CTEs can make complex SQL analysis easier to structure.
Window functions are useful for ranking, cumulative calculations, and comparing records within groups.
Cleaning and exploratory analysis are connected stages of the same analytical workflow.
Project Structure
layoffs-data-analysis/
│
├── README.md
│
├── data/
│   └── layoffs.csv
│
├── sql/
│   ├── data_cleaning.sql
│   └── exploratory_data_analysis.sql
│
└── documentation/
    └── data_cleaning_notes.md

MySQL
SQL
Git
GitHub
Author

Simamkele Sikani
