CREATE PROC dbo.sp_dp_help_type
	@ObjectId	INT
AS
	SELECT
		[TypeName]			= t.[name]
		,[StorageType]		= TYPE_NAME(t.[system_type_id])
		,[Length]			= t.[max_length]
		,[Prec]				= t.[precision]
		,[Scale]			= t.[scale]
		,[Nullable]			= t.[is_nullable]
		,[IsUserDefined]	= t.[is_user_defined]
		,[IsTableType]		= t.[is_table_type]
		,[IsAssemblyType]	= t.[is_assembly_type]
		,[DefaultName]		= OBJECT_NAME(t.[default_object_id])
		,[RuleName]			= OBJECT_NAME(t.[rule_object_id])
		,[Collation]		= t.[collation_name]
	FROM sys.types t
	WHERE t.[user_type_id] = @ObjectId
	ORDER BY [TypeName];
GO
