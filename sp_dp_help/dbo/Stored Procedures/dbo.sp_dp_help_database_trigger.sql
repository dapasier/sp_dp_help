CREATE PROC dbo.sp_dp_help_database_trigger
	@ObjectId		INT
	,@SchemaName	SYSNAME
AS
	SELECT
		 [DatabaseTriggerName]	= o.[name]
		,[Schema]				= @SchemaName
		,[Rev]					= r.[value]
		,[CommitDate]			= CONVERT(DATETIME, d.[value], 121)
		,[CreateDate]			= o.[create_date]
		,[ModifyDate]			= o.[modify_date]
		,[IsDisabled]			= o.[is_disabled]
		,[IsInsteadOf]			= o.[is_instead_of_trigger]
		,[Events]				= STUFF(
									(SELECT ', ' + e.[type_desc]
									FROM sys.trigger_events e
									WHERE e.object_id = o.object_id
									ORDER BY e.type_desc
									FOR XML PATH(''), TYPE).value('.', 'nvarchar(max)')
									,1
									,1
									,''
								)
		,[Description]			= de.value
		,[Script]				= ISNULL(m.[definition], '<ENCRYTED>')
	FROM sys.triggers o
		LEFT JOIN sys.extended_properties r WITH (nolock)
			ON r.class = 1
				AND r.major_id = o.[object_id]
				AND r.minor_id = 0
				AND r.name = 'Rev'
		LEFT JOIN sys.extended_properties d WITH (nolock)
			ON d.class = 1
				AND d.major_id = o.[object_id]
				AND d.minor_id = 0
				AND d.name = 'Date'
		LEFT JOIN sys.extended_properties s WITH (nolock)
			ON s.class = 1
				AND s.major_id = o.[object_id]
				AND s.minor_id = 0
				AND s.name = 'Status'
		LEFT JOIN sys.extended_properties de WITH (nolock)
			ON de.class = 1
				AND de.major_id = o.[object_id]
				AND de.minor_id = 0
				AND de.name = 'Desc'
		LEFT JOIN sys.all_sql_modules m
			ON m.[object_id] = o.[object_id]
	WHERE o.[object_id] = @ObjectId;
GO
