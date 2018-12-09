/*
This program uses iterative proportional fitting to create new estimates of number of persons for highly granular data
that will add up to correct marginal totals provided in 

Ordinarily we would do this with the survey::rake() function in R but that uses more memory than is feasible (eg 28 GB needed
for doing this with just four population sets, and I want to do it with more). Doing it in SQL Server is slow (both to write
and to execute!) but because more is done on hard disk and it doesn't rely on holding everything in memory it is at least feasible.

Peter Ellis 9 December 2018.

TODO - this code is repetitive and would be better off in a function that writes and executes dynamic SQL. The complications are dealing
       with a variable number of columns for each set of population margins. 


Takes 4 minutes with 1 million rows to do 2 iterations
*/

USE ozdata;
GO




-- clear the decks:
DROP TABLE IF EXISTS #latest
DROP TABLE IF EXISTS #second_latest
DROP TABLE IF EXISTS #delta
DROP TABLE IF EXISTS #revised
GO

-- tables with the same shape as the main dataset so we can hold three different versions of it at once, for comparisons
SELECT * INTO #latest FROM ced_persons_seed
SELECT * INTO #second_latest FROM #latest ;
SELECT * INTO #revised FROM #latest WHERE 1 = 2;
GO


-- table to store how much the estimates have changed in each iteration
CREATE TABLE #delta (
	latest INT
	);

INSERT #delta (latest)
	VALUES (1000000);
GO

------------------Start of iteration---------------------------
-- variable we use to iterate the loops by
DECLARE @i INT = 0;


WHILE @i < 5 AND (SELECT min(latest) FROM #delta) > 3
BEGIN

	-------------------------------POPULATION TABLE 2---------------------
	-- Define a CTE of adjustments (ratios to multiply the current estimates by to add up to
	-- correct marginal totals for this particular combination of variables):
	WITH adjustments AS
		(SELECT 
			s.ced_name16,
			s.age04514,
			s.needsassistance,
			s.sex,
			p.freq / s.sample_freq AS adj 
		FROM
			(SELECT
				ced_name16,
				age04514,
				needsassistance,
				sex,
				sum(persons) as sample_freq
			FROM #latest
			GROUP BY ced_name16, age04514, needsassistance, sex) as s
		INNER JOIN dbo.pop2 AS p 
		ON p.ced_name16 = s.ced_name16 AND
		 p.age04514 = s.age04514 AND
		 p.needsassistance = s.needsassistance AND
		 p.sex = s.sex) 
    -- Use those ratios to create a new set of estimates in a new table. Note that we keep emptying and filling tables from scratch
	-- not updating existing tables because that would be slow slow slow:
	INSERT INTO #revised
		SELECT 
			l.ced_name16,
			l.age04514,
			l.needsassistance,
			l.sex,
			l.age5yr,
			l.indigenous,
			l.onlyenglishspokenhome,
			l.Religion,
			l.Denomination,
			l.BornAust,
			l.AustCitizen,
			l.persons * a.adj AS persons
		FROM #latest AS l
		INNER JOIN adjustments AS a
		ON a.ced_name16 = l.ced_name16 AND
		 a.age04514 = l.age04514 AND
		 a.needsassistance = l.needsassistance AND
		 a.sex = l.sex;
		 
    -- shuffle around the various versions
	DELETE FROM #latest WHERE 1 = 1;
	
	INSERT #latest
		SELECT * FROM #revised;

	DELETE FROM #revised WHERE 1 = 1;
	
	-------------------------------POPULATION TABLE 3---------------------
	
	WITH adjustments AS
		(SELECT 
			s.ced_name16,
			s.age5yr,
			s.indigenous,
			s.sex,
			p.freq / s.sample_freq AS adj 
		FROM
			(SELECT
				ced_name16,
				age5yr,
				indigenous,
				sex,
				sum(persons) as sample_freq
			FROM #latest
			GROUP BY ced_name16, age5yr, indigenous, sex) as s
		INNER JOIN dbo.pop3 AS p 
		ON p.ced_name16 = s.ced_name16 AND
		 p.age5yr = s.age5yr AND
		 p.indigenous = s.indigenous AND
		 p.sex = s.sex)
	INSERT INTO #revised
		SELECT 
			l.ced_name16,
			l.age04514,
			l.needsassistance,
			l.sex,
			l.age5yr,
			l.indigenous,
			l.onlyenglishspokenhome,
			l.Religion,
			l.Denomination,
			l.BornAust,
			l.AustCitizen,
			l.persons * adj AS persons
		FROM #latest AS l
		INNER JOIN adjustments AS a
		ON a.ced_name16 = l.ced_name16 AND
		 a.age5yr = l.age5yr AND
		 a.indigenous = l.indigenous AND
		 a.sex = l.sex;


	DELETE FROM #latest WHERE 1 = 1;

	INSERT #latest
		SELECT * FROM #revised;

	DELETE FROM #revised WHERE 1 = 1;

	-------------------------------POPULATION TABLE 4---------------------

	WITH adjustments AS
		(SELECT 
			s.ced_name16,
			s.onlyenglishspokenhome,
			s.sex,
			p.freq / s.sample_freq AS adj 
		FROM
			(SELECT
				ced_name16,
				onlyenglishspokenhome,
				sex,
				sum(persons) as sample_freq
			FROM #latest
			GROUP BY ced_name16, onlyenglishspokenhome, sex) as s
		INNER JOIN dbo.pop4 AS p 
		ON p.ced_name16 = s.ced_name16 AND
		 p.onlyenglishspokenhome = s.onlyenglishspokenhome AND
		 p.sex = s.sex)
	INSERT INTO #revised
		SELECT 
			l.ced_name16,
			l.age04514,
			l.needsassistance,
			l.sex,
			l.age5yr,
			l.indigenous,
			l.onlyenglishspokenhome,
			l.Religion,
			l.Denomination,
			l.BornAust,
			l.AustCitizen,
			l.persons * adj AS persons
		FROM #latest AS l
		INNER JOIN adjustments AS a
		ON a.ced_name16 = l.ced_name16 AND
		 a.onlyenglishspokenhome = l.onlyenglishspokenhome AND
		 a.sex = l.sex;

	DELETE FROM #latest WHERE 1 = 1;

	INSERT #latest
		SELECT * FROM #revised;

	DELETE FROM #revised WHERE 1 = 1;

	-------------------------------POPULATION TABLE 5---------------------

	WITH adjustments AS
		(SELECT 
			s.ced_name16,
			s.religion,
			s.denomination,
			s.sex,
			p.freq / s.sample_freq AS adj 
		FROM
			(SELECT
				ced_name16,
				religion,
				denomination,
				sex,
				sum(persons) as sample_freq
			FROM #latest
			GROUP BY ced_name16, religion, denomination, sex) as s
		INNER JOIN dbo.pop5 AS p 
		ON p.ced_name16 = s.ced_name16 AND
		 p.religion = s.religion AND
		 p.denomination = s.denomination AND
		 p.sex = s.sex)
	INSERT INTO #revised
		SELECT 
			l.ced_name16,
			l.age04514,
			l.needsassistance,
			l.sex,
			l.age5yr,
			l.indigenous,
			l.onlyenglishspokenhome,
			l.Religion,
			l.Denomination,
			l.BornAust,
			l.AustCitizen,
			l.persons * adj AS persons
		FROM #latest AS l
		INNER JOIN adjustments AS a
		ON a.ced_name16 = l.ced_name16 AND
		 a.religion = l.religion AND
		 a.denomination = l.denomination AND
		 a.sex = l.sex;

	DELETE FROM #latest WHERE 1 = 1;

	INSERT #latest
		SELECT * FROM #revised;

	DELETE FROM #revised WHERE 1 = 1;

	-------------------------------POPULATION TABLE 6---------------------

	WITH adjustments AS
		(SELECT 
			s.ced_name16,
			s.BornAust,
			s.sex,
			p.freq / s.sample_freq AS adj 
		FROM
			(SELECT
				ced_name16,
				BornAust,
				sex,
				sum(persons) as sample_freq
			FROM #latest
			GROUP BY ced_name16, BornAust, sex) as s
		INNER JOIN dbo.pop6 AS p 
		ON p.ced_name16 = s.ced_name16 AND
		 p.BornAust = s.BornAust AND
		 p.sex = s.sex)
	INSERT INTO #revised
		SELECT 
			l.ced_name16,
			l.age04514,
			l.needsassistance,
			l.sex,
			l.age5yr,
			l.indigenous,
			l.onlyenglishspokenhome,
			l.religion,
			l.denomination,
			l.BornAust,
			l.AustCitizen,
			l.persons * adj AS persons
		FROM #latest AS l
		INNER JOIN adjustments AS a
		ON a.ced_name16 = l.ced_name16 AND
		 a.BornAust = l.BornAust AND
		 a.sex = l.sex;

	DELETE FROM #latest WHERE 1 = 1;

	INSERT #latest
		SELECT * FROM #revised;

	DELETE FROM #revised WHERE 1 = 1;

		-------------------------------POPULATION TABLE 7---------------------

	WITH adjustments AS
		(SELECT 
			s.ced_name16,
			s.AustCitizen,
			s.sex,
			p.freq / s.sample_freq AS adj 
		FROM
			(SELECT
				ced_name16,
				AustCitizen,
				sex,
				sum(persons) as sample_freq
			FROM #latest
			GROUP BY ced_name16, AustCitizen, sex) as s
		INNER JOIN dbo.pop7 AS p 
		ON p.ced_name16 = s.ced_name16 AND
		 p.AustCitizen = s.AustCitizen AND
		 p.sex = s.sex)
	INSERT INTO #revised
		SELECT 
			l.ced_name16,
			l.age04514,
			l.needsassistance,
			l.sex,
			l.age5yr,
			l.indigenous,
			l.onlyenglishspokenhome,
			l.Religion,
			l.Denomination,
			l.BornAust,
			l.AustCitizen,
			l.persons * adj AS persons
		FROM #latest AS l
		INNER JOIN adjustments AS a
		ON a.ced_name16 = l.ced_name16 AND
		 a.AustCitizen = l.AustCitizen AND
		 a.sex = l.sex;

	DELETE FROM #latest WHERE 1 = 1;

	INSERT #latest
		SELECT * FROM #revised;

	DELETE FROM #revised WHERE 1 = 1;

	-------------------------------POPULATION TABLE 8---------------------

	WITH adjustments AS
		(SELECT 
			s.Indigenous,
			s.AustCitizen,
			p.freq / s.sample_freq AS adj 
		FROM
			(SELECT
				Indigenous,
				AustCitizen,
				sum(persons) as sample_freq
			FROM #latest
			GROUP BY Indigenous, AustCitizen) as s
		INNER JOIN dbo.pop8 AS p 
		ON p.indigenous = s.indigenous AND
		 p.AustCitizen = s.AustCitizen)
	INSERT INTO #revised
		SELECT 
			l.ced_name16,
			l.age04514,
			l.needsassistance,
			l.sex,
			l.age5yr,
			l.indigenous,
			l.onlyenglishspokenhome,
			l.Religion,
			l.Denomination,
			l.BornAust,
			l.AustCitizen,
			l.persons * adj AS persons
		FROM #latest AS l
		INNER JOIN adjustments AS a
		ON a.Indigenous = l.Indigenous AND
		 a.AustCitizen = l.AustCitizen;

	DELETE FROM #latest WHERE 1 = 1;

	INSERT #latest
		SELECT * FROM #revised;

	DELETE FROM #revised WHERE 1 = 1;

	--------------Sum up how we're going-----------
	INSERT INTO #delta 
		SELECT
			avg(abs(b.persons - a.persons)) as latest
		FROM #latest AS a
		INNER JOIN #second_latest AS b
		ON a.ced_name16 = b.ced_name16 AND
			a.age04514 = b.age04514    AND
			a.needsassistance = b.needsassistance AND
			a.sex = b.sex AND
			a.age5yr = b.age5yr AND
			a.indigenous = b.indigenous AND
			a.onlyenglishspokenhome = b.onlyenglishspokenhome AND
			a.religion = b.religion AND
			a.denomination = b.denomination;

	DELETE #second_latest WHERE 1 = 1;

	INSERT #second_latest
		SELECT * FROM #latest;
	
	SET @i = @i + 1;
END

SELECT * FROM #delta

GO

DROP TABLE IF EXISTS ced_persons_transformed;
GO

SELECT * INTO ced_persons_transformed FROM #latest ;
CREATE CLUSTERED COLUMNSTORE INDEX ccxi_ced_persons_transformed
	ON ced_persons_transformed;
GO

