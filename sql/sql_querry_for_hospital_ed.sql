Select *
From hospital.hospital_er_data;

ALTER TABLE hospital_er_data
CHANGE `ï»¿Patient Id` patient_id Varchar(20);

CREATE TABLE hospital_er_data_copy 
LIKE hospital_er_data;

select *
From hospital_er_data_copy;

INSERT hospital_er_data_copy
select *
From hospital_er_data;

DESCRIBE hospital_er_data_copy;

ALTER TABLE hospital_er_data_copy
CHANGE `Patient Admission Date` Admission_Date Varchar(20);

ALTER TABLE hospital_er_data_copy
CHANGE `Patient First Inital` Firstname Varchar(10),
CHANGE `Patient Last Name` Lastname Varchar(50),
CHANGE `Patient Gender` Gender Varchar(10),
CHANGE `Patient Age` Age INT;


ALTER TABLE hospital_er_data_copy
CHANGE `Patient Race` patient_race  Varchar(30),
CHANGE `Department Referral` Department_referral Varchar(20),
CHANGE `Patient Admission Flag` Patient_admission_flag VARCHAR(5),
CHANGE `Patient Satisfaction Score` satisfaction_score VARCHAR(10),
CHANGE `Patient Waittime` patient_wait_time INT,
ADD CONSTRAINT chk_age CHECK (patient_wait_time <= 60),
CHANGE `Patients CM` patient_cm VARCHAR(10)
;

UPDATE hospital_er_data_copy
SET satisfaction_score = NULL WHERE satisfaction_score = ' ';


SELECT * , substring(Admission_Date, 4, 2) AS Admission_month
FROM hospital_er_data_copy;


UPDATE hospital_er_data_copy
SET Gender = 'MALE' WHERE Gender = 'M';

UPDATE hospital_er_data_copy
SET Gender = 'FEMALE' Where Gender = 'F';

UPDATE hospital_er_data_copy
SET Gender = 'OTHER' Where Gender = 'NC';

SELECT *,concat(Firstname,' ',Lastname) AS patient_fullname, LENGTH(concat(Firstname,' ',Lastname)) AS length
FROM hospital_er_data_copy
order by length DESC;

describe hospital_er_data_copy;


-- NUMBER OF PATIENT

SELECT count(DISTINCT patient_id)
FROM hospital_er_data_copy;

-- AVERAGE WAIT TIME

select avg(patient_wait_time)
FROM hospital_er_data_copy;

WITH cte_waittime AS
(SELECT *, substring(Admission_Date, 4, 7) AS month_year
FROM hospital_er_data_copy
ORDER BY month_year ASC)
SELECT month_year, AVG(patient_wait_time)
FROM cte_waittime
WHere month_year = '02-2024';

-- Patient satisfaction score
SELECT ROUND(AVG(satisfaction_score), 2) AS avg_sat_score
FROM hospital_er_data_copy;

WITH cte_sat_score AS
(SELECT *, substring(Admission_Date, 4, 2) AS month, substring(Admission_Date, 7, 4) AS Year
FROM hospital_er_data_copy)
SELECT year, month,CAST(avg(satisfaction_score) AS DECIMAL(10,2)) AS avg_score
FROM cte_sat_score
GROUP BY month, Year
Order by year ASC, month ASC;

-- NUMBER of patient referred
SELECT  COUNT(Department_referral)
FROM hospital_er_data_copy
WHERE Department_referral != 'NONE';


SELECT Department_referral, COUNT(Department_referral)
FROM hospital_er_data_copy
WHERE Department_referral != 'NONE'
GROUP BY Department_referral;

WITH cte_referral AS
(SELECT *, substring(Admission_Date, 4, 2) AS month, substring(Admission_Date, 7, 4) AS Year
FROM hospital_er_data_copy)
SELECT year, month, COUNT(Department_referral)  AS No_of_referral
FROM cte_referral
WHERE Department_referral != 'NONE'
GROUP BY  Year, month
Order by year ASC, month ASC;

