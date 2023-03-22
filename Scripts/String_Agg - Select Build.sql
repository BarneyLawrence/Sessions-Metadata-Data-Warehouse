/*
===============================================================================
Name: String_Agg - Select BUild
Author: Barney Lawrence
Creation Date: 2023-03-23
Description: 
	This script uses metadata to generate SELECT statements for all tables in a database
Usage: 
	Run this query against an instance of SQL Server and copy the results from
	the column SelectStatement for the table you are interested in.
	For the query to format correctly in SSMS please ensure to check the option at:
	Tools>Options>Query Results>SQL Server>Results to Grid>Retain CR/LF on copy or save
Source:
	The latest version of this script can be found at
	https://github.com/BarneyLawrence/Sessions-Metadata-Data-Warehouse
===============================================================================
*/
SELECT 
 C.TABLE_SCHEMA
,C.TABLE_NAME
, STRING_AGG(C.COLUMN_NAME,', ' + char(13) + char(10)) AS ColumnList
,
'
SELECT 
	'+ STRING_AGG(
			QUOTENAME(C.COLUMN_NAME),
			', ' + char(13)  + char(10) + char(9)
			) WITHIN GROUP (ORDER BY C.ORDINAL_POSITION)  +'
FROM ['+ C.TABLE_SCHEMA +'].['+ C. TABLE_NAME+']
' AS SelectStatement
FROM INFORMATION_SCHEMA.COLUMNS AS C
GROUP BY
 C.TABLE_SCHEMA
,C.TABLE_NAME

