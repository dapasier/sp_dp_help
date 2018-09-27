CREATE PROC dbo.sp_dp_help_object_permissons
	@ObjectId	INT
AS
	;WITH 
	role_member AS (
		SELECT
			[role_principal_id]	= r.[principal_id]
			,[role_name]		= r.[name]
			,[role_members]		= STUFF(
									(SELECT ', ' + m.[name]
									 FROM sys.database_role_members rm								
										JOIN sys.database_principals m
										ON m.principal_id = rm.member_principal_id
									WHERE rm.role_principal_id = r.principal_id
									ORDER BY m.name
									FOR XML PATH(''), TYPE).value('.', 'nvarchar(max)')
									,1
									,2
									,''
								)
			,[owning_principal]	= o.[name]
		FROM sys.database_principals r
			JOIN sys.database_principals o
				ON o.principal_id = r.owning_principal_id
		--WHERE r.type = 'R'
	)
	,member_role AS (
		SELECT
			[member_principal_id]	= m.[principal_id]
			,[member_name]			= m.[name]
			,[member_roles]			= STUFF(
										(SELECT ', ' + r.[name]
										 FROM sys.database_role_members rm								
											JOIN sys.database_principals r
											ON r.principal_id = rm.role_principal_id
										WHERE rm.member_principal_id = m.principal_id
										ORDER BY r.[name]
										FOR XML PATH(''), TYPE).value('.', 'nvarchar(max)')
										,1
										,2
										,''
									)
		FROM sys.database_principals m
		--WHERE m.[type] != 'R'
	)
	SELECT
		[ObjectName]		= QUOTENAME(s.[name]) + '.' + QUOTENAME(o.[name])
		,[Column]			= c.[name]	
		,[Grantee]			= g.[name]
		,[GranteeType]		= g.[type_desc]
		,[Permission]		= p.[permission_name]
		,[State]			= p.[state_desc]
		,[GranteeRoles]		= mr.[member_roles]
		,[GranteeMembers]	= rm.[role_members]
		,[Script]			= p.[state_desc]
							+ ' '
							+ p.[permission_name]
							+ ISNULL(' ON ' + QUOTENAME(s.[name]) + '.' + QUOTENAME(o.[name]), '')
							+ ' TO ' + QUOTENAME(g.[name])
							+ ISNULL(' AS ' + QUOTENAME(rm.[owning_principal]), '')
							COLLATE database_default
	FROM sys.database_permissions p
		JOIN sys.database_principals g
			ON g.[principal_id] = p.[grantee_principal_id]
		LEFT JOIN sys.all_objects o
			ON o.[object_id] = p.[major_id]
		LEFT JOIN sys.schemas s
			ON s.schema_id = o.schema_id
		LEFT JOIN role_member rm
			ON g.[principal_id] = rm.[role_principal_id]
		LEFT JOIN member_role mr
			ON p.[grantee_principal_id] = mr.[member_principal_id]
		LEFT JOIN sys.all_columns c
			ON c.[object_id] = o.[object_id]
			AND c.[column_id] = p.[minor_id]
	WHERE (
		p.[class] >= 1
		AND p.[major_id] = @ObjectId
		)
		OR p.[grantee_principal_id] = @ObjectId
	ORDER BY [ObjectName], [Column], [Grantee], [Permission], [State];
GO
