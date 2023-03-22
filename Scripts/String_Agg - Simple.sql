/*
===============================================================================
Name: STRING_AGG Simple Exaple
Author: Barney Lawrence
Creation Date: 2023-03-23
Description: 
	This is a simple example of using STRING_AGG to build a string from row values
Source:
	The latest version of this script can be found at
	https://github.com/BarneyLawrence/Sessions-Metadata-Data-Warehouse
===============================================================================
*/

DROP TABLE IF EXISTS #MyText;

CREATE TABLE #MyText (
WordId int,
Word varchar(50),
CONSTRAINT Pv_Mytext PRIMARY KEY CLUSTERED (Word ASC)
)
INSERT INTO #MyText
SELECT *
FROM
(
VALUES (1,'Hello'), (2, 'World'), (3, 'From'), (4, 'Ruth'), (5, 'Emma'), (6, 'And'), (7, 'Barney')
)  A(WordId,Word);

SELECT 
	STRING_AGG(Word,' ') AS MyPhrase
FROM #MyText;


SELECT 
	STRING_AGG(Word,' ') WITHIN GROUP (ORDER BY WordId) AS  MyPhrase
FROM #MyText;