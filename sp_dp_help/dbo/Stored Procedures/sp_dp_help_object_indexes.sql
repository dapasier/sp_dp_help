CREATE PROC dbo.sp_dp_help_object_indexes
	@ObjectId		INT
	,@SchemaName	SYSNAME
	,@ObjectName	SYSNAME
AS
	DECLARE
		 @crlf	CHAR(2)	 = CHAR(13) + CHAR(10);

	;WITH
	partitions_info AS (
		SELECT
			p.object_id
			,p.index_id
			,[allocation_type]	= au.type_desc
			,[rows]				= SUM(p.rows)
			,[used_pages]		= SUM(au.used_pages)
			,[partitions_count]	= COUNT(p.partition_number)
		FROM sys.partitions p
		LEFT JOIN sys.allocation_units au
			ON au.container_id = p.partition_id
		WHERE p.object_id = @ObjectId
		GROUP BY p.object_id
			,p.index_id
			,au.type_desc
	)
	SELECT
		 [IndexName]		= i.name
		,[IndexType]		= 
							CASE i.is_disabled
								WHEN 1 THEN 'DISABLED '
								ELSE ''
							END
							+ i.type_desc +
							CASE i.is_primary_key
								WHEN 1 THEN ' PK'
								ELSE ''
							END +
							CASE 
								WHEN i.is_unique = 1
									AND i.is_primary_key = 0 THEN ' UNIQUE'
								ELSE ''
							END
		,[Columns]			= STUFF((SELECT ', ' + c1.name + CASE WHEN ic1.is_descending_key = 1 THEN ' DESC' ELSE '' END
									FROM sys.index_columns ic1
									JOIN sys.all_columns c1
										ON c1.object_id = ic1.object_id
											AND c1.column_id = ic1.column_id
									WHERE ic1.object_id = o.object_id
										AND ic1.index_id = i.index_id
										AND ic1.is_included_column = 0
									ORDER BY ic1.key_ordinal
									FOR XML PATH(''), TYPE).value('.', 'nvarchar(max)'), 1, 1, '')
		,[Include]			= STUFF((SELECT ', ' + c1.name + CASE WHEN ic1.is_descending_key = 1 THEN ' DESC' ELSE '' END
									FROM sys.index_columns ic1
									JOIN sys.all_columns c1
										ON c1.object_id = ic1.object_id
											AND c1.column_id = ic1.column_id
									WHERE ic1.object_id = o.object_id
										AND ic1.index_id = i.index_id
										AND ic1.is_included_column = 1
									ORDER BY ic1.key_ordinal
									FOR XML PATH(''), TYPE).value('.', 'nvarchar(max)'), 1, 1, '')
		,[Filter]			= i.filter_definition
		,[AllocationType]	= p.allocation_type
		,[Space (MB)]		= master.dbo.FormatNumeric((p.used_pages * 8) / 1024., 2, default, default, default, 12)
		,[Space (%)]		= CAST((p.used_pages * 1.) / NULLIF(SUM(p.used_pages) OVER(PARTITION BY o.name), 0) * 100 as decimal(19,2))
		,[Rowcount]			= master.dbo.FormatNumeric(p.[rows], 0, default, default, default, 12)
		,[IsDisabled]		= i.is_disabled
		,[FillFactor]		= i.fill_factor
		,[UserSeeks]		= s.user_seeks
		,[UserScans]		= s.user_scans
		,[UserLookups]		= s.user_lookups
		,[LastUserSeek]		= s.last_user_seek
		,[LastUserScan]		= s.last_user_scan
		,[LastUserLookup]	= s.last_user_lookup
		,[PartitionsCount]	= p.partitions_count
		,[Script]			= CASE i.is_primary_key
									WHEN 1 THEN
										'ALTER TABLE ' + QUOTENAME(@SchemaName) + '.' + QUOTENAME(@ObjectName) +
										' ADD CONSTRAINT ' + QUOTENAME(i.name) +
										' PRIMARY KEY ' + i.type_desc + @crlf
									ELSE
										'CREATE ' +
										CASE i.is_unique
											WHEN 1 THEN 'UNIQUE '
											ELSE ''
										END +
										i.type_desc + ' ' +
										'INDEX ' + QUOTENAME(i.name) + ' ON ' + 
										QUOTENAME(@SchemaName) + '.' + QUOTENAME(@ObjectName) + @crlf
								END +
								'(' + @crlf + '	' +
								STUFF(
										(SELECT 
											'	,' + QUOTENAME(c1.name) + 
											CASE 
												WHEN ic1.is_descending_key = 1 
													THEN ' DESC' 
													ELSE ' ASC' 
											END +
											@crlf
										FROM sys.index_columns ic1
											JOIN sys.all_columns c1
											ON c1.object_id = ic1.object_id
												AND c1.column_id = ic1.column_id
										WHERE ic1.object_id = o.object_id
											AND ic1.index_id = i.index_id
											AND ic1.is_included_column = 0
										ORDER BY ic1.key_ordinal
										FOR XML PATH(''), TYPE).value('.', 'nvarchar(max)')
										,1
										,2
										,''
									) COLLATE database_default + 
								')' + @crlf +
								ISNULL('INCLUDE (' + 
									STUFF(
										(SELECT 
											', ' + QUOTENAME(c1.name)
										FROM sys.index_columns ic1
											JOIN sys.all_columns c1
												ON c1.object_id = ic1.object_id
													AND c1.column_id = ic1.column_id
										WHERE ic1.object_id = o.object_id
											AND ic1.index_id = i.index_id
											AND ic1.is_included_column = 1
										ORDER BY ic1.index_column_id
										FOR XML PATH(''), TYPE).value('.', 'nvarchar(max)')
										,1
										,2
										,''
									) +
									')' + @crlf, '') +
								ISNULL('WHERE ' + i.filter_definition + @crlf, '') +
								'ON ' + QUOTENAME(
									(SELECT TOP(1)
										d.name
									FROM sys.data_spaces d
										JOIN sys.indexes i
											ON i.data_space_id = d.data_space_id
											AND i.index_id < 2
									WHERE i.object_id = o.object_id)
								)
	FROM sys.all_objects o
		JOIN sys.indexes i
			ON i.object_id = o.object_id
		LEFT JOIN sys.dm_db_index_usage_stats s
			ON s.database_id = DB_ID()
				AND i.object_id = s.object_id
				AND i.index_id = s.index_id
		LEFT JOIN partitions_info p
			ON i.object_id = p.object_id
				AND i.index_id = p.index_id
	WHERE o.[object_id] = @ObjectId
	ORDER BY [Space (MB)] DESC, [IndexName];
GO
