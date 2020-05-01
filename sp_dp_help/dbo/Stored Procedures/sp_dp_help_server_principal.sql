CREATE PROC dbo.sp_dp_help_server_principal
	@ObjectId	INT
AS
EXEC [dbo].[sp_dp_help_print_grid_info]
	@GridMsg	= 'Server principal';

SELECT
	[PrincipalName]		= p.[name]
	,[Type]				= p.[type_desc]
	,[IsFixedRole]		= p.[is_fixed_role]
	,[CreateDate]		= p.[create_date]
	,[ModifyDate]		= p.[modify_date]
	,[SID]				= p.[sid]
FROM sys.server_principals p
WHERE [principal_id] = @ObjectId
ORDER BY [PrincipalName];

EXEC [dbo].[sp_dp_help_print_grid_info]
	@GridMsg	= 'Server principal role and member';

SELECT	
	[RoleName]		= p.[name]
	,[MemberName]	= m.[name]
FROM sys.server_principals p
	JOIN sys.server_role_members rm
		ON rm.[role_principal_id] = p.[principal_id]
	JOIN sys.server_principals m
		ON m.[principal_id] = rm.[member_principal_id]
WHERE p.[principal_id] = @ObjectId
	
UNION ALL

SELECT	
	[RoleName]		= p.[name]
	,[MemberName]	= m.[name]
FROM sys.server_principals p
	JOIN sys.server_role_members rm
		ON rm.[role_principal_id] = p.[principal_id]
	JOIN sys.server_principals m
		ON m.[principal_id] = rm.[member_principal_id]
WHERE m.[principal_id] = @ObjectId	
ORDER BY [RoleName], [MemberName];

EXEC [dbo].[sp_dp_help_print_grid_info]
	@GridMsg	= 'Server principal permissions';

SELECT
	[Class]			= p.[class_desc]
	,[ObjectName]	= e.[name]
	,[Permission]	= p.[permission_name]
	,[State]		= p.[state_desc]
	,[Script]		= p.[state_desc]
					+ ' '
					+ p.[permission_name]
					+ ISNULL(' ON ' + p.[class_desc] + '::' + QUOTENAME(e.[name]), '')
					+ ' TO ' + QUOTENAME(g.[name])
					COLLATE database_default
FROM sys.server_permissions p
	JOIN sys.server_principals g
		ON g.[principal_id] = p.[grantee_principal_id]
	LEFT JOIN sys.endpoints e
		ON p.[class] = 105
		AND e.[endpoint_id] = p.[major_id]
WHERE p.[grantee_principal_id] = @ObjectId;
GO
