CREATE PROC dbo.sp_dp_help_object_dependencies_up
	@ObjectId			INT
	,@SchemaName		SYSNAME
	,@ObjectName		SYSNAME
	,@ObjectNameFull	NVARCHAR(392)
	,@ObjectType		SYSNAME
	,@ObjectTypeDesc	SYSNAME
	,@DbName			SYSNAME
AS
DECLARE
	@ObjectNameDep		SYSNAME
	,@ObjectTypeDep		SYSNAME

	SELECT
		@ObjectTypeDep = CASE @ObjectType
                         	WHEN 'TYPE' THEN 'TYPE'
                         	WHEN 'XML SCHEMA COLLECTION' THEN 'XML_SCHEMA_COLLECTION'
							WHEN 'PARTITION FUNCTION' THEN 'PARTITION_FUNCTION'							
                         	ELSE 'OBJECT'
                         END

	IF @ObjectName LIKE '%[[]%]'
		AND @ObjectId IS NOT NULL
		SET @ObjectNameDep = PARSENAME(@ObjectName, 1);
	ELSE
		SET @ObjectNameDep = @ObjectName;

	;WITH
	hard_f AS (
		SELECT 
			[Level]					= 1
			,[ParentId]				= d.referencing_id
			,[ParentNameFull]		= COALESCE(QUOTENAME(s.name) + '.' + QUOTENAME(o.name), t.name)
			,[ParentSchema]			= s.name
			,[ParentName]			= o.name
			,[ChildId]				= @ObjectId
			,[ChildNameFull]		= @ObjectNameFull
			,[ChildSchema]			= @SchemaName
			,[ChildName]			= @ObjectName
			,[OrderNo]				= 1
		FROM sys.dm_sql_referencing_entities(@ObjectNameFull, @ObjectTypeDep) d
			LEFT JOIN sys.all_objects o
				ON o.[object_id] = d.referencing_id
			LEFT JOIN sys.schemas s
				ON s.[schema_id] = o.[schema_id]
			LEFT JOIN sys.triggers t
				ON t.[object_id] = d.referencing_id
				AND d.referencing_class = 12
		WHERE d.referencing_id != @ObjectId
		
		UNION ALL

		SELECT 
			[Level]					= 1
			,[ParentId]				= o.object_id
			,[ParentNameFull]		= QUOTENAME(s.name) + '.' + QUOTENAME(o.name)
			,[ParentSchema]			= s.name
			,[ParentName]			= o.name
			,[ChildId]				= @ObjectId
			,[ChildNameFull]		= @ObjectNameFull
			,[ChildSchema]			= @SchemaName
			,[ChildName]			= @ObjectName
			,[OrderNo]				= 1
		FROM sys.synonyms o
			JOIN sys.schemas s
				ON s.schema_id = o.schema_id
		WHERE o.base_object_name = @ObjectNameFull
	),
	hard_t AS (
		SELECT 
			[Level]
			,[ParentId]
			,[ParentNameFull]
			,[ParentSchema]
			,[ParentName]
			,[ChildId]
			,[ChildNameFull]
			,[ChildSchema]
			,[ChildName]
			,[OrderNo]
		FROM hard_f
				
		UNION ALL
		
		SELECT
			[Level]					= [Level] + 1
			,[ParentId]				= e.referencing_id
			,[ParentNameFull]		= ISNULL(QUOTENAME(e.referencing_schema_name) + '.', '')
										+ QUOTENAME(e.referencing_entity_name)
			,[ParentSchema]			= e.referencing_schema_name
			,[ParentName]			= e.referencing_entity_name
			,[ChildId]				= h.ParentId
			,[ChildNameFull]		= CONVERT(NVARCHAR(392), h.ParentNameFull)
			,[ChildSchema]			= h.ParentSchema
			,[ChildName]			= h.ParentName
			,[OrderNo]				= 1
		FROM hard_t h
			CROSS APPLY sys.dm_sql_referencing_entities(h.ParentNameFull, 'OBJECT') e
		WHERE h.[ParentId] != e.referencing_id
	),
	hard_g AS (
		SELECT
			[Level]
			,[ParentId]
			,[ParentNameFull]
			,[ParentSchema]
			,[ParentName]
			,[ChildId]
			,[ChildNameFull]
			,[ChildSchema]
			,[ChildName]
			,[OrderNo]
		FROM hard_t
		GROUP BY 
			[Level]
			,[ParentId]
			,[ParentNameFull]
			,[ParentSchema]
			,[ParentName]
			,[ChildId]
			,[ChildNameFull]
			,[ChildSchema]
			,[ChildName]
			,[OrderNo]
	),
	hard AS (
		SELECT
			[Level]
			,[ParentId]
			,[ParentNameFull]
			,[ParentSchema]
			,[ParentName]
			,[ParentType]		= p.type_desc
			,[ParentText]		= m.[definition]
			,[ChildId]
			,[ChildNameFull]
			,[ChildSchema]
			,[ChildName]
			,[ChildType]		= ISNULL(c.type_desc, @ObjectType)
			,[OrderNo]
		FROM hard_g h
			LEFT JOIN sys.all_objects p
				ON p.[object_id] = h.ParentId
			LEFT JOIN sys.all_objects c
				ON c.[object_id] = h.ChildId
			LEFT JOIN sys.all_sql_modules m
				ON m.[object_id] = h.ParentId
		WHERE NOT EXISTS (
			SELECT 1
			FROM hard_g
			WHERE [ChildNameFull] = h.[ChildNameFull]
				AND [Level] < h.[Level])
	),
	soft AS (
		SELECT
			[Level]					= 1
			,[ParentId]				= m.[object_id]
			,[ParentSchema]			= s.name
			,[ParentName]			= o.name
			,[ParentType]			= o.type_desc
			,[ParentText]			= m.[definition]
			,[ChildId]				= @ObjectId
			,[ChildSchema]			= @SchemaName
			,[ChildName]			= @ObjectName
			,[ChildType]			= @ObjectTypeDesc
			,[OrderNo]				= 2
		FROM sys.all_sql_modules m
			JOIN sys.all_objects o
				ON o.[object_id] = m.[object_id]
			JOIN sys.schemas s
				ON s.[schema_id] = o.[schema_id]
			LEFT JOIN hard h
				ON h.[ParentId] = m.[object_id]
		WHERE m.definition LIKE '%' + @ObjectNameDep + '%'
			AND h.[ParentId] IS NULL
			AND m.[object_id] != ISNULL(@ObjectId, -1)
	),
	job AS (
		SELECT
			[Level]					= 1
			,[ParentId]				= NULL
			,[ParentSchema]			= NULL
			,[ParentName]			= j.name + ':' + CONVERT(nvarchar(10), s.step_id) + ':' + s.step_name
			,[ParentType]			= 'JOB'
			,[ParentText]			= s.command
			,[ChildId]				= @ObjectId
			,[ChildSchema]			= @SchemaName
			,[ChildName]			= @ObjectName
			,[ChildType]			= @ObjectTypeDesc
			,[OrderNo]				= 2
		FROM msdb.dbo.sysjobs j
			JOIN msdb.dbo.sysjobsteps s
				ON j.job_id = s.job_id
		WHERE s.command LIKE '%' + @ObjectNameDep + '%'
			AND s.database_name IN (@DbName, 'master')
	),
	unia AS (
		SELECT
			[Level]
			,[ParentId]
			,[ParentSchema]
			,[ParentName]
			,[ParentType]
			,[ParentText]
			,[ChildId]
			,[ChildSchema]
			,[ChildName]
			,[ChildType]
			,[OrderNo]
		FROM hard h
		UNION ALL
		SELECT 
			[Level]
			,[ParentId]
			,[ParentSchema]
			,[ParentName]		= '~' + [ParentName]
			,[ParentType]
			,[ParentText]
			,[ChildId]
			,[ChildSchema]
			,[ChildName]
			,[ChildType]
			,[OrderNo]
		FROM soft s
		UNION ALL
		SELECT 
			[Level]
			,[ParentId]
			,[ParentSchema]
			,[ParentName]		= '~' + [ParentName]
			,[ParentType]
			,[ParentText]
			,[ChildId]
			,[ChildSchema]
			,[ChildName]
			,[ChildType]
			,[OrderNo]
		FROM job j
	)

	SELECT
		[Level]
		,[ParentName]
		,[ParentSchema]
		,[ParentType]
		,[ParentText]		
		,[ChildName]
		,[ChildSchema]
		,[ChildType]
	FROM unia
	ORDER BY [Level], [OrderNo], [ChildName], [ParentName];
GO
