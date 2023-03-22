/*
===============================================================================
Name: Query Snippets
Author: Barney Lawrence
Creation Date: 2023-03-23
Description: 
	This script uses metadata to generate subsections of SQL code to speed development
	of Select, Insert, Update, Merge type queries
Usage: 
	Run this query against an instance of SQL Server and copy the results from
	the column Query for the table you are developing a query for.
	The queries assume that the final statement uses a table alias of
	S - for the source table
	T - for the target table
	For the query to format correctly in SSMS please ensure to check the option at:
	Tools>Options>Query Results>SQL Server>Results to Grid>Retain CR/LF on copy or save
Source:
	The latest version of this script can be found at
	https://github.com/BarneyLawrence/Sessions-Metadata-Data-Warehouse
===============================================================================
*/

WITH BKStrings AS
(
SELECT OBJECT_SCHEMA_NAME(I.object_id) AS TableSchemaName
,OBJECT_NAME(I.object_id) AS TableName
, STRING_AGG('S.' + QUOTENAME(C.Name) + ' = T.' + QUOTENAME(C.Name), char(10) + ' AND ') AS BK_Matches
FROM sys.indexes AS I
INNER JOIN sys.index_columns AS IC
	ON I.object_id = IC.object_id 
	AND I.index_id = IC.index_id
INNER JOIN sys.all_columns AS C
	ON I.object_id = C.object_id
	AND IC.column_id = C.column_id
WHERE I.name like 'BK_%' AND IC.is_included_column = 0
GROUP BY
OBJECT_SCHEMA_NAME(I.object_id) ,OBJECT_NAME(I.object_id) 
),PKStrings AS
(
SELECT OBJECT_SCHEMA_NAME(I.object_id) AS TableSchemaName
,OBJECT_NAME(I.object_id) AS TableName
, STRING_AGG('S.' + QUOTENAME(C.Name) + ' = T.' + QUOTENAME(C.Name), char(10) + ' AND ') AS PK_Matches
FROM sys.indexes AS I
INNER JOIN sys.index_columns AS IC
	ON I.object_id = IC.object_id 
	AND I.index_id = IC.index_id
INNER JOIN sys.all_columns AS C
	ON I.object_id = C.object_id
	AND IC.column_id = C.column_id
WHERE I.name like 'PK_%' AND IC.is_included_column = 0
GROUP BY
OBJECT_SCHEMA_NAME(I.object_id) ,OBJECT_NAME(I.object_id) 
),
TableStrings AS
(
SELECT C.TABLE_SCHEMA, C.TABLE_NAME
, QUOTENAME(C.TABLE_SCHEMA) + '.' + QUOTENAME(C.TABLE_NAME) AS QuotedTableName
, STRING_AGG(CAST(QUOTENAME(COLUMN_NAME) AS nvarchar(max)),char(10) + ', ') AS ColumnList
, STRING_AGG(CAST(QUOTENAME(COLUMN_NAME) + ' = S.' + QUOTENAME(COLUMN_NAME) AS nvarchar(max)),char(10) + ', ') AS UpdateList
, 'SELECT 
' + STRING_AGG(CAST('S.' + QUOTENAME(COLUMN_NAME) AS nvarchar(max)),char(10) + ', ') + '
EXCEPT 
SELECT 
' + STRING_AGG(CAST('T.' + QUOTENAME(COLUMN_NAME) AS nvarchar(max)),char(10) + ', ') AS ExceptList
, 'INSERT INTO ' +  QUOTENAME(C.TABLE_SCHEMA) + '.' + QUOTENAME(C.TABLE_NAME) + '
(
' + STRING_AGG(CAST(QUOTENAME(COLUMN_NAME) AS nvarchar(max)),char(10) + ', ') + '
) 
SELECT 
' + STRING_AGG(CAST('S.' + QUOTENAME(COLUMN_NAME) AS nvarchar(max)),char(10) + ', ' ) AS InsertList
, 'SELECT 
' + STRING_AGG(CAST('S.' + QUOTENAME(COLUMN_NAME) AS nvarchar(max)),char(10) + ', ')  WITHIN GROUP(ORDER BY ORDINAL_POSITION)
+ '
FROM '  +  QUOTENAME(C.TABLE_SCHEMA) + '.' + QUOTENAME(C.TABLE_NAME) + ' AS S' AS SelectStatement
, 'SELECT 
' + STRING_AGG(CAST(
				'S.' + QUOTENAME(COLUMN_NAME) + ' AS ' + QUOTENAME(REPLACE(COLUMN_NAME,' ','_'))
				AS nvarchar(max)),char(10) + ', ') WITHIN GROUP(ORDER BY ORDINAL_POSITION)
+ '
FROM '  +  QUOTENAME(C.TABLE_SCHEMA) + '.' + QUOTENAME(C.TABLE_NAME) + ' AS S' AS SelectStatementNoSpaces
FROM INFORMATION_SCHEMA.COLUMNS C
GROUP BY C.TABLE_SCHEMA, C.TABLE_NAME
)
SELECT T.*
, BK.BK_Matches
, PK.PK_Matches
FROM TableStrings AS T
LEFT OUTER JOIN BKStrings AS BK
	ON T.TABLE_SCHEMA = BK.TableSchemaName
	AND T.TABLE_NAME = BK.TableName
LEFT OUTER JOIN PKStrings AS PK
	ON T.TABLE_SCHEMA = PK.TableSchemaName
	AND T.TABLE_NAME = PK.TableName