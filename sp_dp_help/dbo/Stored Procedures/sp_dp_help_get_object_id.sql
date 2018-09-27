CREATE PROC dbo.sp_dp_help_get_object_id
	@ObjectName			SYSNAME			OUTPUT
	,@SchemaName		SYSNAME			OUTPUT
	,@ObjectId			INT				OUTPUT
	,@ObjectType		SYSNAME			OUTPUT
	,@ObjectTypeDesc	SYSNAME			OUTPUT
	,@ObjectNameFull	NVARCHAR(392)	OUTPUT
AS
--#region Create #objects
CREATE TABLE #objects
(
     [ObjectId]			INT NOT NULL
	,[ObjectName]		SYSNAME NOT NULL
	,[ObjectType]		SYSNAME NOT NULL
	,[ObjectTypeDesc]	SYSNAME NULL
	,[SchemaName]		SYSNAME NULL
);
--#endregion

--#region Get standard id from sys.all_objects
INSERT INTO #objects (
	[ObjectId]
	,[ObjectName]
	,[ObjectType]
	,[ObjectTypeDesc]
	,[SchemaName])
SELECT
	 [ObjectId]			= o.[object_id]
	,[ObjectName]		= o.[name]
	,[ObjectType]		= o.[type]
	,[ObjectTypeDesc]	= o.[type_desc]
	,[SchemaName]		= s.[name]
FROM sys.all_objects o
	JOIN sys.schemas s
		ON o.schema_id = s.schema_id
WHERE o.[name] = ISNULL(@ObjectName, o.[name])
	AND s.[name] = ISNULL(@SchemaName, s.[name]);

IF @@ROWCOUNT > 1
BEGIN
	SELECT
		ObjectId
		,ObjectName
		,ObjectType
		,ObjectTypeDesc
		,SchemaName
	FROM #objects
	ORDER BY ObjectName;

	RAISERROR('Ambiguous object name, please refine schema.', 16, 1);
	RETURN(1);
END

SELECT
	@ObjectId			= ObjectId
	,@ObjectName		= ObjectName
	,@ObjectType		= ObjectType
	,@ObjectTypeDesc	= ObjectTypeDesc
	,@SchemaName		= SchemaName
FROM #objects;
--#endregion

--#region Get non standard object id
IF @ObjectId IS NULL
BEGIN
	;WITH
	obj AS (		
		SELECT
			 [ObjectId]		= [database_id]
			,[ObjectName]	= [name]
			,[ObjectType]	= 'DATABASE'
			,[SchemaName]	= NULL
		FROM sys.databases
		WHERE [name] = @ObjectName
		UNION ALL
		SELECT
			 [ObjectId]		= p.[principal_id]
			,[ObjectName]	= p.[name]
			,[ObjectType]	= 'SERVER PRINCIPAL'
			,[SchemaName]	= NULL
		FROM sys.server_principals p
		WHERE p.[name] = @ObjectName
		UNION ALL
		SELECT
			 [ObjectId]		= p.[principal_id]
			,[ObjectName]	= p.[name]
			,[ObjectType]	= 'DATABASE PRINCIPAL'
			,[SchemaName]	= NULL
		FROM sys.database_principals p
		WHERE p.[name] = @ObjectName
			AND NOT EXISTS (
				SELECT 1
				FROM sys.all_objects o
					JOIN sys.schemas s
						ON s.[principal_id] = o.[schema_id]
				WHERE s.[name] = p.[default_schema_name]
			)
		UNION ALL
		SELECT
			 [ObjectId]		= [schema_id]
			,[ObjectName]	= [name]
			,[ObjectType]	= 'SCHEMA'
			,[SchemaName]	= NULL
		FROM sys.schemas s
		WHERE [name] = @ObjectName
			--AND EXISTS (
			--	SELECT 1
			--	FROM sys.all_objects o
			--	WHERE o.[schema_id] = s.[schema_id]
			--)
		UNION ALL
		SELECT
			 [ObjectId]		= a.assembly_id
			,[ObjectName]	= a.name
			,[ObjectType]	= 'ASSEMBLY'
			,[SchemaName]	= s.name
		FROM sys.assemblies a
			JOIN sys.schemas s
				ON s.[schema_id] = a.[principal_id]
		WHERE a.[name] = @ObjectName
			AND s.[name] = ISNULL(@SchemaName, s.[name])
		UNION ALL
		SELECT
			 [ObjectId]		= t.[user_type_id]
			,[ObjectName]	= t.[name]
			,[ObjectType]	= 'TYPE'
			,[SchemaName]	= s.[name]
		FROM sys.types t
			JOIN sys.schemas s
				ON s.[schema_id] = t.[schema_id]
		WHERE t.[name] = @ObjectName
			AND s.[name] = ISNULL(@SchemaName, s.[name])
		UNION ALL
		SELECT
			 [ObjectId]		= [object_id]
			,[ObjectName]	= [name]
			,[ObjectType]	= 'DDL TRIGGER'
			,[SchemaName]	= NULL
		FROM sys.triggers
		WHERE [name] = @ObjectName
			AND [parent_id] = 0
		UNION ALL
		SELECT
			 [ObjectId]		= x.[xml_collection_id]
			,[ObjectName]	= x.[name]
			,[ObjectType]	= 'XML SCHEMA COLLECTION'
			,[SchemaName]	= s.[name]
		FROM sys.xml_schema_collections x
			JOIN sys.schemas s
				ON s.[schema_id] = x.[schema_id]
		WHERE x.[name] = @ObjectName
			AND s.[name] = ISNULL(@SchemaName, s.[name])
			AND x.[xml_collection_id] > 1		
		)
	INSERT INTO #objects (
		[ObjectId]
		,[ObjectName]
		,[ObjectType]
		,[SchemaName])
	SELECT
		[ObjectId]
		,[ObjectName]
		,[ObjectType]
		,[SchemaName]	
	FROM obj
	WHERE [ObjectId] IS NOT NULL
		AND (
			[SchemaName] = ISNULL(@SchemaName, [SchemaName])
			OR
			[SchemaName] IS NULL
			)
		AND [ObjectType] = ISNULL(@ObjectType, [ObjectType]);

	IF @@ROWCOUNT > 1
	BEGIN
		SELECT
			[ObjectId]
			,[ObjectName]
			,[ObjectType]
			,[ObjectTypeDesc]
			,[SchemaName]
		FROM #objects
		ORDER BY [ObjectName];

		RAISERROR('Ambiguous object name, please refine schema.', 16, 1);
		RETURN(1);
	END

	SELECT
		@ObjectId			= [ObjectId]
		,@ObjectName		= [ObjectName]
		,@ObjectType		= [ObjectType]
		,@ObjectTypeDesc	= [ObjectType]
		,@SchemaName		= [SchemaName]
	FROM #objects;
END
--#endregion

--#region Build full object name and get OBJECT_ID if not already filled
SET @ObjectNameFull = ISNULL(QUOTENAME(@SchemaName) + '.', '.')
					+ QUOTENAME(@ObjectName);

IF @ObjectId IS NULL
	SET @ObjectId = OBJECT_ID(@ObjectNameFull);
--#endregion

--#region Another try to get schema if not provided
IF @SchemaName IS NULL
	AND @ObjectId IS NOT NULL
BEGIN
	SET @SchemaName = OBJECT_SCHEMA_NAME(@ObjectId);
	
	SET @ObjectNameFull = ISNULL(QUOTENAME(@SchemaName) + '.', '')
					+ QUOTENAME(@ObjectName);
END
--#endregion
GO
