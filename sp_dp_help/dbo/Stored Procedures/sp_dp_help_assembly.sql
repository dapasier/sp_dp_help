CREATE PROC dbo.sp_dp_help_assembly
	@ObjectId	INT
AS
	SELECT
		 [AssemblyName]		= a.[name]
		,[SchemaName]		= s.[name]
		,[CLRName]			= a.[clr_name]
		,[PermissionSet]	= a.[permission_set_desc]
		,[IsVisible]		= a.[is_visible]
		,[IsUserDefined]	= a.[is_user_defined]
		,[CreateDate]		= a.[create_date]
		,[ModifyDate]		= a.[modify_date]
	FROM sys.assemblies a
		JOIN sys.schemas s
			ON s.[schema_id] = a.[principal_id]
	WHERE a.[assembly_id] = @ObjectId;

	SELECT
		[AssemblyFile]		= f.name
		,[Script]			= CASE f.file_id
								WHEN 1 THEN
'CREATE ASSEMBLY [' + a.name + ']
FROM ' + CONVERT(nvarchar(max), f.content, 1) + '
WITH PERMISSION_SET = ' + REPLACE(a.permission_set_desc, '_ACCESS', '') + ';

' COLLATE database_default
								ELSE
'ALTER ASSEMBLY [' + a.name + ']
ADD FILE FROM ' + CONVERT(nvarchar(max), f.content, 1) + '
AS N''' + f.name + ''';

' COLLATE database_default
							END
	FROM sys.assemblies a
		JOIN sys.assembly_files f
			ON f.assembly_id = a.assembly_id
	WHERE a.assembly_id = @ObjectId
	ORDER BY f.file_id;

	SELECT
		[Class]				= m.assembly_class
		,[Method]			= m.assembly_method
		,[ObjectName]		= QUOTENAME(s.name) + '.' + QUOTENAME(o.name)
		,[ObjectType]		= o.type_desc
		,[NullOnNullInput]	= m.null_on_null_input
	FROM sys.assembly_modules m
		JOIN sys.objects o
			ON o.object_id = m.object_id
		JOIN sys.schemas s
			ON s.schema_id = o.schema_id
	WHERE m.[assembly_id] = @ObjectId;
GO
