CREATE PROC dbo.sp_dp_help_object_space_used
	@ObjectId	INT = NULL
AS
EXEC [dbo].[sp_dp_help_print_grid_info]
	@GridMsg	= 'Space used by objects sorted by Reserved space descending.';

;WITH 
aggr AS (
	SELECT
		[ObjectName]	= QUOTENAME(s.[name]) + '.' + QUOTENAME(o.[name])
		,[ObjectType]	= o.[type_desc]
		,[Reserved]		= SUM(ps.[reserved_page_count]) * 8 / 1024.
		,[Used]			= SUM(ps.[used_page_count]) * 8 / 1024.
		,[Data]			= SUM(
							CASE  
								WHEN (ps.[index_id] < 2) 
									THEN (ps.[in_row_data_page_count] + ps.[lob_used_page_count] + ps.[row_overflow_used_page_count])  
								ELSE ps.[lob_used_page_count] + ps.[row_overflow_used_page_count]  
							END
						) * 8 / 1024.
		,[Rowcount]		= SUM(
							CASE  
								WHEN (ps.[index_id] < 2) THEN ps.[row_count]
								ELSE 0  
							END
						)
		,[DataSpace]	= ds.name
	FROM sys.dm_db_partition_stats ps
		JOIN sys.objects o
			ON o.object_id = ps.object_id
		JOIN sys.schemas s
			ON o.schema_id = s.schema_id
		JOIN sys.indexes i
			ON i.object_id = o.object_id
			AND i.index_id = ps.index_id
		LEFT JOIN sys.data_spaces ds
			ON ds.data_space_id = i.data_space_id
	WHERE o.object_id = ISNULL(@ObjectId, o.object_id)
	GROUP BY 
		s.[name]
		,o.[name]
		,o.[type_desc]
		,ds.[name]
)
SELECT
	a.[ObjectName]
	,a.[ObjectType]
	,[Reserved (MB)]	= master.dbo.FormatNumeric(a.[Reserved], 2, default, default, default, 12)
	,[Data (MB)]		= master.dbo.FormatNumeric(a.[Data], 2, default, default, default, 12)
	,[Indexes (MB)]		= master.dbo.FormatNumeric(a.[Used] - a.[Data], 2, default, default, default, 12)
	,[Unused (MB)]		= master.dbo.FormatNumeric(a.[Reserved] - a.[Used], 2, default, default, default, 12)
	,[Rowcount]			= master.dbo.FormatNumeric(a.[Rowcount], 0, default, default, default, 12)
	,a.[DataSpace]
FROM aggr a
ORDER BY [Reserved] DESC;
GO
