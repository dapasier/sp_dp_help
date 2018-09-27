CREATE PROC dbo.sp_dp_help_object_triggers
	@ObjectId	INT
AS
	;WITH
	ord AS (
		SELECT
			[object_id]
			,[is_first]
			,[is_last]
		FROM sys.trigger_events
		GROUP BY
			[object_id]
			,[is_first]
			,[is_last])
	SELECT
		[ParentName]		= ISNULL(p.name, o.parent_class_desc)
		,[TriggerName]		= o.name
		,[Schema]			= sc.name
		,[Rev]				= r.value
		,[CommitDate]		= CONVERT(DATETIME, d.value, 121)
		,[CreateDate]		= o.create_date
		,[ModifyDate]		= o.modify_date
		,[IsDisabled]		= o.is_disabled
		,[IsInsteadOf]		= o.is_instead_of_trigger
		,[Events]			= STUFF((SELECT ', ' + e.type_desc
									FROM sys.trigger_events e
									WHERE e.object_id = o.object_id
									ORDER BY e.type_desc
									FOR XML PATH(''), TYPE).value('.', 'nvarchar(max)')
									,1
									,2
									,'')
		,[OrderNo]			= CASE 
								WHEN ord.is_first = 1 THEN -1
								WHEN ord.is_last = 1 THEN 1
								ELSE 0
							  END
		,[Order]			= CASE 
								WHEN ord.is_first = 1 THEN 'FIRST'
								WHEN ord.is_last = 1 THEN 'LAST'
								ELSE NULL
							  END
		,[Description]		= de.value
		,[Script]			= ISNULL(m.[definition], '<ENCRYTED>')
	INTO #trigger_info
	FROM sys.triggers o
		JOIN sys.objects ob
			ON ob.object_id = o.object_id
		JOIN sys.schemas sc
			ON sc.schema_id = ob.schema_id
		JOIN ord
			ON ord.object_id = o.object_id
		LEFT JOIN sys.all_objects p
			ON p.[object_id] = o.parent_id
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
	WHERE o.[parent_id] = @ObjectId;

	SELECT
		[TriggerName]
		,[Schema]
		,[Rev]
		,[CommitDate]
		,[CreateDate]
		,[ModifyDate]
		,[IsDisabled]
		,[IsInsteadOf]
		,[Events]
		,[Order]
		,[Description]
		,[Script]
	FROM #trigger_info
	ORDER BY [OrderNo], [TriggerName];
GO
