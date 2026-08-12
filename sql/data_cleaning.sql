#DATA_CLEANING:
select * from layoffs;

-- create table data_cleaning
-- like  layoffs;
-- insert data_cleaning
-- select * from layoffs;

with view_duplicatesCTE as (
select * , 
row_number() over(
partition by company, location, industry, total_laid_off, percentage_laid_off, `date`, stage, country, funds_raised_millions) as row_num
from data_cleaning
) select * from view_duplicatesCTE
where row_num > 1;

-- CREATE TABLE `data_cleaning2` (
--    `company` text,
--    `location` text,
--    `industry` text,
--    `total_laid_off` int DEFAULT NULL,
--    `percentage_laid_off` text,
--    `date` text,
--    `stage` text,
--    `country` text,
--    `funds_raised_millions` int DEFAULT NULL,
--    `row_num` INT
-- ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

-- insert data_cleaning2
-- select * , 
-- row_number() over(
-- partition by company, location, industry, total_laid_off, percentage_laid_off, `date`, stage, country, funds_raised_millions) as row_num
-- from data_cleaning;

delete 
from data_cleaning2
where row_num > 1;


-- standardize the data

select distinct(company), trim(company)
from data_cleaning2;

update data_cleaning2 
set company = trim(company);

select distinct(industry)
from data_cleaning2
where industry like 'Crypto%';

update data_cleaning2
set industry = "Crypto"
where industry like 'Crypto%';



select distinct(country),
trim(trailing '.' from country)
from data_cleaning2
where country like "United States%";

update data_cleaning2
set country = trim(trailing '.' from country)
where country like "United States%";

select `date`, str_to_date(`date`, '%m/%d/%Y')
from data_cleaning2;

update data_cleaning2
set `date` = str_to_date(`date`, '%m/%d/%Y');

alter table data_cleaning2
modify `date` date;


-- null and blank values

select * from data_cleaning2
where industry is null or industry = ''
;

select * from data_cleaning2
where company in ( 'Airbnb', "Bally's Interactive", 'Carvana' , 'Juul' );

update data_cleaning2 
set industry = null 
where industry = '';

select *
from data_cleaning2 t1
join data_cleaning2 t2
on t1.company = t2.company
where t1.industry is null
and t2.industry is not null;

update data_cleaning2 t1
join data_cleaning2 t2
on t1.company = t2.company
set t1.industry = t2.industry
where t1.industry is null
and t2.industry is not null;

select * from data_cleaning2;

-- removing dead-end rows and columns

delete 
from data_cleaning2 
where (total_laid_off is null or total_laid_off = "")
and (percentage_laid_off is  null or percentage_laid_off = "");

alter table data_cleaning2 
drop column row_num;



