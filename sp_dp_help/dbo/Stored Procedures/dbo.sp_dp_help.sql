CREATE PROC dbo.sp_dp_help
	 @ObjectNameIn	NVARCHAR(1035)	= NULL
	,@Mode			INT				= NULL
	--0 - standard
	--1 - info only
	--2 - refs only
	,@ObjectTypeIn	SYSNAME			= NULL
AS
--TODO:
--obs³uga Check Constraint
--poprawiæ obs³ugê pobierania opisu dla TT
--wyci¹ganie Rev z tekstu
--skryptowanie constraintów
--dodaæ skryptowanie outputu procedury do tabeli tymczasowej
--listê uprawnien dla roli/u¿ytkownika
SET NOCOUNT ON;
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;

--#region Declare variables
DECLARE
	 @ServerName		SYSNAME
	,@DbName			SYSNAME
	,@SchemaName		SYSNAME
	,@ObjectName		SYSNAME
	,@ObjectNameFull	NVARCHAR(392)
	,@ObjectType		SYSNAME
	,@ObjectTypeDesc	SYSNAME
	,@ObjectId			INT
	,@ColumnsObjectId	INT
	,@BaseObjectName	NVARCHAR(1035)
	,@Params			NVARCHAR(MAX)
	,@Query				NVARCHAR(MAX)
	,@grid_no			INT	= 0
	,@grid_msg			VARCHAR(1000)
	,@tab_len			INT = 4
--#endregion

--#region Set defaults
IF @Mode IS NULL
	SET @Mode = 0;
--#endregion

--#region Parse name
SELECT
	 @ServerName	= PARSENAME(@ObjectNameIn, 4)
	,@DbName		= PARSENAME(@ObjectNameIn, 3)
	,@SchemaName	= PARSENAME(@ObjectNameIn, 2)
	,@ObjectName	= PARSENAME(@ObjectNameIn, 1)
	,@ObjectType	= NULLIF(@ObjectTypeIn, '')
--#endregion

--#region WARN: Server name is not supported and it will be omitted.
IF @ServerName IS NOT NULL
	RAISERROR('WARN: Server name is not supported and it will be omitted.', 10, 1);
--#endregion

--#region Give some space usage info if object name not provided
IF @ObjectName IS NULL
BEGIN
	SET @grid_no += 1;
	SET @grid_msg = 'Grid ' + CONVERT(VARCHAR(10), @grid_no) + ': Space used by objects sorted by Reserved space descending.';
	RAISERROR(@grid_msg, 10, 1) WITH NOWAIT;

	EXEC dbo.sp_dp_help_object_space_used;

	SET @grid_no += 1;
	SET @grid_msg = 'Grid ' + CONVERT(VARCHAR(10), @grid_no) + ': Database files info.';
	RAISERROR(@grid_msg, 10, 1) WITH NOWAIT;

	EXEC dbo.sp_dp_help_database_files;

	RETURN(0);
END
--#endregion

--#region Get db name if not provided
IF @DbName IS NULL
	IF @ObjectName LIKE '#%'
		SET @DbName = 'tempdb';
	ELSE
		SET @DbName = DB_NAME();
--#endregion

--#region Execute in another database context
IF @DbName != DB_NAME()
BEGIN
	SET @Query = '
EXEC {DbName}.dbo.sp_dp_help
	 @ObjectNameIn	= @ObjectNameIn
	,@Mode			= @Mode;';

	SET @Params = '
@ObjectNameIn	NVARCHAR(1035)
,@Mode			INT';

	SET @Query = REPLACE(@Query, '{DbName}', QUOTENAME(@DbName));

	EXEC sp_executesql
		@Query			= @Query
		,@Params		= @Params
		,@ObjectNameIn	= @ObjectNameIn
		,@Mode			= @Mode;

	RETURN(0);
END
--#endregion

--#region Get object id
EXEC dbo.sp_dp_help_object_id
	 @ObjectName		= @ObjectName		OUTPUT
	,@SchemaName		= @SchemaName		OUTPUT
	,@ObjectId			= @ObjectId			OUTPUT
	,@ObjectType		= @ObjectType		OUTPUT
	,@ObjectTypeDesc	= @ObjectTypeDesc	OUTPUT
	,@ObjectNameFull	= @ObjectNameFull	OUTPUT
--#endregion

--#region Get dependencies up
IF @Mode = 2
BEGIN
	SET @grid_no += 1;
	SET @grid_msg = 'Grid ' + CONVERT(VARCHAR(10), @grid_no) + ': Dependencies of object or LIKE string.';
	RAISERROR(@grid_msg, 10, 1) WITH NOWAIT;

	EXEC dbo.sp_dp_help_object_dependencies_up
		 @ObjectId			= @ObjectId		
		,@SchemaName		= @SchemaName	
		,@ObjectName		= @ObjectName	
		,@ObjectNameFull	= @ObjectNameFull	
		,@ObjectType		= @ObjectType	
		,@ObjectTypeDesc	= @ObjectTypeDesc
		,@DbName			= @DbName;

	RETURN(0);
END
--#endregion

--#region If object_id is still null - give up
IF @ObjectId IS NULL
BEGIN
	RAISERROR(15009, -1, -1, @ObjectNameIn, @DbName);
	RETURN(1);
END
--#endregion

--#region Get DATABASE info
IF @ObjectType = 'DATABASE'
BEGIN
	SET @grid_no += 1;
	SET @grid_msg = 'Grid ' + CONVERT(VARCHAR(10), @grid_no) + ': Database info.';
	RAISERROR(@grid_msg, 10, 1) WITH NOWAIT;

	EXEC dbo.sp_dp_help_database
		@ObjectId = @ObjectId;

	IF @Mode = 0
	BEGIN
		SET @grid_no += 1;
		SET @grid_msg = 'Grid ' + CONVERT(VARCHAR(10), @grid_no) + ': Database files info.';
		RAISERROR(@grid_msg, 10, 1) WITH NOWAIT;

		EXEC dbo.sp_dp_help_database_files;
	END

	RETURN(0);
END
--#endregion

--#region Get SERVER PRINCIPAL info
IF @ObjectType = 'SERVER PRINCIPAL'
BEGIN
	SET @grid_no += 1;
	SET @grid_msg = 'Grid ' + CONVERT(VARCHAR(10), @grid_no) + ': Server principal info.';
	RAISERROR(@grid_msg, 10, 1) WITH NOWAIT;
	SET @grid_no += 1;
	SET @grid_msg = 'Grid ' + CONVERT(VARCHAR(10), @grid_no) + ': Server role and member info.';
	RAISERROR(@grid_msg, 10, 1) WITH NOWAIT;
	
	EXEC dbo.sp_dp_help_server_principal
		@ObjectId = @ObjectId;

	--SET @grid_no += 1;
	--SET @grid_msg = 'Grid ' + CONVERT(VARCHAR(10), @grid_no) + ': Object permisions info.';
	--RAISERROR(@grid_msg, 10, 1) WITH NOWAIT;

	--EXEC dbo.sp_dp_help_object_permissons
	--	@ObjectId = @ObjectId;

	RETURN(0);
END
--#endregion

--#region Get DATABASE PRINCIPAL info
IF @ObjectType = 'DATABASE PRINCIPAL'
BEGIN
	SET @grid_no += 1;
	SET @grid_msg = 'Grid ' + CONVERT(VARCHAR(10), @grid_no) + ': Database principal info.';
	RAISERROR(@grid_msg, 10, 1) WITH NOWAIT;
	SET @grid_no += 1;
	SET @grid_msg = 'Grid ' + CONVERT(VARCHAR(10), @grid_no) + ': Database role and member info.';
	RAISERROR(@grid_msg, 10, 1) WITH NOWAIT;
	
	EXEC dbo.sp_dp_help_database_principal
		@ObjectId = @ObjectId;

	SET @grid_no += 1;
	SET @grid_msg = 'Grid ' + CONVERT(VARCHAR(10), @grid_no) + ': Object permisions info.';
	RAISERROR(@grid_msg, 10, 1) WITH NOWAIT;

	EXEC dbo.sp_dp_help_object_permissons
		@ObjectId = @ObjectId;

	RETURN(0);
END
--#endregion

--#region Get SCHEMA info
IF @ObjectType = 'SCHEMA'
BEGIN
	SET @grid_no += 1;
	SET @grid_msg = 'Grid ' + CONVERT(VARCHAR(10), @grid_no) + ': Schema info.';
	RAISERROR(@grid_msg, 10, 1) WITH NOWAIT;

	EXEC dbo.sp_dp_help_schema
		@ObjectId = @ObjectId;

	RETURN(0);
END
--#endregion

--#region Get ASSEMBLY info
IF @ObjectType = 'ASSEMBLY'
BEGIN
	SET @grid_no += 1;
	SET @grid_msg = 'Grid ' + CONVERT(VARCHAR(10), @grid_no) + ': Assembly info.';
	RAISERROR(@grid_msg, 10, 1) WITH NOWAIT;

	EXEC dbo.sp_dp_help_assembly
		@ObjectId = @ObjectId;

	RETURN(0);
END
--#endregion

--#region Get TYPE info
IF @ObjectType = 'TYPE'
BEGIN
	SET @grid_no += 1;
	SET @grid_msg = 'Grid ' + CONVERT(VARCHAR(10), @grid_no) + ': User type info.';
	RAISERROR(@grid_msg, 10, 1) WITH NOWAIT;

	EXEC dbo.sp_dp_help_type
		@ObjectId = @ObjectId;
	
	IF EXISTS (
	   	SELECT 1
		FROM sys.table_types
		WHERE user_type_id = @ObjectId)
			AND @Mode = 0
		SELECT
			@ColumnsObjectId = [type_table_object_id]
		FROM sys.table_types
		WHERE [user_type_id] = @ObjectId;
	ELSE
		RETURN(0);
END
--#endregion

--#region Get DATABASE TRIGGER info
IF @ObjectType = 'DDL TRIGGER'
BEGIN
	SET @grid_no += 1;
	SET @grid_msg = 'Grid ' + CONVERT(VARCHAR(10), @grid_no) + ': DDL Trigger info.';
	RAISERROR(@grid_msg, 10, 1) WITH NOWAIT;

	EXEC dbo.sp_dp_help_database_trigger
		@ObjectId		= @ObjectId
		,@SchemaName	= @SchemaName;

	RETURN(0);
END
--#endregion

--#region Get XML SCHEMA COLLECTION info
IF @ObjectType = 'XML SCHEMA COLLECTION'
BEGIN
	SET @grid_no += 1;
	SET @grid_msg = 'Grid ' + CONVERT(VARCHAR(10), @grid_no) + ': XML Schema Collection info.';
	RAISERROR(@grid_msg, 10, 1) WITH NOWAIT;

	EXEC dbo.sp_dp_help_xml_schema_collection
		@ObjectId		= @ObjectId;

	RETURN(0);
END
--#endregion

--#region Get base object name for SYNONYM
IF @ObjectType = 'SN'
BEGIN
	SELECT
		@BaseObjectName = base_object_name
	FROM sys.synonyms
	WHERE object_id = @ObjectId;
END
--#endregion

IF @ColumnsObjectId IS NULL
	SET @ColumnsObjectId = @ObjectId;

--#region Get standard object info
IF EXISTS (
   		SELECT 1
   		FROM sys.all_objects
		WHERE [object_id] = @ObjectId
	)
BEGIN	
	SET @grid_no += 1;
	SET @grid_msg = 'Grid ' + CONVERT(VARCHAR(10), @grid_no) + ': Object info.';
	RAISERROR(@grid_msg, 10, 1) WITH NOWAIT;

	EXEC dbo.sp_dp_help_object
		 @ObjectId			= @ObjectId		
		,@ObjectType		= @ObjectType	
		,@BaseObjectName	= @BaseObjectName;

	IF @Mode = 1
		RETURN (0);
END
--#endregion

--#region Get Base Object info for SYNONYM
IF @ObjectType = 'SN'
	AND @Mode = 0
BEGIN
	SELECT
		 @ServerName	= PARSENAME(@BaseObjectName, 4)
		,@DbName		= ISNULL(PARSENAME(@BaseObjectName, 3), @DbName);

	IF @ServerName IS NOT NULL
	BEGIN		
		RAISERROR('Server level is not supported.', 10, 1);
		RETURN(1);
	END

	SET @Query = '
EXEC {DbName}.dbo.sp_dp_help
	 @ObjectNameIn	= @ObjectNameIn;';

	SET @Params = '
@ObjectNameIn	NVARCHAR(1035)';

	SET @Query = REPLACE(@Query, '{DbName}', QUOTENAME(@DbName));

	EXEC sp_executesql
		@Query			= @Query
		,@Params		= @Params
		,@ObjectNameIn	= @BaseObjectName;

	RETURN(0);
END
--#endregion

--#region Get params info
IF EXISTS (
	SELECT 1
	FROM sys.all_parameters
	WHERE [object_id] = @ObjectId)
	AND @Mode = 0
BEGIN
	SET @grid_no += 1;
	SET @grid_msg = 'Grid ' + CONVERT(VARCHAR(10), @grid_no) + ': Object parameters info.';
	RAISERROR(@grid_msg, 10, 1) WITH NOWAIT;

	EXEC dbo.sp_dp_help_object_parameters
		@ObjectId		= @ObjectId
		,@tab_len		= @tab_len;
END
--#endregion

--#region Get columns info
IF EXISTS (
	SELECT 1
	FROM sys.all_columns
	WHERE [object_id] = @ColumnsObjectId)
	AND @Mode = 0
BEGIN
	SET @grid_no += 1;
	SET @grid_msg = 'Grid ' + CONVERT(VARCHAR(10), @grid_no) + ': Object columns info.';
	RAISERROR(@grid_msg, 10, 1) WITH NOWAIT;

	EXEC dbo.sp_dp_help_object_columns
		@ObjectId		= @ObjectId
		,@tab_len		= @tab_len;
END
--#endregion

--#region Get index info
IF EXISTS (
	SELECT 1
	FROM sys.indexes i
	WHERE [object_id] = @ObjectId
	)
BEGIN
	SET @grid_no += 1;
	SET @grid_msg = 'Grid ' + CONVERT(VARCHAR(10), @grid_no) + ': Object indexes info.';
	RAISERROR(@grid_msg, 10, 1) WITH NOWAIT;

	EXEC dbo.sp_dp_help_object_indexes
		@ObjectId		= @ObjectId
		,@SchemaName	= @SchemaName
		,@ObjectName	= @ObjectName;		
END
--#endregion

--#region Get trigger info
IF EXISTS (
   	SELECT 1
	FROM sys.triggers
	WHERE parent_id = @ObjectId
)
BEGIN
	SET @grid_no += 1;
	SET @grid_msg = 'Grid ' + CONVERT(VARCHAR(10), @grid_no) + ': Object triggers info.';
	RAISERROR(@grid_msg, 10, 1) WITH NOWAIT;

	EXEC dbo.sp_dp_help_object_triggers
		@ObjectId		= @ObjectId;
END
--#endregion

--#region Get constraint info
IF EXISTS (
	SELECT 1
	FROM sys.all_objects
	WHERE parent_object_id = @ObjectId
		AND type NOT IN ('TR', 'IT'))
BEGIN
	SET @grid_no += 1;
	SET @grid_msg = 'Grid ' + CONVERT(VARCHAR(10), @grid_no) + ': Object constraints info.';
	RAISERROR(@grid_msg, 10, 1) WITH NOWAIT;

	EXEC dbo.sp_dp_help_object_constraints
		@ObjectId = @ObjectId;
END
--#endregion

--#region Get referencing objects
IF EXISTS (
	SELECT 1
	FROM sys.foreign_keys
	WHERE referenced_object_id = @ObjectId)
BEGIN
	SET @grid_no += 1;
	SET @grid_msg = 'Grid ' + CONVERT(VARCHAR(10), @grid_no) + ': Object referenced by foreign keys info.';
	RAISERROR(@grid_msg, 10, 1) WITH NOWAIT;

	EXEC dbo.sp_dp_help_object_referenced_by_fk
		@ObjectId = @ObjectId;
END
--#endregion

--#region Get permisions
IF EXISTS (
	SELECT 1
	FROM sys.database_permissions p
		JOIN sys.database_principals g
			ON g.[principal_id] = p.[grantee_principal_id]
		JOIN sys.all_objects o
			ON o.[object_id] = p.[major_id]
	WHERE p.[class] >= 1
		AND p.[major_id] = @ObjectId)
BEGIN
	SET @grid_no += 1;
	SET @grid_msg = 'Grid ' + CONVERT(VARCHAR(10), @grid_no) + ': Object permisions info.';
	RAISERROR(@grid_msg, 10, 1) WITH NOWAIT;

	EXEC dbo.sp_dp_help_object_permissons
		@ObjectId = @ObjectId;
END
--#endregion
GO

