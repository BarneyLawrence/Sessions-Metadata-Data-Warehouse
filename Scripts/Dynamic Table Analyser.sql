/*
===============================================================================
Name: Dynamic Table Analyser
Author: Barney Lawrence
Creation Date: 2023-03-23
Description: 
	This script uses metadata to generate queries to support analysis
	of table content by using distinct counts, maximums, minimums and other
	details for all columns and pivoting into a presentable format.
Usage: 
	Run this query against an instance of SQL Server and copy the results from
	the column Query for the table you with to analyse.
	For the query to format correctly in SSMS please ensure to check the option at:
	Tools>Options>Query Results>SQL Server>Results to Grid>Retain CR/LF on copy or save
Source:
	The latest version of this script can be found at
	https://github.com/BarneyLawrence/Sessions-Metadata-Data-Warehouse
===============================================================================
*/

SELECT TABLE_SCHEMA, TABLE_NAME
,'
WITH DistinctCounts AS
(
SELECT '
+ STRING_AGG(CAST('' AS varchar(max)) +
    'COUNT(DISTINCT [' + COLUMN_NAME  +']) AS [DISTINCT_' + COLUMN_NAME +']' + CHAR(13)
    +',COUNT(IIF([' + COLUMN_NAME  +'] IS NULL,1,NULL)) AS [NULL_' + COLUMN_NAME +']' + CHAR(13)
    +',COUNT(IIF(CAST([' + COLUMN_NAME  +'] AS varchar(max)) = '''' ,1,NULL)) AS [BLANK_' + COLUMN_NAME +']' + CHAR(13)
    +',MAX(LEN([' + COLUMN_NAME  +'])) AS [MAXLENGTH_' + COLUMN_NAME +']' + CHAR(13)
    +',MIN([' + COLUMN_NAME  +']) AS [MIN_' + COLUMN_NAME +']' + CHAR(13)
    +',MAX([' + COLUMN_NAME  +']) AS [MAX_' + COLUMN_NAME +']' + CHAR(13)
    +',''' + DATA_TYPE +  ISNULL('(' +CAST(COALESCE(CHARACTER_MAXIMUM_LENGTH,DATETIME_PRECISION) AS varchar(5)) + ')','') +''' '  + ' AS [DATA_TYPE_' + COLUMN_NAME +']' + CHAR(13)
,', ') WITHIN GROUP (ORDER BY ORDINAL_POSITION) + '
FROM [' + TABLE_SCHEMA + '].[' + TABLE_NAME + ']
)
SELECT ''' + TABLE_SCHEMA +''' AS TableSchema, ''' + TABLE_NAME + ''' AS TableName, V.ColumnName, 
V.DistinctColumnCount,V.NullColumnCount,V.BlankColumnCount,V.MaxColumnLength,V.MinColumnValue,V.MaxColumnValue,V.ColumnDataType
FROM DistinctCounts AS C
CROSS APPLY
(
VALUES
 '+
STRING_AGG( CAST('' AS varchar(max)) + 
    '(''' + COLUMN_NAME
    + ''', C.[DISTINCT_' + COLUMN_NAME + ']'
    + ', C.[NULL_' + COLUMN_NAME + '] '
    + ', C.[BLANK_' + COLUMN_NAME + '] '
    + ', C.[MAXLENGTH_' + COLUMN_NAME + ']'
    + ', CAST(C.[MIN_' + COLUMN_NAME + '] AS varchar(max))'
    + ', CAST(C.[MAX_' + COLUMN_NAME + '] AS varchar(max))'
    + ', C.[DATA_TYPE_' + COLUMN_NAME + ']'    +')'
    + CHAR(13)
,', ') WITHIN GROUP (ORDER BY ORDINAL_POSITION)
 +'
) AS V(ColumnName,DistinctColumnCount,NullColumnCount,BlankColumnCount,MaxColumnLength,MinColumnValue,MaxColumnValue,ColumnDataType)
;'
AS Query
FROM INFORMATION_SCHEMA.COLUMNS
GROUP BY TABLE_SCHEMA, TABLE_NAME
