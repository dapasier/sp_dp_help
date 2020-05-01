CREATE PROC dbo.sp_dp_help_object_parameters
	@ObjectId	INT
	,@tab_len	INT		= 4
AS
DECLARE	
	@tab		CHAR(1)	= CHAR(9);

EXEC [dbo].[sp_dp_help_print_grid_info]
	@GridMsg	= 'Object parameters';

SELECT
	[ParamName]		= p.name
	,[Type]			= t.name
	,[Length]		= p.max_length
	,[Prec]			= p.precision
	,[Scale]		= p.scale
	,[IsOutput]		= p.is_output
	,[IsReadonly]	= p.is_readonly
	,[XSD]			= x.name
	,[Collation]	= CASE 
						WHEN p.system_type_id in (35, 99, 167, 175, 231, 239)
							THEN ServerProperty('collation')
						END
	,[Default]		= df.value
	,[Description]	= de.value
	,[Execute]		= CASE p.parameter_id
						WHEN 1 THEN ' '
						ELSE ','
					END + NULLIF(p.name, '') +
						REPLICATE(@tab, (CEILING(MAX(LEN(p.name) + 1) OVER() / @tab_len) - FLOOR((LEN(p.name) + 1) / @tab_len)) + 1) +
						'= ' + 
						ISNULL(
							CONVERT(nvarchar(1000), df.value), 
							CASE t.name
								WHEN 'bit' THEN '0'
								WHEN 'tinyint' THEN '0'
								WHEN 'smallint' THEN '0'
								WHEN 'int' THEN '0'
								WHEN 'bigint' THEN '0'
									
								WHEN 'char' THEN ''''''
								WHEN 'varchar' THEN ''''''
								WHEN 'text' THEN ''''''
								WHEN 'nchar' THEN 'N'''''
								WHEN 'nvarchar' THEN 'N'''''
								WHEN 'sysname' THEN 'N'''''
								WHEN 'ntext' THEN 'N'''''

								WHEN 'binary' THEN '0x0'
								WHEN 'varbinary' THEN '0x0'
								WHEN 'image' THEN '0x0'
								WHEN 'uniqueidentifier' THEN '''' + CONVERT(varchar(36), CONVERT(uniqueidentifier, 0x0)) + ''''

								WHEN 'time' THEN '''' + CONVERT(varchar(17), CONVERT(time, SYSDATETIME()), 121) + ''''
								WHEN 'date' THEN '''' + CONVERT(varchar(10), CONVERT(date, GETDATE())) + ''''
								WHEN 'smalldatetime' THEN '''' + CONVERT(varchar(16), CONVERT(smalldatetime, GETDATE()), 121) + ''''
								WHEN 'datetime' THEN '''' + CONVERT(varchar(23), GETDATE(), 121) + ''''
								WHEN 'datetime2' THEN '''' + CONVERT(varchar(28), SYSDATETIME()) + ''''
								WHEN 'datetimeoffset' THEN '''' + CONVERT(varchar(35), SYSDATETIMEOFFSET()) + ''''

								WHEN 'decimal' THEN '0.0'
								WHEN 'float' THEN '0.0'
								WHEN 'smallmoney' THEN '0.0'
								WHEN 'money' THEN '0.0'
								WHEN 'numeric' THEN '0.0'
								WHEN 'real' THEN '0.0'
									
								WHEN 'sql_variant' THEN ''''''
								WHEN 'xml' THEN ''''''
								ELSE ''
							END
						) +
						CASE p.is_output
							WHEN 1 THEN ' OUTPUT'
							ELSE ''
						END
	,[Script]		= CASE p.parameter_id
						WHEN 1 THEN ' '
						ELSE ','
					END + NULLIF(p.name, '') +
						REPLICATE(@tab, (CEILING(MAX(LEN(p.name) + 1) OVER() / @tab_len) - FLOOR((LEN(p.name) + 1) / @tab_len)) + 1) +
						QUOTENAME(t.name) +
						CASE
							WHEN t.name IN (
								'time',
								'varbinary',
								'varchar',
								'binary',
								'char') 
								THEN '(' + ISNULL(CONVERT(nvarchar(19), NULLIF(p.max_length, -1)), 'max') + ')'
							WHEN t.name IN (								
								'nvarchar',
								'nchar') 
								THEN '(' + ISNULL(CONVERT(nvarchar(19), NULLIF(p.max_length, -1)/ 2), 'max') + ')'
							WHEN t.name IN (
								'decimal',
								'numeric')
								THEN '(' + CONVERT(nvarchar(19), p.precision) + ',' + CONVERT(nvarchar(19), p.scale) + ')'
							ELSE ''
						END +
						ISNULL(' (' + QUOTENAME(x.name) + ') ', '') +
						ISNULL(' = ' + CONVERT(nvarchar(1000), df.value), '') +
						CASE p.is_output
							WHEN 1 THEN ' OUTPUT'
							ELSE ''
						END +
						CASE p.is_readonly
							WHEN 1 THEN ' READONLY'
							ELSE ''
						END
FROM sys.all_parameters p
	JOIN sys.types t
		ON t.user_type_id = p.user_type_id
	LEFT JOIN sys.xml_schema_collections x
		ON x.xml_collection_id = p.xml_collection_id
	LEFT JOIN sys.extended_properties de WITH (nolock)
		ON de.class = 2
			AND de.major_id = p.[object_id]
			AND de.minor_id = p.parameter_id
			AND de.name = 'desc'
	LEFT JOIN sys.extended_properties df WITH (nolock)
		ON df.class = 2
			AND df.major_id = p.[object_id]
			AND df.minor_id = p.parameter_id
			AND df.name = 'default'
WHERE [object_id] = @ObjectId
ORDER BY parameter_id;
GO
