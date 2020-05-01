CREATE PROC dbo.sp_dp_help_database_files
AS
DECLARE
	@DatabaseId	INT = DB_ID();

EXEC [dbo].[sp_dp_help_print_grid_info]
	@GridMsg	= 'Database files';

SELECT
	[LogicalFileName]	= s.[name]
	,[FileName]			= s.[physical_name]
	,[Type]				= s.[type_desc]
	,[FileGroup]		= fg.name
	,[Size (MB)]		= master.dbo.FormatNumeric(s.[size] * 8 / 1024., 2, default, default, default, 12)
	,[UsedSpace (MB)]	= master.dbo.FormatNumeric(FILEPROPERTY(s.[name], 'SpaceUsed') * 8 / 1024., 2, default, default, default, 12)
	,[UsedSpace (%)]	= master.dbo.FormatNumeric(CAST(FILEPROPERTY(s.[name], 'SpaceUsed') AS float) / s.[size] * 100, 2, default, default, default, 12)
	,[Growth]			= CASE s.[is_percent_growth]
							WHEN 1 THEN CONVERT(varchar(20), s.[growth]) + ' %'
							ELSE CONVERT(varchar(20), s.[growth] * 8 / 1024) + ' MB'
						END
	,[FreeSpace (MB)]	= master.dbo.FormatNumeric(f.[available_bytes] / 1024. / 1024., 2, default, default, default, 12)	
	,[FreeSpace (%)]	= master.dbo.FormatNumeric(f.[available_bytes] / CONVERT(decimal(19, 0), f.[total_bytes]) * 100, 2, default, default, default, 12)
	,[TotalSpace (MB)]	= master.dbo.FormatNumeric(f.[total_bytes] / 1024. / 1024., 2, default, default, default, 12)
	,[State]			= s.[state_desc]
FROM sys.database_files s
	CROSS APPLY sys.dm_os_volume_stats(@DatabaseId, s.[file_id]) f
	LEFT JOIN sys.filegroups fg
		ON fg.data_space_id = s.data_space_id;
GO
