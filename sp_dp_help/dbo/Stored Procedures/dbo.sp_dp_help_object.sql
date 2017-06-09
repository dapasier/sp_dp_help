CREATE PROC dbo.sp_dp_help_object
	@ObjectId			INT
	,@ObjectType		SYSNAME
	,@BaseObjectName	NVARCHAR(1035)	
AS
	;WITH 
	aggr AS (
		SELECT
			[ObjectId]		= s.object_id
			,[Reserved]		= SUM(s.reserved_page_count) * 8 / 1024.
			,[Used]			= SUM(s.used_page_count) * 8 / 1024.
			,[Data]			= SUM(
								CASE  
									WHEN (s.index_id < 2) 
										THEN (s.in_row_data_page_count + s.lob_used_page_count + s.row_overflow_used_page_count)  
									ELSE s.lob_used_page_count + s.row_overflow_used_page_count  
								END) * 8 / 1024.
			,[Rowcount]		= SUM(
								CASE  
									WHEN (s.index_id < 2) THEN s.row_count  
									ELSE 0  
								END)
		FROM sys.dm_db_partition_stats s
		GROUP BY s.object_id)
	SELECT
		 [ObjectName]		= o.name
		,[Schema]			= sc.name
		,[ObjectType]		= o.type_desc
		,[Rev]				= r.value
		,[Status]			= s.value
		,[CommitDate]		= d.value
		,[CreateDate]		= o.create_date
		,[ModifyDate]		= o.modify_date
		,[BaseObjectName]	= @BaseObjectName
		,[Reserved (MB)]	= master.dbo.FormatNumeric(a.[Reserved], 2, default, default, default, 12)
		,[Data (MB)]		= master.dbo.FormatNumeric(a.[Data], 2, default, default, default, 12)
		,[Indexes (MB)]		= master.dbo.FormatNumeric(a.[Used] - a.[Data], 2, default, default, default, 12)
		,[Unused (MB)]		= master.dbo.FormatNumeric(a.[Reserved] - a.[Used], 2, default, default, default, 12)
		,[Rowcount]			= master.dbo.FormatNumeric(a.[Rowcount], 0, default, default, default, 12)
		,[Description]		= de.value
		,[Script]			= CASE
								WHEN o.type IN ('FN', 'IF', 'V ', 'P ', 'TF', 'TR') 
									THEN ISNULL(m.[definition], '<ENCRYTED>')
							  END
	INTO #object_info
	FROM sys.all_objects o
		JOIN sys.schemas sc
			ON sc.schema_id = o.schema_id
		LEFT JOIN aggr a
			ON a.ObjectId = o.object_id
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

	IF @ObjectType IN ('U', 'IT', 'S')
		SELECT
			[ObjectName]
			,[Schema]
			,[ObjectType]
			,[Rev]
			,[Status]
			,[CommitDate]
			,[CreateDate]
			,[ModifyDate]
			,[Reserved (MB)]
			,[Data (MB)]
			,[Indexes (MB)]
			,[Unused (MB)]
			,[Rowcount]
			,[Description]
		FROM #object_info
		ORDER BY [ObjectName];
	ELSE
		IF @ObjectType IN ('SN')
		SELECT
			[ObjectName]
			,[Schema]
			,[ObjectType]
			,[Rev]
			,[Status]
			,[CommitDate]
			,[CreateDate]
			,[ModifyDate]
			,[BaseObjectName]
			,[Description]
			,[Script]
		FROM #object_info
		ORDER BY [ObjectName];
		ELSE
		SELECT
			[ObjectName]
			,[Schema]
			,[ObjectType]
			,[Rev]
			,[Status]
			,[CommitDate]
			,[CreateDate]
			,[ModifyDate]
			,[Description]
			,[Script]
		FROM #object_info
		ORDER BY [ObjectName];
GO
