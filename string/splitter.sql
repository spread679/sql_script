USE [your db]
GO

/**
 * author:		spread
 * description:	function tu split a string that has a delimiter and a qualifier
 *
 */

-- ##############################################################################
-- DESCRIPTION: split a string and return a table
-- PARAMETERS:
--	@string - the string to split
--	@delimiter - the delimiter
-- RETURNS: a table with two column, the "position" and the different values
--
CREATE FUNCTION a3f_StringSplit
	(@string VARCHAR(MAX),
	 @delimiter VARCHAR(10))
RETURNS @returnTB TABLE (
	ID INT UNIQUE,
	value VARCHAR(MAX)
)
BEGIN
	-- input controll
	IF (ISNULL(@string, '') = '' OR ISNULL(@delimiter, '') = '') RETURN;

	-- variables
	DECLARE @i INT = 1
	DECLARE @len INT = LEN(@string)
	DECLARE @character AS CHAR(1)
	DECLARE @value AS VARCHAR(MAX)
	DECLARE @tempTable TABLE (
		ID INT IDENTITY(1,1),
		value VARCHAR(MAX)
	)

	WHILE (@i <= @len AND CHARINDEX(@delimiter, @string) > 0)
	BEGIN
		SET @character = SUBSTRING(@string, @i, 1)

		-- control if is the splitter character
		IF @character = @delimiter
		BEGIN
			SET @value = SUBSTRING(@string, 1, @i - 1)

			-- save the splitted string
			INSERT INTO @tempTable (value)
			VALUES (@value)

			-- reduce the input string
			SET @len = @len - @i
			SET @string = SUBSTRING(@string, @i + 1, @len)
			SET @i = 1
		END
		ELSE
		BEGIN
			SET @i = @i + 1
		END
	END

	-- insert the last string
	INSERT INTO @tempTable (value)
	VALUES (@string)

	INSERT INTO @returnTB
	SELECT ID, value
	FROM @tempTable

	RETURN;
END
GO

SELECT *
FROM dbo.a3f_StringSplit('T;DTCL;EVCOSR;1234;20200326;20200326;;', ';')
GO

-- ##############################################################################
-- DESCRIPTION: replace the delimiter with a new string
-- PARAMETERS:
--	@string - the string to control
--	@delimiter - the delimiter to replace if inside a qualifier
--	@qualifier - the qualifier
-- RETURNS: the input string with the delimiter changed
--
CREATE OR ALTER FUNCTION a3f_ReplaceSplitChar
	(@string AS VARCHAR(MAX),
	 @delimiter AS VARCHAR(10),
	 @qualifier AS VARCHAR(10))
 RETURNS VARCHAR(MAX)
BEGIN
	DECLARE @i INT
	DECLARE @length INT
	DECLARE @innerDelimiter CHAR(1)
	DECLARE @char CHAR(1)
	DECLARE @output VARCHAR(MAX)
	DECLARE @new_delimiter VARCHAR(3) = '<->'

	IF (ISNULL(@string, '') = '' OR ISNULL(@delimiter, '') = '' OR ISNULL(@qualifier, '') = '')
		RETURN NULL

	SET @i = 1
	SET @length = LEN(@string)
	SET @innerDelimiter = '0'

	-- control all the characters
	WHILE @i <= @length
	BEGIN
		DECLARE @beforeChar CHAR(1)
		DECLARE @nextChar CHAR(1)

		SET @char = SUBSTRING(@string, @i, 1)
		IF (@i - 1) > 0 SET @beforeChar = SUBSTRING(@string, @i - 1, 1)
		IF (@i + 1) <= @length SET @nextChar = SUBSTRING(@string, @i + 1, 1)
		SET @i = @i + 1
		
		-- control the split char
		IF (@innerDelimiter = '0' AND @char = @delimiter)
		BEGIN
			SET @output = CONCAT(@output, @new_delimiter)
			CONTINUE
		END

		-- entry control in string delimiter
		IF (CHARINDEX('0', @innerDelimiter) = 1 AND CHARINDEX(@qualifier, @char) = 1 AND CHARINDEX(@delimiter, @beforeChar) = 1)
		BEGIN
			SET @innerDelimiter = '1'
			CONTINUE
		END

		-- exit control from delimiter
		IF (CHARINDEX('1', @innerDelimiter) = 1 AND CHARINDEX(@qualifier, @char) = 1 AND CHARINDEX(@delimiter, @nextChar) = 1)
		BEGIN
			SET @innerDelimiter = '0'
			CONTINUE
		END

		SET @output = CONCAT(@output, @char)
	END

	RETURN @output
END
GO

SELECT dbo.a3f_ReplaceSplitChar('T,DTCL,ELIWCO,11387,20200720,,,"Ciao, mondo. "Che bello, che sei""', ',', '"')
GO

-- ##############################################################################
-- DESCRIPTION: get the speciffic column from a string in csv formatted
-- PARAMETERS:
--	@string - the string to split
--	@position - the position to return
--	@delimiter - the delimiter
--	@qualifier - the qualifier
-- RETURNS: return the specific column
--
CREATE FUNCTION a3f_getColumnString
	(@string AS VARCHAR(MAX),
	 @position AS INT,
	 @delimiter AS VARCHAR(10),
	 @qualifier AS VARCHAR(10))
RETURNS VARCHAR(MAX)
BEGIN
	DECLARE @mediator VARCHAR(MAX)
	DECLARE @output VARCHAR(MAX)
	DECLARE @newSplit CHAR(1) = '¦'

	-- control the input
	IF (ISNULL(@string, '') = '' OR ISNULL(@delimiter, '') = '' OR ISNULL(@qualifier, '') = '' OR ISNULL(@position, 0) = 0)
		RETURN NULL

	-- prepare variables
	SET @output = NULL
	SET @mediator = dbo.a3f_ReplaceSplitChar(@string, @delimiter, @qualifier)
	SET @mediator = REPLACE(@mediator, @newSplit, '0x00a6')
	SET @mediator = REPLACE(@mediator, '<->', @newSplit)
	
	-- get the column value
	SELECT @output = value
	FROM dbo.a3f_StringSplit(@mediator, @newSplit)
	WHERE ID = @position

	SET @output = REPLACE(@output, '0x00a6', @newSplit)

	RETURN @output
END
GO

SELECT dbo.a3f_getColumnString('T,DTCL,ELIWCO,11387,20200720,,,"Ciao, mondo. "Che bello, che sei""', 2, ',', '"')
GO
