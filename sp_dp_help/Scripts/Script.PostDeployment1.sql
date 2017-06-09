/*
Post-Deployment Script Template							
--------------------------------------------------------------------------------------
 This file contains SQL statements that will be appended to the build script.		
 Use SQLCMD syntax to include a file in the post-deployment script.			
 Example:      :r .\myfile.sql								
 Use SQLCMD syntax to reference a variable in the post-deployment script.		
 Example:      :setvar TableName MyTable							
               SELECT * FROM [$(TableName)]					
--------------------------------------------------------------------------------------
*/
EXEC sys.sp_MS_marksystemobject 'sp_dp_help'
GO
EXEC sys.sp_MS_marksystemobject 'sp_dp_help_assembly'
GO
EXEC sys.sp_MS_marksystemobject 'sp_dp_help_database'
GO
EXEC sys.sp_MS_marksystemobject 'sp_dp_help_database_files'
GO
EXEC sys.sp_MS_marksystemobject 'sp_dp_help_database_principal'
GO
EXEC sys.sp_MS_marksystemobject 'sp_dp_help_database_trigger'
GO
EXEC sys.sp_MS_marksystemobject 'sp_dp_help_object'
GO
EXEC sys.sp_MS_marksystemobject 'sp_dp_help_object_columns'
GO
EXEC sys.sp_MS_marksystemobject 'sp_dp_help_object_constraints'
GO
EXEC sys.sp_MS_marksystemobject 'sp_dp_help_object_dependencies_up'
GO
EXEC sys.sp_MS_marksystemobject 'sp_dp_help_object_id'
GO
EXEC sys.sp_MS_marksystemobject 'sp_dp_help_object_indexes'
GO
EXEC sys.sp_MS_marksystemobject 'sp_dp_help_object_parameters'
GO
EXEC sys.sp_MS_marksystemobject 'sp_dp_help_object_permissons'
GO
EXEC sys.sp_MS_marksystemobject 'sp_dp_help_object_referenced_by_fk'
GO
EXEC sys.sp_MS_marksystemobject 'sp_dp_help_object_space_used'
GO
EXEC sys.sp_MS_marksystemobject 'sp_dp_help_object_triggers'
GO
EXEC sys.sp_MS_marksystemobject 'sp_dp_help_schema'
GO
EXEC sys.sp_MS_marksystemobject 'sp_dp_help_server_principal'
GO
EXEC sys.sp_MS_marksystemobject 'sp_dp_help_type'
GO
EXEC sys.sp_MS_marksystemobject 'sp_dp_help_xml_schema_collection'
GO
