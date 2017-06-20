CREATE PROCEDURE [dbo].[sp_dp_help_print_grid_info]
	@GridNo		int = 0
	,@GridMsg	varchar(1000) = ''
AS
	SET @GridMsg = 'Grid ' + CONVERT(VARCHAR(10), @GridNo) + ': ' + @GridMsg;
	RAISERROR(@GridMsg, 10, 1) WITH NOWAIT;

	RETURN 0
GO
