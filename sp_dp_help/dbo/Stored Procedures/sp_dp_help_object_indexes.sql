CREATE PROC dbo.sp_dp_help_object_indexes
	@ObjectId		INT
	,@SchemaName	SYSNAME	= NULL
	,@ObjectName	SYSNAME	= NULL
AS
EXEC [dbo].[sp_dp_help_print_grid_info]
	@GridMsg	= 'Object indexes';

;WITH
object_indexes AS (
	SELECT
		o.object_id
		,i.index_id
		,i.name
		,[Columns]			= STUFF(
								(
									SELECT
										', ' + c1.name + IIF(ic1.is_descending_key = 1, ' DESC', '')
									FROM sys.index_columns ic1
										JOIN sys.all_columns c1
											ON c1.object_id = ic1.object_id
												AND c1.column_id = ic1.column_id
									WHERE ic1.object_id = i.object_id
										AND ic1.index_id = i.index_id
										AND ic1.is_included_column = 0
									ORDER BY ic1.key_ordinal
									FOR XML PATH(''), TYPE
								).value('.', 'nvarchar(max)')
								,1
								,2
								,''
							)
		,i.type
		,i.type_desc
		,internal_type_desc	= NULL
		,i.is_unique
		,i.data_space_id
		,i.is_primary_key
		,i.is_disabled
		,i.fill_factor
		,i.filter_definition
	FROM sys.all_objects o
		JOIN sys.indexes i
			ON i.object_id = o.object_id
	WHERE o.object_id = @ObjectId
		AND i.type NOT IN (3, 4)

	UNION ALL

	SELECT
		it.object_id
		,i.index_id
		,i.name
		,[Columns]			= STUFF(
								(
									SELECT
										', ' + c1.name + IIF(ic1.is_descending_key = 1, ' DESC', '')
									FROM sys.index_columns ic1
										JOIN sys.all_columns c1
											ON c1.object_id = ic1.object_id
												AND c1.column_id = ic1.column_id
									WHERE ic1.object_id = ip.object_id
										AND ic1.index_id = ip.index_id
										AND ic1.is_included_column = 0
									ORDER BY ic1.key_ordinal
									FOR XML PATH(''), TYPE
								).value('.', 'nvarchar(max)')
								,1
								,2
								,''
							)
		,ip.type
		,ip.type_desc
		,it.internal_type_desc
		,i.is_unique
		,i.data_space_id
		,i.is_primary_key
		,i.is_disabled
		,i.fill_factor
		,i.filter_definition
	FROM sys.internal_tables it
		JOIN sys.indexes i
			ON i.object_id = it.object_id
		JOIN sys.indexes ip
			ON ip.object_id = it.parent_id
			AND ip.name = i.name
	WHERE it.parent_id = @ObjectId
)
,partitions_info AS (
	SELECT
		p.object_id
		,p.index_id
		,[allocation_type]	= IIF(o.type IN (3, 4), o.internal_type_desc, au.type_desc)
		,[rows]				= SUM(p.rows)
		,[used_pages]		= SUM(au.used_pages)
		,[partitions_count]	= COUNT(p.partition_number)
	FROM sys.partitions p
		JOIN object_indexes o
			ON p.object_id = o.object_id
			AND p.index_id = o.index_id
		LEFT JOIN sys.allocation_units au
			ON au.container_id = p.partition_id
	GROUP BY p.object_id
		,p.index_id
		,o.type
		,o.internal_type_desc
		,au.type_desc
)
SELECT
	[IndexName]			= o.name
	,[IndexType]		= CONCAT(
							IIF(o.is_disabled = 1, 'DISABLED ', '')
							,o.type_desc
							,IIF(o.is_primary_key = 1, ' PK', '')
							,IIF(o.is_unique = 1
								AND o.is_primary_key = 0, ' UNIQUE', '')
						)
	,o.[Columns]
	,[Include]			= STUFF(
							(
								SELECT
									', ' + c1.name + IIF(ic1.is_descending_key = 1, ' DESC', '')
								FROM sys.index_columns ic1
									JOIN sys.all_columns c1
										ON c1.object_id = ic1.object_id
											AND c1.column_id = ic1.column_id
								WHERE ic1.object_id = o.object_id
									AND ic1.index_id = o.index_id
									AND ic1.is_included_column = 1
								ORDER BY ic1.key_ordinal
								FOR XML PATH(''), TYPE
							).value('.', 'nvarchar(max)')
							,2
							,1
							,''
						)
	,[Filter]			= o.filter_definition
	,[AllocationType]	= p.allocation_type
	,[Space (MB)]		= master.dbo.FormatNumeric((p.used_pages * 8) / 1024., 2, default, default, default, 12)
	,[Space (%)]		= CAST((p.used_pages * 1.) / NULLIF(SUM(p.used_pages) OVER(), 0) * 100 as decimal(19,2))
	,[Rowcount]			= master.dbo.FormatNumeric(p.[rows], 0, default, default, default, 12)
	,[IsDisabled]		= o.is_disabled
	,[FillFactor]		= o.fill_factor
	,[UserSeeks]		= s.user_seeks
	,[UserScans]		= s.user_scans
	,[UserLookups]		= s.user_lookups
	,[LastUserSeek]		= s.last_user_seek
	,[LastUserScan]		= s.last_user_scan
	,[LastUserLookup]	= s.last_user_lookup
	,[PartitionsCount]	= p.partitions_count
	,[FileGroup]		= fg.name
FROM object_indexes o
	LEFT JOIN sys.dm_db_index_usage_stats s
		ON s.database_id = DB_ID()
			AND o.object_id = s.object_id
			AND o.index_id = s.index_id
	LEFT JOIN partitions_info p
		ON o.object_id = p.object_id
			AND o.index_id = p.index_id
	LEFT JOIN sys.filegroups fg
		ON o.data_space_id = fg.data_space_id
ORDER BY [Space (MB)] DESC, [IndexName];
GO
