-- HR Analysis Project--

-- Data Cleaning and transformation -- 

SELECT *
FROM hr;

-- Changing the names of columns

ALTER TABLE hr
CHANGE COLUMN ï»¿id emp_id VARCHAR(25) NOT NULL;

ALTER TABLE hr
RENAME COLUMN birthdate to birth_date;

ALTER TABLE hr
RENAME COLUMN jobtitle TO job_title;

ALTER TABLE hr
RENAME COLUMN termdate TO term_date;


-- Changing the data types and fixing the date columns

DESC hr;

SELECT birth_date
FROM hr;

SET sql_safe_updates = 0;

UPDATE hr
SET birth_date = CASE
	WHEN birth_date LIKE "%/%" THEN DATE_FORMAT(STR_TO_DATE(birth_date,"%m/%d/%Y"),"%Y-%m-%d")
    WHEN birth_date LIKE "%-%" THEN DATE_FORMAT(STR_TO_DATE(birth_date,"%m-%d-%Y"),"%Y-%m-%d")
    ELSE NULL
END;

ALTER TABLE hr
MODIFY COLUMN birth_date DATE;

DESC hr;

UPDATE hr
SET hire_date = CASE
	WHEN hire_date LIKE "%/%" THEN DATE_FORMAT(STR_TO_DATE(hire_date,"%m/%d/%Y"), "%Y-%m-%d")
	WHEN hire_date LIKE "%-%" THEN DATE_FORMAT(STR_TO_DATE(hire_date,"%m-%d-%Y"), "%Y-%m-%d")
    ELSE NULL
END;

ALTER TABLE hr
MODIFY COLUMN hire_date DATE;
    
SELECT hire_date
FROM hr;

DESC hr;

UPDATE hr
SET term_date = DATE(STR_TO_DATE(term_date,"%Y-%m-%d %H:%i:%s UTC"))
WHERE term_date IS NOT NULL AND term_date != "";

SELECT term_date
FROM hr;

SET SQL_MODE = "";

ALTER TABLE hr
MODIFY COLUMN term_date DATE;

DESC hr;

SELECT *
FROM hr;


-- Creating a new age column

ALTER TABLE hr
ADD COLUMN age INT ;

UPDATE hr
SET age = timestampdiff(YEAR,birth_date,CURDATE());


SELECT COUNT(*)
FROM hr
WHERE age < 0;

-- Fixing the error in birth date

UPDATE hr
SET birth_date = DATE_SUB(birth_date, INTERVAL 100 YEAR)
WHERE age < 0;

-- Creating a view excluding the terminated employees

CREATE VIEW hrr AS
SELECT *
FROM hr
WHERE term_date = "0000-00-00";

SELECT *
FROM hrr;


-- Data Analysis and answering questions --


-- Youngest and oldest employee 

SELECT MIN(age) AS youngest, MAX(age) AS oldest
FROM hrr;

-- Gender breakdown of employees

SELECT gender, COUNT(*) AS count
FROM hrr
GROUP BY gender;

-- Ethnicity breakdown of employees

SELECT race, COUNT(*) AS count
FROM hrr
GROUP BY race
ORDER BY 2 DESC;

-- Age distribution of employees

SELECT MIN(age) AS youngest, MAX(age) AS oldest
FROM hrr;

SELECT 
CASE
	WHEN age >= 18 AND age <= 24 THEN "18-24"
    WHEN age >= 25 AND age <= 34 THEN "25-34"
    WHEN age >= 35 AND age <= 44 THEN "35-44"
    WHEN age >= 45 AND age <= 54 THEN "45-54"
    WHEN age >= 55 AND age <= 64 THEN "55-64"
    ELSE "65+"
END AS age_group, COUNT(*) AS count
FROM hrr
GROUP BY age_group
ORDER BY age_group;

-- Age group by gender

SELECT 
CASE
	WHEN age >= 18 AND age <= 24 THEN "18-24"
    WHEN age >= 25 AND age <= 34 THEN "25-34"
    WHEN age >= 35 AND age <= 44 THEN "35-44"
    WHEN age >= 45 AND age <= 54 THEN "45-54"
    WHEN age >= 55 AND age <= 64 THEN "55-64"
    ELSE "65+"
END AS age_group, gender,COUNT(*) AS count
FROM hrr
GROUP BY age_group,gender
ORDER BY age_group,gender;

-- Employees work at headquarters vs remote locations

SELECT location, COUNT(*) AS count
FROM hrr
GROUP BY location;

-- Average length of employment who have been terminated

SELECT ROUND(AVG(DATEDIFF(term_date,hire_date))/365,0) AS avg_lenth_employment
FROM hr
WHERE term_date <= CURDATE() AND term_date != "0000-00-00";

-- Gender distribution vary across departments and job titles

SELECT department, gender, COUNT(*) AS count
FROM hrr
GROUP BY department, gender
ORDER BY department, gender;

-- Distribution of job titles

SELECT job_title, COUNT(*) AS count
FROM hrr
GROUP BY job_title
ORDER BY job_title DESC;

-- department with highest turnover rate

SELECT department,
	total_count,
    terminated_count,
    terminated_count/total_count AS termination_rate
FROM (
	SELECT department,
		COUNT(*) AS total_count,
        SUM(CASE WHEN term_date != "0000-00-00" AND term_date <= CURDATE() THEN 1 ELSE 0 END) AS terminated_count 
        FROM hr
        GROUP BY department) AS sub_query
ORDER BY termination_rate DESC;

-- Distribution of employees across locations by city and state

SELECT location_state, COUNT(*) AS count
FROM hrr
GROUP BY location_state
ORDER BY 2 DESC;

-- Employee count changed over time based on hire and term dates

SELECT year,
	hires,
    terminations,
    hires-terminations AS net_change,
	ROUND((hires-terminations)/hires*100,2) AS net_change_percent
FROM (
	SELECT YEAR(hire_date) AS year,
		COUNT(*) AS hires,
        SUM(CASE WHEN term_date != "0000-00-00" AND term_date <= CURDATE() THEN 1 ELSE 0 END) AS terminationS
        FROM hr
        GROUP BY 1) AS sub_query
ORDER BY 1 ASC;

-- Tenure distribution for each department

SELECT department, ROUND(AVG(DATEDIFF(term_date, hire_date)/365),0) AS avg_tenure
FROM hr
WHERE term_date != "0000-00-00" AND term_date <= CURDATE()
GROUP BY department
ORDER BY 2 DESC;
