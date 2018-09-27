CREATE PROC dbo.sp_dp_help_database
	@ObjectId	INT = NULL
AS
	SELECT
		 [DatabaseName]			= d.[name]
		,[Owner]				= ISNULL(p.[name], '<EXTERNAL>')
		,[CreateDate]			= d.[create_date]
		,[CompatibilityLevel]	= d.[compatibility_level]
		,[State]				= d.[state_desc] +
									CASE d.[is_read_only]
										WHEN 1 THEN ', READ ONLY'
										ELSE ''
									END +									
									CASE d.[is_in_standby]
										WHEN 1 THEN ', STANDBY'
										ELSE ''
									END
		,[UserAccess]			= d.[user_access_desc]
		,[RecoveryModel]		= d.[recovery_model_desc]
		,[Options]				= (
									SELECT
										[is_auto_close_on]					= NULLIF(d.[is_auto_close_on], 0)
										,[is_auto_shrink_on]				= NULLIF(d.[is_auto_shrink_on], 0)
										,[is_cleanly_shutdown]				= NULLIF(d.[is_cleanly_shutdown], 0)
										,[is_supplemental_logging_enabled]	= NULLIF(d.[is_supplemental_logging_enabled], 0)
										,[snapshot_isolation_state]			= d.[snapshot_isolation_state_desc]										
										,[page_verify_option]				= d.[page_verify_option_desc]
										,[is_auto_create_stats_on]			= d.[is_auto_create_stats_on]
										,[is_auto_update_stats_on]			= d.[is_auto_update_stats_on]
										,[is_auto_update_stats_async_on]	= d.[is_auto_update_stats_async_on]
										,[is_ansi_null_default_on]			= NULLIF(d.[is_ansi_null_default_on], 0)
										,[is_ansi_nulls_on]					= NULLIF(d.[is_ansi_nulls_on], 0)
										,[is_ansi_padding_on]				= NULLIF(d.[is_ansi_padding_on], 0)
										,[is_ansi_warnings_on]				= NULLIF(d.[is_ansi_warnings_on], 0)
										,[is_arithabort_on]					= NULLIF(d.[is_arithabort_on], 0)
										,[is_concat_null_yields_null_on]	= NULLIF(d.[is_concat_null_yields_null_on], 0)
										,[is_numeric_roundabort_on]			= NULLIF(d.[is_numeric_roundabort_on], 0)
										,[is_quoted_identifier_on]			= NULLIF(d.[is_quoted_identifier_on], 0)
										,[is_recursive_triggers_on]			= NULLIF(d.[is_recursive_triggers_on], 0)
										,[is_local_cursor_default]			= NULLIF(d.[is_local_cursor_default], 0)
										,[is_fulltext_enabled]				= NULLIF(d.[is_fulltext_enabled], 0)
										,[is_trustworthy_on]				= NULLIF(d.[is_trustworthy_on], 0)
										,[is_db_chaining_on]				= NULLIF(d.[is_db_chaining_on], 0)
										,[is_parameterization_forced]		= NULLIF(d.[is_parameterization_forced], 0)
										,[is_master_key_encrypted_by_server]= NULLIF(d.[is_master_key_encrypted_by_server], 0)
										,[is_published]						= NULLIF(d.[is_published], 0)
										,[is_subscribed]					= NULLIF(d.[is_subscribed], 0)
										,[is_merge_published]				= NULLIF(d.[is_merge_published], 0)
										,[is_distributor]					= NULLIF(d.[is_distributor], 0)
										,[is_sync_with_backup]				= NULLIF(d.[is_sync_with_backup], 0)
										,[is_broker_enabled]				= NULLIF(d.[is_broker_enabled], 0)
										,[is_date_correlation_on]			= NULLIF(d.[is_date_correlation_on], 0)
										,[is_cdc_enabled]					= NULLIF(d.[is_cdc_enabled], 0)
										,[is_encrypted]						= NULLIF(d.[is_encrypted], 0)
										,[is_honor_broker_priority_on]		= NULLIF(d.[is_honor_broker_priority_on], 0)
									FOR XML PATH(''), ROOT('options'), TYPE
								  )
		,[Collation]			= d.[collation_name]
		,[UserAcces]			= d.[user_access_desc]
		,[LogReuseWait]			= d.[log_reuse_wait_desc]
	FROM sys.databases d
		LEFT JOIN sys.database_principals p
			ON d.[owner_sid] = p.[sid]
	WHERE d.[database_id] = ISNULL(@ObjectId, d.[database_id])
	ORDER BY [DatabaseName];
GO
