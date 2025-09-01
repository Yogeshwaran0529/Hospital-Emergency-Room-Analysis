SELECT *
FROM hospital_er_data_dup;

DESCRIBE hospital_er_data_dup;

-- AS we can see the datatype is differ and column name as some space inbetween so lets change 

ALTER TABLE hospital_er_data_dup
CHANGE `Patient Admission Date` admission_date Varchar(20),
CHANGE `Patient First Inital` firstname Varchar(20),
CHANGE `Patient Last Name` lastname Varchar(30),
CHANGE `Patient Gender` gender Varchar(10),
CHANGE `Patient Age` age INT,
ADD CONSTRAINT chk_age1 CHECK (age <=105),
CHANGE `Patient Race` patient_race  text,
CHANGE `Department Referral` Department_referral Varchar(20),
CHANGE `Patient Admission Flag` Patient_admission_flag VARCHAR(5),
CHANGE `Patient Satisfaction Score` satisfaction_score VARCHAR(10),
CHANGE `Patient Waittime` patient_wait_time INT,
ADD CONSTRAINT chk_waittime CHECK (patient_wait_time <= 60),
CHANGE `Patients CM` patient_cm VARCHAR(10)
;

SELECT *
FROM hospital_er_data_dup;

-- lets check any duplicate values

SELECT patient_id, count(*)
FROM hospital_er_data_dup
group by patient_id
Having Count(*) > 2;



-- Handle missing values (NULL)  

SELECT COUNT(*)
FROM hospital_er_data_dup
WHERE satisfaction_score IN (NULL,'NONE','NA','');

UPDATE hospital_er_data_dup
SET satisfaction_score = NULL WHERE Satisfaction_score = '';

SELECT Count(satisfaction_score)
FROM hospital_er_data_dup;


-- cleaning	Standardize text formats

UPDATE hospital_er_data_dup
SET gender = CASE
WHEN gender = 'M' THEN 'MALE'
WHEN gender = 'F'THEN 'FEMALE'
WHEN gender = 'NC' THEN 'OTHER'
END;

SELECT admission_date , 
TRIM(admission_date) 
FROM hospital_er_data_dup
WHERE admission_date <> TRIM(admission_date);


-- Ensure Date Columns Are Valid

SELECT DISTINCT
SUBSTRING(admission_date,12,2) AS hour,
SUBSTRING(admission_date,15,2) AS minute,
SUBSTRING(admission_date,1,2) AS date,
SUBSTRING(admission_date,4,2) AS month,
SUBSTRING(admission_date,7,4) AS year
FROM hospital_er_data_dup
WHERE SUBSTRING(admission_date,12,2) > 23 OR
SUBSTRING(admission_date,15,2) > 59 OR
SUBSTRING(admission_date,1,2) > 31 OR
SUBSTRING(admission_date,4,2) > 12 OR
SUBSTRING(admission_date,7,4) > 2024;

-- changing the admission_date column into date formate

SELECT 
admission_date,
STR_TO_DATE(admission_date, '%d-%m-%Y %H:%i') AS datetime_formate 
FROM hospital_er_data_dup;

ALTER TABLE hospital_er_data_dup
ADD admission_datetime DATETIME;


UPDATE hospital_er_data_dup 
SET admission_datetime = STR_TO_DATE(admission_date, '%d-%m-%Y %H:%i');

ALTER TABLE hospital_er_data_dup
MODIFY COLUMN admission_datetime DATETIME AFTER admission_date;


ALTER TABLE hospital_er_data_dup
DROP COLUMN admission_date;

ALTER TABLE hospital_er_data_dup
CHANGE COLUMN admission_datetime admission_date DATETIME;

ALTER TABLE hospital_er_data_dup
ADD PRIMARY KEY(patient_id);

SHOW KEYS FROM hospital_er_data_dup WHERE Key_name = 'PRIMARY';

SELECT *
FROM hospital_er_data_dup;

ALTER TABLE hospital_er_data_dup
MODIFY satisfaction_score INT,
MODIFY patient_cm INT;
 
-- lets add a full name by initial in front and last name besides it

SELECT firstname, lastname,
CONCAT(firstname, ' ', lastname) AS fullname, length(CONCAT(firstname, ' ', lastname)) as len
FROM hospital_er_data_dup
Order by len DESC;

ALTER TABLE hospital_er_data_dup
ADD COLUMN fullname VARCHAR(25) AFTER lastname;

UPDATE hospital_er_data_dup
SET fullname = CONCAT(firstname,' ',lastname);

ALTER TABLE hospital_er_data_dup
DROP COLUMN firstname,
DROP COLUMN lastname;

SELECT *
FROM hospital_er_data_dup;


-- Data Transformation Process
-- lets create a new column near admission_date for month and year 

ALTER TABLE hospital_er_data_dup
ADD COLUMN year INT AFTER admission_date,
ADD COLUMN month VARCHAR(20) AFTER year ;

ALTER TABLE hospital_er_data_dup
CHANGE month monthname VARCHAR(20);

UPDATE hospital_er_data_dup
SET year = DATE_FORMAT(admission_date, '%Y'),
month = DATE_FORMAT(admission_date, '%b');

ALTER TABLE hospital_er_data_dup
MODIFY Patient_admission_flag VARCHAR(15);


UPDATE hospital_er_data_dup
SET Patient_admission_flag = 'Admitted' WHERE Patient_admission_flag = 'TRUE';

UPDATE hospital_er_data_dup
SET Patient_admission_flag = 'Not Admitted' WHERE Patient_admission_flag = 'FALSE';


-- EDA

-- NUMBER OF PATIENT

SELECT count(DISTINCT patient_id)
FROM hospital_er_data_dup;

-- gender distribution

SELECT gender, COUNT(*) as counts
FROM hospital_er_data_dup
GROUP BY gender;


-- age distribution

SELECT CASE
WHEN age < 18 THEN 'Child'
WHEN age BETWEEN 18 AND 32 THEN 'Young adults'
WHEN age BETWEEN 33 AND 55 THEN 'Adult'
When age BETWEEN 56 and 75 THEN 'Retired'
WHEN age > 75 THEN 'Old'
END AS age_group, COUNT(*) as counts
FROM hospital_er_data_dup
GROUP BY age_group
ORDER BY counts DESC;


-- patient race distribution

SELECT patient_race, COUNT(*) AS counts
FROM hospital_er_data_dup
GROUP BY patient_race;


-- AVERAGE WAIT TIME

select avg(patient_wait_time)
FROM hospital_er_data_dup;

-- MEDIAN WAIT TIME of patient


WITH cte_median_waittime AS
(
SELECT *,
ROW_NUMBER() over(order by patient_wait_time) as index_
FROM hospital_er_data_dup
),
total_count AS
(
SELECT COUNT(*) AS cnt 
FROM hospital_er_data_dup
),
Cte_median_waittime2 AS
(
SELECT c. patient_wait_time, c.index_
FROM cte_median_waittime c
CROSS JOIN total_count d
WHERE d.cnt % 2 = 0 AND c.index_ IN (d.cnt/2, d.cnt/2 + 1) OR
d.cnt % 2 = 1 AND c.index_ IN (FLOOR(d.cnt/2) +1)
)
SELECT AVG(patient_wait_time) AS median_waittime
FROM Cte_median_waittime2;


-- Patient Satisfaction Score:
      
SELECT CAST(AVG(satisfaction_score) AS DECIMAL(10,2)) AS avg_score
FROM hospital_er_data_dup;

-- Mode/ highest number of patient give satisfaction as 

WITH cte_satisfaction_score_mode AS
(SELECT satisfaction_score, COUNT(satisfaction_score) AS cnt
FROM hospital_er_data_dup
WHERE satisfaction_score IS NOT NULL
GROUP BY satisfaction_score
ORDER BY cnt desc)
SELECT satisfaction_score
FROM cte_satisfaction_score_mode
LIMIT 1;

-- Number of Patients Referred:


SELECT  COUNT(Department_referral)
FROM hospital_er_data_dup
WHERE Department_referral != 'NONE';


-- EDA
-- Measure the total number of patients visiting the ER as per month & year.


SELECT monthname,counts
FROM(SELECT  MONTH(admission_date) as month_no, monthname, COUNT(patient_id) AS counts
FROM hospital_er_data_dup
GROUP BY month_no,monthname
ORDER BY month_no) AS month_vs_patientcounts_;

SELECT year, COUNT(patient_id) AS counts
FROM hospital_er_data_dup
GROUP BY year;

SELECT year, monthname, counts
FROM(SELECT year, MONTH(admission_date) as month_no, monthname, COUNT(patient_id) AS counts
FROM hospital_er_data_dup
GROUP BY year, month_no, monthname
ORDER BY year, month_no) AS patient_nos;

-- Calculate the Average Wait Time as per the month(season): 

WITH cte_month_avg_waittime AS
(SELECT  monthname, MONTH(admission_date) as month_no,
COUNT(patient_wait_time) AS counts, CAST(AVG(patient_wait_time) AS decimal(7,2)) as Average_wait_time
FROM hospital_er_data_dup
GROUP BY monthname,month_no
ORDER BY month_no)
SELECT monthname,Counts,Average_wait_time
FROM cte_month_avg_waittime;


-- Calculate the Average satisfaction score as per the month(season): 


WITH cte_month_avg_satisfactionscore AS
(SELECT  monthname, MONTH(admission_date) as month_no, COUNT(satisfaction_score) AS counts, CAST(AVG(satisfaction_score) AS decimal(7,2)) as AVERAGE
FROM hospital_er_data_dup
GROUP BY monthname,month(admission_date)
ORDER BY month_no)
SELECT monthname,Counts,AVERAGE
FROM cte_month_avg_satisfactionscore;

-- Count the patients referred to specific departments from the ER.

SELECT department_referral, COUNT(*) AS count
FROM hospital_er_data_dup
group by Department_referral
ORDER BY count DESC; 

-- Department referral for number of patient as per YEAR

SELECT department_referral, year, COUNT(*) AS count
FROM hospital_er_data_dup
GROUP BY Department_referral, year
ORDER BY department_referral ASC, year ASC, count DESC;

-- Department referral for number of patient as per Season
SELECT DISTINCT monthname
FROM hospital_er_data_dup;

WITH cte_hospital AS 
(SELECT Department_referral, monthname, month(admission_date) as month_no,
CASE
WHEN monthname IN ('Jan','Feb') THEN 'Winter'
WHEN monthname IN ('Mar','Apr','May') THEN 'Summer'
WHEN monthname IN ('Jun','Jul','Aug','Sep') THEN 'Monsoon'
WHEN monthname IN ('Oct','Nov','Dec') THEN 'Autumn'
END AS season
FROM hospital_er_data_dup),
cte_hospital2 AS
(SELECT department_referral,season,COUNT(*) as referral_count
FROM cte_hospital
GROUP BY department_referral, season
ORDER BY department_referral)
SELECT Department_referral,referral_count
FROM cte_hospital2
WHERE season = 'Summer'
ORDER BY referral_count DESC;

-- Top 2 Department referral for number of patient as per month

WITH cte_hospital AS 
(SELECT Department_referral, monthname, month(admission_date) as month_no
FROM hospital_er_data_dup
ORDER BY month_no),
cte_hospital2 AS
(SELECT monthname, month_no, department_referral, COUNT(*) as referral_count
FROM cte_hospital
GROUP BY  monthname, month_no, department_referral
ORDER BY month_no ASC, referral_count DESC)
SELECT monthname, department_referral, referral_count
FROM cte_hospital2;

WITH cte_hospital AS 
(SELECT Department_referral, monthname, month(admission_date) as month_no
FROM hospital_er_data_dup
ORDER BY month_no),
cte_hospital2 AS
(SELECT monthname, month_no, department_referral, COUNT(*) as referral_count
FROM cte_hospital
GROUP BY  monthname, month_no, department_referral
ORDER BY month_no ASC, referral_count DESC),
cte_hospital3 AS
(SELECT *,
ROW_NUMBER() OVER (PARTITION BY month_no ORDER BY referral_count DESC) AS rn
FROM cte_hospital2)
SELECT monthname,department_referral,referral_count
FROM cte_hospital3
WHERE rn <= 2;

SELECT *
FROM hospital_er_data_dup;

-- How does the wait time vary by patient gender or race?
SELECT gender, ROUND(AVG(patient_wait_time))
FROM hospital_er_data_dup 
GROUP BY gender;

SELECT patient_race, CAST(AVG(patient_wait_time)AS DECIMAL(7,2) ) AVG
FROM hospital_er_data_dup 
GROUP BY patient_race;

-- What is the average wait time per department referral?

SELECT department_referral, AVG(patient_wait_time) AS Average
FROM hospital_er_data_dup
GROUP BY Department_referral;


-- How many patients were admitted vs. not admitted each month

SELECT monthname,patient_admission_flag, MONTH(admission_date) AS month_no, COUNT(*) AS counts
FROM hospital_er_data_dup
group by monthname,Patient_admission_flag, month_no
ORDER BY month_no;

-- How many patients were admitted vs not admitted each day
-- DATE_FORMAT(),WEEKDAY()/DAYOFWEEK(),DAYNAME()

SELECT patient_admission_flag, days, counts
FROM (
SELECT patient_admission_flag, DATE_FORMAT(admission_date,'%W') AS days,WEEKDAY(admission_date) AS week_no, COUNT(*) AS counts 
FROM hospital_er_data_dup
GROUP BY patient_admission_flag, days,week_no
ORDER BY Patient_admission_flag ASC, week_no ASC ) AS table1;

-- What percentage of patients are admitted after visiting the ER?

SELECT ((SELECT COUNT(Patient_admission_flag)
FROM hospital_er_data_dup
WHERE Patient_admission_flag = 'Admitted') / count(Patient_admission_flag)) * 100 AS Percentage
FROM hospital_er_data_dup;


SELECT Patient_admission_flag, (COUNT(*)/(SELECT COUNT(*) FROM hospital_er_data_dup)) * 100 as percentage
FROM hospital_er_data_dup
GROUP BY Patient_admission_flag;

-- admission rate by patient age group?
-- lets splt age group as below 18, 18- 32, 32 - 55, 55- 70, above 70


SELECT age_group, admit_rate
FROM (
SELECT 
CASE
WHEN age < 18 THEN 'Child'
WHEN age BETWEEN 18 AND 32 THEN 'Young adults'
WHEN age BETWEEN 33 AND 55 THEN 'Adult'
When age BETWEEN 56 and 75 THEN 'Retired'
WHEN age > 75 THEN 'Old'
END AS age_group,
COUNT(*) AS age_counts,
COUNT(CASE WHEN Patient_admission_flag = 'Admitted' THEN 1 END) AS admitted_patients,
(COUNT(CASE WHEN Patient_admission_flag = 'Admitted' THEN 1 END) / COUNT(*)) * 100 as admit_rate
FROM hospital_er_data_dup
GROUP BY age_group ) AS table1
ORDER BY 
CASE 
WHEN age_group = 'Child' THEN 1
WHEN age_group = 'Young adults' THEN 2
WHEN age_group = 'Adult' THEN 3
WHEN age_group = 'Retired' THEN 4
WHEN age_group = 'Old' THEN 5
END;

-- What is the average satisfaction score per day

SELECT DATE_FORMAT(admission_date,'%a') AS month_day, 
AVG(satisfaction_score) AS average, MAX(satisfaction_score) AS MAX, MIN(satisfaction_score) AS MIN
FROM hospital_er_data_dup
GROUP BY month_day
ORDER BY 
CASE 
WHEN month_day = 'Mon' THEN 1
WHEN month_day = 'Tue' THEN 2
WHEN month_day = 'Wed' THEN 3
WHEN month_day = 'Thu' THEN 4
WHEN month_day = 'Fri' THEN 5
WHEN month_day = 'Sat' THEN 6
WHEN month_day = 'SUN' THEN 7
END;

SELECT DATE_FORMAT(admission_date,'%d') AS month_date, AVG(satisfaction_score)
FROM hospital_er_data_dup
GROUP BY month_date
ORDER BY month_date;

-- How does patient satisfaction vary by gender, race, and admission flag?

SELECT gender, COUNT(*) AS count,
 AVG(satisfaction_score) AS average_sat_score,
 MAX(satisfaction_score) AS Max_sat_score
FROM hospital_er_data_dup
GROUP BY gender;

SELECT patient_race, COUNT(*) AS count,
 AVG(satisfaction_score) AS average_sat_score,
 MAX(satisfaction_score) AS Max_sat_score
FROM hospital_er_data_dup
GROUP BY patient_race;

SELECT Patient_admission_flag, COUNT(*) AS count,
 AVG(satisfaction_score) AS average_sat_score,
 MAX(satisfaction_score) AS Max_sat_score
FROM hospital_er_data_dup
GROUP BY Patient_admission_flag;

-- How does patient satisfaction vary by age group?

SELECT age_group, COUNT(*) AS count,
 CAST(AVG(satisfaction_score) AS DECIMAL (10,2)) AS average_sat_score,
 MAX(satisfaction_score) AS Max_sat_score
FROM (
SELECT 
CASE
WHEN age < 18 THEN 'Child'
WHEN age BETWEEN 18 AND 32 THEN 'Young adults'
WHEN age BETWEEN 33 AND 55 THEN 'Adult'
When age BETWEEN 56 and 75 THEN 'Retired'
WHEN age > 75 THEN 'Old'
END AS age_group, satisfaction_score
FROM hospital_er_data_dup
) AS table1
GROUP BY age_group
ORDER BY 
CASE
WHEN age_group = 'Child' THEN 1
WHEN age_group = 'Young adults' THEN 2
WHEN age_group = 'Adult' THEN 3
WHEN age_group = 'Retired' THEN 4
WHEN age_group = 'Old' THEN 5
END;


-- How many patients have a case manager assigned?

SELECT 
CASE
WHEN patient_cm = 0 Then 'No Care Manager'
WHEN patient_cm = 1 THEN 'Has Care Manager'
END AS patient_care_manager,
COUNT(*) AS counts
FROM hospital_er_data_dup
GROUP BY patient_care_manager;

-- What is the average wait time for patients with and without case managers?

SELECT 
CASE
WHEN patient_cm = 0 Then 'No Care Manager'
WHEN patient_cm = 1 THEN 'Has Care Manager'
END AS patient_care_manager,
COUNT(*) AS counts,
AVG(patient_wait_time) AS AVG_Waittime
FROM hospital_er_data_dup
GROUP BY patient_care_manager;


-- What is the referral pattern to various departments by case manager involvement?
SELECT 
CASE
WHEN patient_cm = 0 Then 'No Care Manager'
WHEN patient_cm = 1 THEN 'Has Care Manager'
END AS patient_care_manager,
Department_referral,
COUNT(*) AS counts,
AVG(patient_wait_time) AS AVG_Waittime
FROM hospital_er_data_dup
GROUP BY patient_care_manager, Department_referral
ORDER BY patient_care_manager ASC;

-- "Patient Admission Counts by Care Manager Assignment"
SELECT 
CASE
WHEN patient_cm = 0 Then 'No Care Manager'
WHEN patient_cm = 1 THEN 'Has Care Manager'
END AS patient_care_manager,
Patient_admission_flag,
COUNT(*) AS counts
FROM hospital_er_data_dup
GROUP BY patient_care_manager, Patient_admission_flag;

-- How do patients with case managers rate their satisfaction versus those without?
SELECT 
CASE
WHEN patient_cm = 0 THEN 'No Care Manager'
WHEN patient_cm = 1 THEN 'Has Care Manager'
END AS patient_care_manager,
AVG(satisfaction_score) AVG,
(AVG(satisfaction_score) / (SELECT AVG(satisfaction_score) FROM hospital_er_data_dup))*100 AS percentage
FROM hospital_er_data_dup
GROUP BY patient_care_manager;

-- Time-Related Trends
-- What are the peak hours/days for ER visits?

SELECT DATE_FORMAT(admission_date, '%a') AS admit_day, COUNT(*) AS counts
FROM hospital_er_data_dup
GROUP BY admit_day
ORDER BY 
CASE 
WHEN admit_day = 'Mon' THEN 1
WHEN admit_day = 'Tue' THEN 2
WHEN admit_day = 'Wed' THEN 3
WHEN admit_day = 'Thu' THEN 4
WHEN admit_day = 'Fri' THEN 5
WHEN admit_day = 'Sat' THEN 6
WHEN admit_day = 'SUN' THEN 7
END;

-- hours

SELECT DATE_FORMAT(admission_date, '%H') AS admit_hour, COUNT(*) AS counts
FROM hospital_er_data_dup
GROUP BY admit_hour
ORDER BY admit_hour;

SELECT EXTRACT(HOUR FROM admission_date) AS ad_hour,
 AVG(patient_wait_time) AS avg_waittime,
 AVG(satisfaction_score) AS AVG_satis_score
FROM hospital_er_data_dup
GROUP BY ad_hour
ORDER BY ad_hour;

-- Is there a seasonal trend for ER visits? (Monthly or Quarterly trend analysis)

SELECT
CASE
WHEN monthname IN ('Jan','Feb') THEN 'Winter'
WHEN monthname IN ('Mar','Apr','May') THEN 'Summer'
WHEN monthname IN ('Jun','Jul','Aug','Sep') THEN 'Monsoon'
WHEN monthname IN ('Oct','Nov','Dec') THEN 'Autumn'
END AS season,
COUNT(*) AS patient_counts
FROM hospital_er_data_dup
GROUP BY season;

-- How do wait times and satisfaction scores change across different seasons or months?


WITH cte_month_avg_waittime_satscore AS
(SELECT  monthname, MONTH(admission_date) as month_no, CAST(AVG(patient_wait_time) AS decimal(7,2)) as Average_wait_time,
COUNT(satisfaction_score) AS satis_score_counts,
CAST(AVG(satisfaction_score) AS decimal(7,2)) as Average_sat_score
FROM hospital_er_data_dup
GROUP BY monthname, month_no
ORDER BY month_no)
SELECT monthname,Average_wait_time,Average_sat_score
FROM cte_month_avg_waittime_satscore;


-- Number of Patients Referred as per department for every month basis:

WITH cte_hospital AS 
(SELECT Department_referral, monthname, month(admission_date) as month_no
FROM hospital_er_data_dup
ORDER BY month_no),
cte_hospital2 AS
(SELECT department_referral, month_no, monthname, COUNT(*) as referral_count
FROM cte_hospital
GROUP BY  department_referral, month_no,monthname
ORDER BY month_no ASC, referral_count DESC)
SELECT  department_referral,monthname, referral_count
FROM cte_hospital2;



-- Patient Age Distribution: Group patients by 10-year age intervals.

SELECT CASE
WHEN age < 10 THEN '0-9'
WHEN age BETWEEN 10 AND 19 THEN '10-19'
WHEN age BETWEEN 20 AND 29 THEN '20-29'
When age BETWEEN 30 and 39 THEN '30-39'
When age BETWEEN 40 and 49 THEN '40-49'
When age BETWEEN 50 and 59 THEN '50-59'
When age BETWEEN 60 and 69 THEN '60-69'
When age BETWEEN 70 and 79 THEN '70-79'
END AS age_group,
COUNT(*) as counts
FROM hospital_er_data_dup
GROUP BY age_group
ORDER BY age_group ASC;


-- Department Referrals: Analyze referral trends across different departments. (year and month wise)

WITH cte_hospital AS 
(SELECT year,monthname, month(admission_date) as month_no, Department_referral, COUNT(*) AS 'NO of patient'
FROM hospital_er_data_dup
GROUP BY year, month_no, monthname, Department_referral
ORDER BY year ASC, month_no ASC)
SELECT  year,monthname,  Department_referral, `NO of patient`
FROM cte_hospital;


-- Timeliness: Measure the percentage of patients seen within 30 minutes.

SELECT year, monthname,CASE 
WHEN patient_wait_time <= 30 THEN 'Within 30min'
WHEN patient_wait_time > 30 THEN 'More than 30min'
END AS col1,
COUNT(*) as No_of_patient
FROM hospital_er_data_dup
GROUP BY year, monthname, col1
order by year DESC, monthname, col1;

WITH cte_1 AS
(SELECT year, monthname,CASE 
WHEN patient_wait_time <= 30 THEN 'Within 30min'
WHEN patient_wait_time > 30 THEN 'More than 30min'
END AS col1,
COUNT(*) as No_of_patient
FROM hospital_er_data_dup
GROUP BY year, monthname, col1
order by year DESC, monthname, col1),
cte_2 AS
(SELECT year, monthname,
COUNT(*) as counts
FROM hospital_er_data_dup
GROUP BY year, monthname
ORDER BY year DESC, monthname),
cte_3 AS
(SELECT a.year, a.monthname, a.col1, a.No_of_patient,
ROUND((a.No_of_patient *100/ b.counts),2) AS percentage
FROM cte_1 AS a
INNER JOIN cte_2 AS b 
ON a.year = b.year AND a.monthname = b.monthname)
SELECT * 
FROM cte_3
ORDER BY year DESC, monthname, col1;

--
SELECT year, monthname,gender,`NO of patients`
FROM (SELECT year, monthname, MONTH(admission_date) as month_no, gender, COUNT(*) as 'NO of patients'
FROM hospital_er_data_dup
GROUP BY year, monthname, month_no, gender
ORDER BY  year DESC, month_no ASC) AS table1;


--
SELECT year, monthname,patient_race ,`NO of patients`
FROM (SELECT year, monthname, MONTH(admission_date) as month_no, patient_race, COUNT(*) as 'NO of patients'
FROM hospital_er_data_dup
GROUP BY year, monthname, month_no, patient_race
ORDER BY  year DESC, month_no ASC) AS table1;
