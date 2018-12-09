---------------Finish getting the data ready----------------
SELECT 
	a.CED_NAME16,
	a.Age04514,
	a.NeedsAssistance,
	a.Sex,
	a.Age5yr,
	a.Indigenous,
	b.OnlyEnglishSpokenHome,
	c.Religion,
	c.Denomination,
	d.BornAust,
	e.AustCitizen,
    CAST(1.0 AS FLOAT) AS persons
INTO ced_persons_seed
FROM ced_persons_seed_incomplete AS a
FULL JOIN pop4 AS b
  ON a.CED_NAME16 = b.CED_NAME16 AND
     a.Sex = b.Sex
FULL JOIN pop5 AS c
  ON a.CED_NAME16 = c.CED_NAME16 AND
     a.Sex = c.Sex
FULL JOIN pop6 AS d
  ON a.CED_NAME16 = d.CED_NAME16 AND
     a.Sex = d.Sex
FULL JOIN pop7 AS e
  ON a.CED_NAME16 = e.CED_NAME16 AND
     a.Sex = e.Sex

