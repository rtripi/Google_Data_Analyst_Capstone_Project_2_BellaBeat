SELECT COUNT(DISTINCT Id) FROM `bellabeatrtrip.daily_dt.dailyActivity`;
SELECT COUNT(DISTINCT Id) FROM `bellabeatrtrip.daily_dt.dailyCalories`;
SELECT COUNT(DISTINCT Id) FROM `bellabeatrtrip.daily_dt.dailyIntensities`;
SELECT COUNT(DISTINCT Id) FROM `bellabeatrtrip.daily_dt.dailySteps`;
SELECT COUNT(DISTINCT Id) FROM `bellabeatrtrip.daily_dt.sleepDay`;
SELECT COUNT(DISTINCT Id) FROM `bellabeatrtrip.daily_dt.weightLogInfo`;

-- Checking for duplicates
SELECT Id, ActivityDate, TotalSteps, Count(*)
FROM `bellabeatrtrip.daily_dt.dailyActivity`
GROUP BY id, ActivityDate, TotalSteps
HAVING Count(*) > 1;

SELECT Id, ActivityDay, Calories, Count(*)
FROM `bellabeatrtrip.daily_dt.dailyCalories`
GROUP BY id, ActivityDay, Calories
HAVING Count(*) > 1;

SELECT Id, ActivityDay, Count(*)
FROM `bellabeatrtrip.daily_dt.dailyIntensities`
GROUP BY id, ActivityDay
HAVING Count(*) > 1;

SELECT Id, ActivityDay, Count(*)
FROM `bellabeatrtrip.daily_dt.dailySteps`
GROUP BY id, ActivityDay
HAVING Count(*) > 1;

SELECT Id, Date, Count(*)
FROM `bellabeatrtrip.daily_dt.weightLogInfo`
GROUP BY id, Date
HAVING Count(*) > 1;

SELECT Id, SleepDay, Count(*)
FROM `bellabeatrtrip.daily_dt.sleepDay`
GROUP BY id, SleepDay
HAVING Count(*) > 1;

-- Created CTE with DuplicateCount -- 
WITH dailySleep_clean AS (
  SELECT
    Id,
    SleepDay,
    TotalSleepRecords,
    TotalMinutesAsleep,
    TotalTimeInBed,
    ROW_NUMBER() OVER (PARTITION BY Id, SleepDay ORDER BY Id) AS DuplicateCount
  FROM `bellabeatrtrip.daily_dt.sleepDay`
)
SELECT
  *,
  (ROUND(TotalMinutesAsleep/60)) AS TotalHoursAsleep,
  (TotalTimeInBed - TotalMinutesAsleep) AS MinutesTillAsleep
FROM dailySleep_clean
WHERE DuplicateCount = 1
  AND (TotalTimeInBed - TotalMinutesAsleep) > 0;

--Add dayOfWeek on dailyActivity

ALTER Table `bellabeatrtrip.daily_dt.dailyActivity`
ADD column dayOfWeek string;

--I was supose to insert the days of the week, but bigquery asked me to pay for dml queries, not doing that right now, the intention was good though

ALTER Table `bellabeatrtrip.daily_dt.dailyActivity`
DROP column dayOfWeek;

--new columns for daily activity

SELECT Id,ActivityDate,TotalSteps
,TotalDistance
,(round(SedentaryMinutes/60,1)) AS SedentaryHours
,(round((VeryActiveMinutes + FairlyActiveMinutes + LightlyActiveMinutes)/60,1)) AS TotalTimeActive
,Calories
from `bellabeatrtrip.daily_dt.dailyActivity`
WHERE (VeryActiveMinutes + FairlyActiveMinutes + LightlyActiveMinutes) > 0
      AND
      Calories > 0;

--Joining daily sleep and activities clean tables

SELECT A.Id
,A.ActivityDate
,B.SleepDay
,A.TotalSteps
,A.SedentaryHours
,A.TotalTimeActive
,B.TotalHoursAsleep
,B.MinutesTillAsleep
FROM `bellabeatrtrip.daily_dt.dailyActivity_clean` A 
INNER JOIN `bellabeatrtrip.daily_dt.dailySleep_clean` B
ON A.ActivityDate = B.SleepDay AND A.Id = B.Id
ORDER BY A.TotalTimeActive;

--Removing columns from the weight table

SELECT * EXCEPT(Fat,IsManualReport,LogId,WeightKg)
, CASE
    WHEN bmi < 18.5 THEN 'Underweight'
    WHEN bmi >= 18.5 AND bmi <= 24.9 THEN 'Normal weight'
    WHEN bmi >= 25 AND bmi <= 29.9 THEN 'Overweight'
    WHEN bmi >= 30 AND bmi <= 34.9 THEN 'Obesity (Class I)'
    WHEN bmi >= 35 AND bmi <= 39.9 THEN 'Obesity (Class II)'
    ELSE 'Obesity (Class III)'
  END AS BMICategory
FROM `bellabeatrtrip.daily_dt.weightLogInfo`
WHERE BMI > 0