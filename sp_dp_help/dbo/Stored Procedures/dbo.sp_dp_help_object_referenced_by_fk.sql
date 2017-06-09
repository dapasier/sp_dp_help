CREATE PROC dbo.sp_dp_help_object_referenced_by_fk
	@ObjectId	INT
AS
	SELECT
		 [ForeignKey]			= f.[name]
		,[ReferencingObject]	= s.name + '.' + o.name
		,[IsDisabled]			= f.is_disabled
		,[Columns]				= STUFF(
									(SELECT ', ' + c1.name
									FROM sys.foreign_key_columns fkc
									JOIN sys.all_columns c1
										ON c1.object_id = fkc.parent_object_id
											AND c1.column_id = fkc.parent_column_id
									WHERE fkc.constraint_object_id = f.object_id
									ORDER BY fkc.constraint_column_id
									FOR XML PATH(''), TYPE).value('.', 'nvarchar(max)')
									,1
									,2
									,'')
		,[References]			= QUOTENAME(frs.name) + '.' + QUOTENAME(fro.name) + ' (' +
									STUFF(
										(SELECT ', ' + c1.name
										FROM sys.foreign_key_columns fkc
										JOIN sys.all_columns c1
											ON c1.object_id = fkc.referenced_object_id
												AND c1.column_id = fkc.referenced_column_id
										WHERE fkc.constraint_object_id = f.object_id
										ORDER BY fkc.constraint_column_id
										FOR XML PATH(''), TYPE).value('.', 'nvarchar(max)')
										,1
										,2
										,'') +
									')'
		,[DeleteAction]			= f.delete_referential_action_desc
		,[UpdateAction]			= f.update_referential_action_desc
		,[IsNotForReplication]	= f.is_not_for_replication
		,[IsNotTrusted]			= f.is_not_trusted
		,[Script]				= NULL
	FROM sys.foreign_keys f
		JOIN sys.objects o
			ON o.object_id = f.parent_object_id
		JOIN sys.schemas s
			ON s.schema_id = o.schema_id			
		JOIN sys.all_objects fro
			ON fro.object_id = f.referenced_object_id
		JOIN sys.schemas frs
			ON frs.schema_id = fro.schema_id
	WHERE f.referenced_object_id = @ObjectId
	ORDER BY [ForeignKey];
GO
