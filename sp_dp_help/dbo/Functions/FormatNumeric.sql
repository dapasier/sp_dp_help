CREATE FUNCTION dbo.FormatNumeric (
	 @Input			[decimal](38, 12)
	,@FractionDig	[int]			= -1
	,@FractionSep	[nvarchar](5)	= '.'
	,@ThousandSep	[nvarchar](5)	= ' '
	,@Currency		[nvarchar](5)	= ''
	,@FormatLen		[int]			= 0
)
RETURNS VARCHAR(100)
AS
BEGIN

DECLARE
	 @Output			[nvarchar](100)
	,@OutputLen			[int]
	,@ConstFractionLen	[int]
	,@FractionLen		[int]
	,@FractionPart		[nvarchar](50)
	,@ThousandLen		[int]
	,@ThousandPart		[nvarchar](50)
	,@FormatLenAdd		[int]
	,@i					[int];

-- constant
SET @ConstFractionLen = 12;

IF @FractionSep IS NULL
	SET @FractionSep = '.';

IF @ThousandSep IS NULL
	SET @FractionSep = ' ';

IF @Currency IS NULL
	SET @Currency = '';

IF @FractionDig = 0
BEGIN
	SET @FractionPart = '';
	SET @FractionSep = '';
END
ELSE
BEGIN
	SET @FractionPart = RIGHT(CONVERT([nvarchar](50), @Input % 10), @ConstFractionLen);

	-- auto fraction dig
	IF @FractionDig = -1
	BEGIN
		SET @i = 0;

		WHILE @FractionPart > ''
			AND @i <= @ConstFractionLen
		BEGIN
			IF RIGHT(@FractionPart, 1) = '0'
			BEGIN
				SET @FractionPart = SUBSTRING(@FractionPart, 1, LEN(@FractionPart) - 1);
				SET @i = @i + 1;
			END
			ELSE
				BREAK;
		END

		SET @FractionLen = @ConstFractionLen - @i;
	END
	ELSE
	BEGIN
		SET @FractionLen = @FractionDig;
		SET @FractionPart = LEFT(@FractionPart, @FractionLen);
	END
	
	IF @FractionLen = 0
	BEGIN
		SET @FractionSep = '';
	END
	ELSE
	BEGIN
		-- add thousand sep
		SET @i = 3;

		WHILE @FractionLen >= @i + 1
		BEGIN
			SET @FractionPart = STUFF(@FractionPart, @i + @i / 3 , 0, @ThousandSep);
			
			SET @i = @i + 3;
		END
	END
END

SET @ThousandPart	= CONVERT([nvarchar](50), @Input);
SET @ThousandLen	= CHARINDEX('.', @ThousandPart) - 1;
SET @ThousandPart	= LEFT(@ThousandPart, @ThousandLen);

SET @i = 3;

WHILE @ThousandLen > @i
BEGIN
	SET @ThousandPart = STUFF(@ThousandPart, @ThousandLen - @i + 1, 0, @ThousandSep);
	SET @i = @i + 3;
END

SET @Output		= @ThousandPart + @FractionSep + @FractionPart + @Currency;
SET @OutputLen	= LEN(@Output);

IF @FormatLen > 0
BEGIN
	SET @FormatLenAdd = @OutputLen + (@FormatLen - @OutputLen) * 2 + ((@ThousandLen -1)/ 3); -- for Microsoft Sans Serif font
	--SET @FormatLenAdd = @FormatLen; -- for constant len font

	IF @FormatLenAdd > @OutputLen
	BEGIN
		SET @Output = RIGHT(REPLICATE(' ', @FormatLenAdd) + @Output, @FormatLenAdd);
	END
END

RETURN @Output;
END
GO
--;WITH n AS (
--	SELECT [a] = '10 219.01'		,[i] = (5-1)/3/*1*/ UNION ALL
--	SELECT [a] = '9 172.23'			,[i] = (4-1)/3/*1*/ UNION ALL
--	SELECT [a] = '983.28' 			,[i] = (3-1)/3/*0*/ UNION ALL
--	SELECT [a] = '3 333 333.33'		,[i] = (7-1)/3/*2*/ UNION ALL
--	SELECT [a] = '444 444.44' 		,[i] = (6-1)/3/*1*/ UNION ALL
--	SELECT [a] = '55 555.55' 		,[i] = (5-1)/3/*1*/ UNION ALL
--	SELECT [a] = '6 666.66' 		,[i] = (4-1)/3/*1*/ UNION ALL
--	SELECT [a] = '777.77' 			,[i] = (3-1)/3/*0*/ UNION ALL
--	SELECT [a] = '88.88' 			,[i] = (2-1)/3/*0*/ UNION ALL
--	SELECT [a] = '9.99'				,[i] = (1-1)/3/*0*/ )

--SELECT
--	[a]
--	,RIGHT(REPLICATE(' ', 16) + [a], 16)
--	,RIGHT(REPLICATE(' ', LEN([a]) + (16 - LEN([a])) * 2 + [i]) + [a], LEN([a]) + (16 - LEN([a])) * 2 + [i])
--	,[LEN(a)] = LEN([a])
--	,[i]
--	,dbo.FormatNumeric(CONVERT(decimal(19, 2), REPLACE([a], ' ', '')), default, default, default, default, 16)
--FROM n

