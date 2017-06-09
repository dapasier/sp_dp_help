CREATE PROC dbo.sp_dp_help_database_principal
	@ObjectId	INT
AS
	SELECT
		 [PrincipalName]	= p.[name]
		,[Type]				= p.[type_desc]
		,[DefaultSchema]	= p.[default_schema_name]
		,[IsFixedRole]		= p.[is_fixed_role]
		,[CreateDate]		= p.[create_date]
		,[ModifyDate]		= p.[modify_date]
		,[SID]				= p.[sid]
	FROM sys.database_principals p
	WHERE [principal_id] = @ObjectId
	ORDER BY [PrincipalName];

	IF EXISTS (
	   	SELECT 1
	   	FROM sys.database_principals p
			JOIN sys.database_role_members rm
				ON rm.[role_principal_id] = p.[principal_id]
		WHERE [principal_id] = @ObjectId
	)
	BEGIN
		SELECT	
			[RoleName]		= p.[name]
			,[MemberName]	= m.[name]
		FROM sys.database_principals p
			JOIN sys.database_role_members rm
				ON rm.[role_principal_id] = p.[principal_id]
			JOIN sys.database_principals m
				ON m.[principal_id] = rm.[member_principal_id]
		WHERE p.[principal_id] = @ObjectId		
		ORDER BY [RoleName], [MemberName];
	END
	ELSE
	IF EXISTS (
	   	SELECT 1
	   	FROM sys.database_principals p
			JOIN sys.database_role_members rm
				ON rm.member_principal_id = p.principal_id
		WHERE principal_id = @ObjectId
	)
	BEGIN
		SELECT	
			[RoleName]		= p.[name]
			,[MemberName]	= m.[name]
		FROM sys.database_principals p
			JOIN sys.database_role_members rm
				ON rm.[role_principal_id] = p.[principal_id]
			JOIN sys.database_principals m
				ON m.[principal_id] = rm.[member_principal_id]
		WHERE m.[principal_id] = @ObjectId	
		ORDER BY [RoleName], [MemberName];
	END
	ELSE
		SELECT TOP(0)
			[RoleName]		= ''
			,[MemberName]	= ''
GO
