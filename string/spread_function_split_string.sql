USE [your db]
GO

/**
 * author:		spread
 * date:		20210510
 * description:	split a string gived a specific delimiter, qualifier and the position field
 *
 *	### INPUT ###
 *	DECLARE @string_to_split varchar(max) = '2,"2021-03-11 09:23:31",read,"Name Surname",email@email.it,123456789,"Some text, some text, "some TEXT"",1,4,"Contact page"'
 *	DECLARE @delimiter char(1) = ','
 *	DECLARE @qualifier char(1) = '"'
 *	DECLARE @position int = 7
 *	### INPUT ###
 *
 */

CREATE OR ALTER FUNCTION function_split_string (
	@string_to_split varchar(max),
	@delimiter char(1),
  @qualifier char(1),
	@position int
)
RETURNS varchar(8000)
BEGIN
	IF ( @string_to_split = '' OR @delimiter = '' OR @position = 0 ) RETURN ''

	DECLARE @string_size int = LEN(@string_to_split)
	DECLARE @current_position int = 1
	DECLARE @current_char char(1) = ''
	DECLARE @previous_char char(1)
	DECLARE @next_char char(1)
	DECLARE @in_qualified BIT = 0 -- 0 - false; 1 - true
	DECLARE @current_index_field int = 0
	DECLARE @result_field varchar(8000) = ''

	-- loop all the string
	WHILE @current_position <= @string_size
	BEGIN
		SET @previous_char = ''
		SET @next_char = ''

		IF @current_index_field = 0 SET @current_index_field = 1

		-- set the char variables
		SET @current_char = SUBSTRING(@string_to_split, @current_position, 1)
		IF (@current_position > 1) SET @previous_char = SUBSTRING(@string_to_split, @current_position - 1, 1)
		IF (@current_position < @string_size) SET @next_char = SUBSTRING(@string_to_split, @current_position + 1, 1)

		-- change the position
		SET @current_position = @current_position + 1

		-- get the field position
		IF @previous_char = @delimiter AND @in_qualified = 0
			SET @current_index_field = @current_index_field + 1

		-- change @in_qualifier status
		IF @current_char = @qualifier AND @previous_char = @delimiter AND @in_qualified = 0
		BEGIN
			SET @in_qualified = 1
			CONTINUE
		END

		IF @current_char = @qualifier AND (@next_char = @delimiter OR @next_char = '') AND @in_qualified = 1
		BEGIN
			SET @in_qualified = 0
			CONTINUE
		END

		-- store the field result
		IF @current_index_field = @position AND ((@current_char <> @delimiter AND @in_qualified = 0) OR @in_qualified = 1)
		BEGIN
			SET @result_field = @result_field + @current_char
			CONTINUE
		END

		IF @position = (@current_index_field - 1)
			RETURN @result_field
	END

	RETURN @result_field
END
GO
