-- THIS SCRIPT IS IN THE CLEANING PROCESS OF THE LAYOFFS DATA
-- WE WILL DO THESE STEPS
-- 1- REMOVING DUPLICATES
-- 2- STANDARDIZING DATA
-- 3- NULL VALUES AND BLANKS
-- 4- REMOVING COLUMNS AND ROWS

-- LET'S START OUR CLEANING PROCESS!

-- Displaying the initial table
SELECT * FROM world_layoffs.layoffs;

-- Creating another table for cleaning
CREATE TABLE layoffs_staging AS
SELECT * FROM layoffs;

-- Displaying the new table
SELECT * FROM layoffs_staging;

-- Creating ROW_NUMBER to identify the duplicates
SELECT *,
ROW_NUMBER() OVER (PARTITION BY company, location, industry, total_laid_off, percentage_laid_off, `date`, stage, country, funds_raised_millions) AS row_num
FROM layoffs_staging;

-- Identifying the duplicates by the new column row_num
WITH duplicates_cte AS (
SELECT *,
ROW_NUMBER() OVER (PARTITION BY company, location, industry, total_laid_off, percentage_laid_off, `date`, stage, country, funds_raised_millions) AS row_num
FROM layoffs_staging
)
SELECT *
FROM duplicates_cte
WHERE row_num > 1;

-- Checking if the duplicates are correct
SELECT *
FROM layoffs_staging
WHERE company = 'Casper';

-- Creating another new table to add the new column row_num to remove the duplicates because MySQL doesn't support delete from CTE
CREATE TABLE layoffs_staging2 (
  `company` TEXT,
  `location` TEXT,
  `industry` TEXT,
  `total_laid_off` INT DEFAULT NULL,
  `percentage_laid_off` TEXT,
  `date` TEXT,
  `stage` TEXT,
  `country` TEXT,
  `funds_raised_millions` INT DEFAULT NULL,
  `row_num` INT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

-- Inserting the necessary data and the new column into the new table
INSERT INTO layoffs_staging2
SELECT *,
ROW_NUMBER() OVER (PARTITION BY company, location, industry, total_laid_off, percentage_laid_off, `date`, stage, country, funds_raised_millions) AS row_num
FROM layoffs_staging;

-- Filtering in the new table to identify the duplicates
SELECT *
FROM layoffs_staging2
WHERE row_num > 1;

-- Removing duplicates
DELETE FROM layoffs_staging2
WHERE row_num > 1;

-- Checking to ensure that the duplicates are removed
SELECT *
FROM layoffs_staging2;

-- FINALLY NO DUPLICATES!

-- Now let's standardize our data

-- 1- First let's get rid of EXTRA SPACES
UPDATE layoffs_staging2
SET company = TRIM(company), location = TRIM(location), industry = TRIM(industry), stage = TRIM(stage), country = TRIM(country);

-- 2- Second let's check if there are any repeating names
SELECT DISTINCT industry
FROM layoffs_staging2
ORDER BY industry ASC;

-- So let's update these repeating names
UPDATE layoffs_staging2
SET industry = 'Crypto'
WHERE industry LIKE 'Crypto%';

-- We found another issue here at the COUNTRY column
SELECT DISTINCT country
FROM layoffs_staging2
WHERE country LIKE 'United States%';

-- So let's fix this issue
UPDATE layoffs_staging2
SET country = TRIM(TRAILING '.' FROM country)
WHERE country LIKE 'United States%';

-- Let's ensure that everything's updated
SELECT DISTINCT country
FROM layoffs_staging2
WHERE country LIKE 'United States%';

-- NOW let's fix the wrong data types like the date column
SELECT `date`, STR_TO_DATE(`date`, '%m/%d/%Y') AS date
FROM layoffs_staging2;

UPDATE layoffs_staging2
SET `date` = STR_TO_DATE(`date`, '%m/%d/%Y');

ALTER TABLE layoffs_staging2
MODIFY COLUMN `date` DATE;

-- Now let's get rid of NULLs and BLANKs as we could
SELECT *
FROM layoffs_staging2
WHERE (total_laid_off IS NULL OR total_laid_off = '')
AND (percentage_laid_off IS NULL OR percentage_laid_off = '');

-- We don't need companies which didn't have any layoffs! So let's remove these useless rows
DELETE FROM layoffs_staging2
WHERE (total_laid_off IS NULL OR total_laid_off = '')
AND (percentage_laid_off IS NULL OR percentage_laid_off = '');

-- Let's check if we have issues with the industry column
SELECT *
FROM layoffs_staging2
WHERE (industry IS NULL OR industry = '');

-- We have a blank value in the industry in the Airbnb company we can fix by updating the industry and fill this missing value 'Travel'
SELECT *
FROM layoffs_staging2
WHERE company = 'Airbnb';

UPDATE layoffs_staging2
SET industry = 'Travel'
WHERE company = 'Airbnb'
AND (industry IS NULL OR industry = '');

-- Let's check other values we can fix
SELECT *
FROM layoffs_staging2
WHERE (industry IS NULL OR industry = '');

-- We have another blank value in the industry in the Carvana company we can fix by updating the industry and fill this missing value 'Transportation'
SELECT *
FROM layoffs_staging2
WHERE company = 'Carvana';

UPDATE layoffs_staging2
SET industry = 'Transportation'
WHERE company = 'Carvana'
AND (industry IS NULL OR industry = '');

-- Let's clean all NULLs and BLANKs as we could!
SELECT *
FROM layoffs_staging2
WHERE (industry IS NULL OR industry = '');

-- We have another blank value in the industry in the Juul company we can fix by updating the industry and fill this missing value 'Consumer'
SELECT *
FROM layoffs_staging2
WHERE company = 'Juul';

UPDATE layoffs_staging2
SET industry = 'Consumer'
WHERE company = 'Juul'
AND (industry IS NULL OR industry = '');

-- Now let's remove any unnecessary columns
ALTER TABLE layoffs_staging2
DROP COLUMN row_num;

SELECT *
FROM layoffs_staging2;

-- FINALLY, THE CLEANING PROCESS IS DONE!


-- NOW let's start our analysis journey

-- First, let's explore max and min layoffs.

SELECT MIN(total_laid_off) AS min_laid_off, MAX(total_laid_off) AS max_laid_off
FROM layoffs_staging2;

-- Now let's explore the total layoff around the world.

SELECT SUM(total_laid_off) AS total_laid_off
FROM layoffs_staging2;

-- Okay, let's explore which company has the most total laid off!

SELECT company, SUM(total_laid_off) AS total_laid_off
FROM layoffs_staging2
GROUP BY company
ORDER BY total_laid_off DESC;

-- That's pretty good information!

-- Now let's explore which industry has the most total laid off!

SELECT industry, SUM(total_laid_off) AS total_laid_off
FROM layoffs_staging2
GROUP BY industry
ORDER BY total_laid_off DESC;

-- Now let's explore which country has the most total laid off!

SELECT country, SUM(total_laid_off) AS total_laid_off
FROM layoffs_staging2
GROUP BY country
ORDER BY total_laid_off DESC;

-- Now let's play with window functions and explore the min laid off for each country.

SELECT DISTINCT country, MIN(total_laid_off) OVER(PARTITION BY country) AS min_laid_off_each_country
FROM layoffs_staging2
ORDER BY min_laid_off_each_country DESC;

-- And the max too!

SELECT DISTINCT country, MAX(total_laid_off) OVER(PARTITION BY country) AS max_laid_off_each_country
FROM layoffs_staging2
ORDER BY max_laid_off_each_country DESC;

-- Okay, let's find out which year had the most layoffs!

SELECT DISTINCT `date`, MAX(total_laid_off) max_laid_off_by_date
FROM layoffs_staging2
GROUP BY `date`
ORDER BY max_laid_off_by_date DESC;

-- And the min too!

SELECT DISTINCT `date`, MIN(total_laid_off) min_laid_off_by_date
FROM layoffs_staging2 
GROUP BY `date`
HAVING MIN(total_laid_off) IS NOT NULL
ORDER BY min_laid_off_by_date;

-- Okay, maybe we also want to know the min and max layoffs for each industry.

SELECT DISTINCT industry, MIN(total_laid_off) OVER(PARTITION BY industry) AS min_laid_off_each_industry
FROM layoffs_staging2
WHERE industry IS NOT NULL
ORDER BY min_laid_off_each_industry DESC;

-- And for max:

SELECT DISTINCT industry, MAX(total_laid_off) OVER(PARTITION BY industry) AS max_laid_off_each_industry
FROM layoffs_staging2
WHERE industry IS NOT NULL
ORDER BY max_laid_off_each_industry DESC;

-- Let's explore which year and month had the most layoffs.

SELECT MONTH(`date`) AS month, MAX(total_laid_off) AS max_laid_off_by_month
FROM layoffs_staging2
WHERE MONTH(`date`) IS NOT NULL
GROUP BY month
ORDER BY max_laid_off_by_month DESC;

-- And for the year.

SELECT YEAR(`date`) AS year, MAX(total_laid_off) AS max_laid_off_by_year
FROM layoffs_staging2
WHERE YEAR(`date`) IS NOT NULL
GROUP BY year
ORDER BY max_laid_off_by_year DESC;

-- Let's explore which year and month had the lowest layoffs.

SELECT MONTH(`date`) AS month, MIN(total_laid_off) AS min_laid_off_by_month
FROM layoffs_staging2
WHERE MONTH(`date`) IS NOT NULL
GROUP BY month
ORDER BY min_laid_off_by_month;

-- And for the year.

SELECT YEAR(`date`) AS year, MIN(total_laid_off) AS min_laid_off_by_year
FROM layoffs_staging2
WHERE YEAR(`date`) IS NOT NULL
GROUP BY year
ORDER BY min_laid_off_by_year;

-- Let's explore the average layoffs by date.

-- For the month.

SELECT MONTH(`date`) AS month, ROUND(AVG(total_laid_off), 2) AS avg_laid_off_by_month 
FROM layoffs_staging2
WHERE MONTH(`date`) IS NOT NULL
GROUP BY month
ORDER BY avg_laid_off_by_month DESC;

-- For the year.

SELECT YEAR(`date`) AS year, ROUND(AVG(total_laid_off), 2) AS avg_laid_off_by_year 
FROM layoffs_staging2
WHERE YEAR(`date`) IS NOT NULL
GROUP BY year
ORDER BY avg_laid_off_by_year DESC;