CREATE PROC dbo.sp_dp_help_object_columns
	@ObjectId	INT
	,@tab_len	INT		= 4
AS
DECLARE	
	@tab		CHAR(1)	= CHAR(9);

	SELECT
		[ColumnName]	= c.name
		,[Type]			= t.name
		,[Length]		= c.max_length
		,[Prec]			= c.precision
		,[Scale]		= c.scale
		,[Nullable]		= c.is_nullable
		,[Identity]		= 'IDENTITY(' + t.name + ', ' + CONVERT(nvarchar(19), i.seed_value) + ', ' + CONVERT(nvarchar(19), i.increment_value) + ')' 
						+ ISNULL(';' +master.dbo.FormatNumeric(CONVERT(decimal(38, 0), i.last_value), 0, default, default, default, 0), '')
		,[Default]		= d.definition
		,[XSD]			= x.name
		,[Options]		= (
							SELECT
								--[is_ansi_padded]			= NULLIF(c.is_ansi_padded, 0)
								[is_rowguidcol]				= NULLIF(c.is_rowguidcol, 0)
								,[is_computed]				= NULLIF(c.is_computed, 0)
								,[is_filestream]			= NULLIF(c.is_filestream, 0)
								,[is_replicated]			= NULLIF(c.is_replicated, 0)
								,[is_non_sql_subscribed]	= NULLIF(c.is_non_sql_subscribed, 0)
								,[is_merge_published]		= NULLIF(c.is_merge_published, 0)
								,[is_sparse]				= NULLIF(c.is_sparse, 0)
								,[is_column_set]			= NULLIF(c.is_column_set, 0)
							FOR XML PATH(''), ROOT('options'), TYPE
						  )
		,[Collation]	= c.collation_name
		,[Description]	= de.value
		,[Script]		= CASE c.column_id
							WHEN 1 THEN ' '
							ELSE ','
						END + QUOTENAME(c.name) +
						--REPLICATE(@tab, (CEILING(MAX(LEN(c.name) + 3) OVER() / @tab_len) - FLOOR((LEN(c.name) + 3) / @tab_len)) + 1) +
						' ' +
						QUOTENAME(t.name) +
						CASE
							WHEN t.name IN (
								'time',
								'varbinary',
								'varchar',
								'binary',
								'char') 
								THEN '(' + ISNULL(CONVERT(nvarchar(19), NULLIF(c.max_length, -1)), 'max') + ')'
							WHEN t.name IN (
								'nvarchar',
								'nchar') 
								THEN '(' + ISNULL(CONVERT(nvarchar(19), NULLIF(c.max_length, -1)/ 2), 'max') + ')'
							WHEN t.name IN (
								'decimal',
								'numeric')
								THEN '(' + CONVERT(nvarchar(19), c.precision) + ',' + CONVERT(nvarchar(19), c.scale) + ')'
							ELSE ''
						END +
						ISNULL(' (' + QUOTENAME(x.name) + ')', '') +
						ISNULL(' IDENTITY(' + CONVERT(nvarchar(19), i.seed_value) + ', ' + CONVERT(nvarchar(19), i.increment_value) + ')', '') +
						CASE c.is_nullable
							WHEN 0 THEN ' NOT'
							ELSE ''
						END +
						' NULL' +
						ISNULL(' CONSTRAINT ' + QUOTENAME(d.name) + ' DEFAULT ' + d.definition, '')
		,[Insert]		= CASE c.column_id
							WHEN 1 THEN ' '
							ELSE ','
						  END
						+ QUOTENAME(c.name)
		,[Select]		= CASE c.column_id
							WHEN 1 THEN ' '
							ELSE ','
							END
						+ QUOTENAME(c.name)
						+ REPLICATE(@tab, (CEILING(MAX(LEN(c.name) + 3) OVER() / @tab_len) - FLOOR((LEN(c.name) + 3) / @tab_len)) + 1)
						+ '= '
	FROM sys.all_columns c
		JOIN sys.types t
			ON t.user_type_id = c.user_type_id
		LEFT JOIN sys.default_constraints d
			ON d.object_id = c.default_object_id
			AND d.parent_column_id = c.column_id
		LEFT JOIN sys.xml_schema_collections x
			ON x.xml_collection_id = c.xml_collection_id
		LEFT JOIN sys.identity_columns i
			ON i.object_id = c.object_id
			AND i.column_id = c.column_id
		LEFT JOIN sys.extended_properties de WITH (nolock)
			ON de.class = 1
				AND de.major_id = c.[object_id]
				AND de.minor_id = c.[column_id]
				AND de.name = 'Desc'
	WHERE c.[object_id] = @ObjectId
	ORDER BY c.column_id;
GO
