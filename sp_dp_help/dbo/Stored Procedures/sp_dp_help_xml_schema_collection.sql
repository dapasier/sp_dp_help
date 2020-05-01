CREATE PROC dbo.sp_dp_help_xml_schema_collection
	@ObjectId	INT
AS
EXEC [dbo].[sp_dp_help_print_grid_info]
	@GridMsg	= 'XML Schema Collection';

SELECT
	[XMLSchemaName]		= o.name
	,[Schema]			= sc.name
	,[Rev]				= r.value
	,[CommitDate]		= CONVERT(DATETIME, d.value, 121)
	,[CreateDate]		= o.create_date
	,[ModifyDate]		= o.modify_date
	,[Description]		= de.value
	,[Script]			= XML_SCHEMA_NAMESPACE(sc.name, o.name)
FROM sys.xml_schema_collections o
		JOIN sys.schemas sc
			ON sc.[schema_id] = o.[schema_id]
	LEFT JOIN sys.extended_properties r WITH (nolock)
		ON r.class = 10
			AND r.major_id = o.[xml_collection_id]
			AND r.minor_id = 0
			AND r.name = 'Rev'
	LEFT JOIN sys.extended_properties d WITH (nolock)
		ON d.class = 10
			AND d.major_id = o.[xml_collection_id]
			AND d.minor_id = 0
			AND d.name = 'Date'
	LEFT JOIN sys.extended_properties s WITH (nolock)
		ON s.class = 10
			AND s.major_id = o.[xml_collection_id]
			AND s.minor_id = 0
			AND s.name = 'Status'
	LEFT JOIN sys.extended_properties de WITH (nolock)
		ON de.class = 1
			AND de.major_id = o.xml_collection_id
			AND de.minor_id = 0
			AND de.name = 'Desc'
	LEFT JOIN sys.all_sql_modules m
		ON m.[object_id] = o.[xml_collection_id]
WHERE o.[xml_collection_id] = @ObjectId
ORDER BY [XMLSchemaName];
GO
