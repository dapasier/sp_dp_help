/*
 Pre-Deployment Script Template							
--------------------------------------------------------------------------------------
 This file contains SQL statements that will be executed before the build script.	
 Use SQLCMD syntax to include a file in the pre-deployment script.			
 Example:      :r .\myfile.sql								
 Use SQLCMD syntax to reference a variable in the pre-deployment script.		
 Example:      :setvar TableName MyTable							
               SELECT * FROM [$(TableName)]					
--------------------------------------------------------------------------------------
*/
DECLARE
	@query nvarchar(max) = '';

SELECT
	@query = @query + 'DROP PROCEDURE ' + QUOTENAME(s.name) + '.' + QUOTENAME(o.name) + ';
'
FROM sys.all_objects o
	JOIN sys.schemas s
		ON o.schema_id = s.schema_id
WHERE o.name LIKE 'sp_dp_help%'
	AND s.name = 'dbo'
	AND o.is_ms_shipped = 1
	AND o.type = 'P';

PRINT @query;

EXEC (@query);
GO
