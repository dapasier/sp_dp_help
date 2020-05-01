CREATE PROCEDURE [dbo].[sp_dp_help_print_grid_info]
	@GridMsg	varchar(1000)	= ''
AS
DECLARE
	@ContexInfo	binary(5)
	,@PrintHelp	bit
	,@GridNo	int;

SET @PrintHelp	= ISNULL(TRY_CONVERT(bit, SUBSTRING(CONTEXT_INFO(), 1, 1)), 1);

IF @PrintHelp = 1
BEGIN
	SET @GridNo		= ISNULL(TRY_CONVERT(int, SUBSTRING(CONTEXT_INFO(), 2, 4)), 0);
	SET @GridNo		+= 1;

	SET @ContexInfo	= CONVERT(binary(1), @PrintHelp) + CONVERT(binary(4), @GridNo);
	SET CONTEXT_INFO @ContexInfo;

	SET @GridMsg = CONCAT('Grid ', @GridNo, ': ', @GridMsg);
	RAISERROR(@GridMsg, 10, 1) WITH NOWAIT;
END

RETURN (0)
GO
