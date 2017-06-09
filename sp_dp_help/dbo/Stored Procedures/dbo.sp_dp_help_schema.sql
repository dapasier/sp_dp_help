CREATE PROC dbo.sp_dp_help_schema
	@ObjectId	INT
AS
	SELECT
		 [SchemaName]		= s.[name]
		,[PrincipalName]	= p.[name]
		,[PrincipalType]	= p.[type_desc]
	FROM sys.schemas s
		JOIN sys.database_principals p
			ON s.[principal_id] = p.[principal_id]
	WHERE s.[schema_id] = @ObjectId
	ORDER BY [PrincipalName];
GO
