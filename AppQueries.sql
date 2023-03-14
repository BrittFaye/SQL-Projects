-- A test query to make my date conversion is correct before altering the table.
SELECT released, CONVERT(Date, released)
FROM EducationalAppData..Data
-- Altering the date column to remove the unneeded time stamp. 
ALTER TABLE Data
ADD release_date Date;

UPDATE EducationalAppData..Data
SET release_date = CONVERT(Date, released)

-- Seeing the correlation between release date/installs/rating.
SELECT release_date, installs, ratings
FROM EducationalAppData..Data
WHERE ratings IS NOT null
ORDER BY release_date

-- Looking for information on the apps that have an above average score.
SELECT 
	title,
	developer,
	score
FROM EducationalAppData..Data 
WHERE score > (SELECT
	AVG(score) AS AvgScore
FROM EducationalAppData..Data)
ORDER BY title

-- Updating the size column so I can convert it to int. 
UPDATE EducationalAppData..Data 
SET size = NULL
WHERE size LIKE 'Varies with device'

-- Created a common table expression to remove the M character in the size column, then
-- change the data type to decimal and create a download size range with a case statement. 
WITH CTE_CharacterRemoval AS
(
SELECT 
	title, 
	score, 
	SUBSTRING(size, 1, CHARINDEX('M', size)-1) AS resize
FROM EducationalAppData..Data
)
SELECT 
	title,
	CASE
		WHEN CAST(resize AS decimal) >= 1 AND CAST(resize AS decimal) <= 95 THEN 'Small Download'
		WHEN CAST(resize AS decimal) >= 96 AND CAST(resize AS decimal) <= 195 THEN 'Medium Download'
		ELSE 'Large Download'
	END AS DownloadRange,
	score
FROM CTE_CharacterRemoval
ORDER BY DownloadRange DESC

-- Made a temp table to avoid JOINing the tables since there is so little
-- data in the Review table. 
DROP TABLE IF EXISTS #ReviewLookup
CREATE TABLE #ReviewLookup (
developer nvarchar(255),
title nvarchar(255),
score float, 
Column3 nvarchar(max)
)
INSERT INTO #ReviewLookup 
SELECT 
	dat.developer, 
	dat.title, 
	dat.score,
	rev.Column3
FROM EducationalAppData..Data dat
RIGHT OUTER JOIN EducationalAppData..Reviews rev
ON dat.title = rev.Column1
ORDER BY dat.developer, dat.title

SELECT title, Column3
FROM #ReviewLookup