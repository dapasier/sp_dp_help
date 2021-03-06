﻿/*
Post-Deployment Script Template							
--------------------------------------------------------------------------------------
 This file contains SQL statements that will be appended to the build script.		
 Use SQLCMD syntax to include a file in the post-deployment script.			
 Example:      :r .\myfile.sql								
 Use SQLCMD syntax to reference a variable in the post-deployment script.		
 Example:      :setvar TableName MyTable							
               SELECT * FROM [$(TableName)]					
--------------------------------------------------------------------------------------
*/
DECLARE
	@query nvarchar(max) = '';

SELECT
	@query = @query + 'EXEC sys.sp_MS_marksystemobject ''' + QUOTENAME(s.name) + '.' + QUOTENAME(o.name) + ''';
'
FROM sys.all_objects o
	JOIN sys.schemas s
		ON o.schema_id = s.schema_id
WHERE o.name LIKE 'sp_dp_help%'
	AND s.name = 'dbo'
	AND o.is_ms_shipped = 0
	AND o.type = 'P';

PRINT @query;

EXEC (@query);
GO
