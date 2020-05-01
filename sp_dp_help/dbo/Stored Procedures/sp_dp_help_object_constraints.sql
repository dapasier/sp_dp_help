CREATE PROC dbo.sp_dp_help_object_constraints
	@ObjectId				INT
AS
EXEC [dbo].[sp_dp_help_print_grid_info]
	@GridMsg	= 'Object constraints';

SELECT
	[ConstraintName]			= o.name
	,[ConstraintType]			= REPLACE(REPLACE(o.type_desc COLLATE database_default , '_', ' '), 'CONSTRAINT', '')
								+ CASE 
									WHEN i.index_id = 1	THEN '(clustered)'
									WHEN i.index_id > 1	THEN '(non-clustered)'
									ELSE ''
									END
								+ ISNULL('on column ' + ISNULL(dc.name, cc.name),'')
								+ CASE 
									WHEN c.parent_column_id = 0 THEN 'on table level'
									ELSE ''
									END
	,[IsDisabled]				= COALESCE(i.is_disabled, c.is_disabled, f.is_disabled)
	,[ConstraintColumns]		= COALESCE(
									STUFF(
										(SELECT 
											', ' + c1.name + 
											CASE 
												WHEN ic1.is_descending_key = 1 THEN ' DESC' 
												ELSE '' 
											END
										FROM sys.index_columns ic1
											JOIN sys.all_columns c1
												ON c1.object_id = ic1.object_id
													AND c1.column_id = ic1.column_id
										WHERE ic1.object_id = i.object_id
											AND ic1.index_id = i.index_id
											AND ic1.is_included_column = 0
										ORDER BY ic1.key_ordinal
										FOR XML PATH(''), TYPE).value('.', 'nvarchar(max)')
										,1
										,2
										,''
									)
									,d.[definition] COLLATE database_default
									,c.[definition]
									,STUFF(
										(SELECT ', ' + c1.name
										FROM sys.foreign_key_columns fkc
											JOIN sys.all_columns c1
												ON c1.object_id = fkc.parent_object_id
													AND c1.column_id = fkc.parent_column_id
										WHERE fkc.constraint_object_id = o.object_id
										ORDER BY fkc.constraint_column_id
										FOR XML PATH(''), TYPE).value('.', 'nvarchar(max)')
										,1
										,2
										,''
									)
								)
	,[References]				= QUOTENAME(frs.name) + '.' + QUOTENAME(fro.name) + ' (' +
									STUFF(
										(SELECT ', ' + c1.name
										FROM sys.foreign_key_columns fkc
										JOIN sys.all_columns c1
											ON c1.object_id = fkc.referenced_object_id
												AND c1.column_id = fkc.referenced_column_id
										WHERE fkc.constraint_object_id = o.object_id
										ORDER BY fkc.constraint_column_id											
										FOR XML PATH(''), TYPE).value('.', 'nvarchar(max)')
										,1
										,2
										,''
									) +
								')'
	,[DeleteAction]				= f.delete_referential_action_desc
	,[UpdateAction]				= f.update_referential_action_desc
	,[IsNotForReplication]		= ISNULL(c.is_not_for_replication, f.is_not_for_replication)
	,[IsNotTrusted]				= ISNULL(c.is_not_trusted, f.is_not_trusted)
	,[Script]					= NULL
FROM sys.all_objects o
	LEFT JOIN sys.indexes i
		ON i.object_id = o.parent_object_id
		AND i.name = o.name
	LEFT JOIN sys.default_constraints d
		ON d.object_id = o.object_id
	LEFT JOIN sys.columns dc
		ON dc.object_id = d.parent_object_id
		AND dc.column_id = d.parent_column_id
	LEFT JOIN sys.check_constraints c
		ON c.object_id = o.object_id
	LEFT JOIN sys.columns cc
		ON cc.object_id = c.parent_object_id
		AND cc.column_id = c.parent_column_id
	LEFT JOIN sys.foreign_keys f
		ON f.object_id = o.object_id
	LEFT JOIN sys.all_objects fro
		ON fro.object_id = f.referenced_object_id
	LEFT JOIN sys.schemas frs
		ON frs.schema_id = fro.schema_id
WHERE o.parent_object_id = @ObjectId
	AND o.type NOT IN ('TR', 'IT')
ORDER BY o.type DESC, o.name;
GO
