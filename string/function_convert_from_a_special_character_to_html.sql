USE [your db]
GO

/**
 * author:		spread
 * description:	allow the convertion from a special character to a specific tag html
 *				- ** will be convert into <strong /> tag
 *
 * try to test it by enter: SELECT dbo.function_convert_from_a_special_character_to_html('ciao mi piacerebbe avere del testo in **grassetto**, nel formato **html')
 *
 */

 CREATE OR ALTER FUNCTION function_convert_from_a_special_character_to_html
	(@input_string varchar(MAX))
RETURNS varchar(MAX)
BEGIN
	IF (@input_string = '') RETURN ''

	DECLARE @i int = 1
	DECLARE @current_char varchar(5) = ''
	DECLARE @special_char varchar(5) = ''
	DECLARE @text_size int = LEN(@input_string)
	DECLARE @new_text varchar(max) = ''
	DECLARE @in_open_tag BIT = 0
	DECLARE @current_enum varchar(5) = ''
	DECLARE @tmp_conversion TABLE (
		special_char varchar(5),
		its_opening_conversion varchar(100),
		its_closing_conversion varchar(100),
		UNIQUE (special_char)
	)

	-- set your convertion
	-- in the first column (special_char) set the special character used from the client
	-- in the second one (its_opening_conversion) set the open tag format
	-- in the last one (its_closing_conversion) the close tag
	INSERT INTO @tmp_conversion
	VALUES
		('**', '<strong>', '</strong>')

	WHILE @i <= @text_size
	BEGIN
		SET @current_char = SUBSTRING(@input_string, @i, 1)

		-- get the enum special char
		WHILE ( EXISTS( SELECT * FROM @tmp_conversion WHERE CHARINDEX(@current_char, special_char) > 0 ) AND ( @i <= @text_size ) )
		BEGIN
			SET @special_char = @current_char
			SET @i = @i + 1
			SET @current_char = @current_char + SUBSTRING(@input_string, @i, 1)
		END

		-- convert the special character to the corresponding opening character
		IF EXISTS( SELECT * FROM @tmp_conversion WHERE special_char = @special_char ) AND @in_open_tag = 0
		BEGIN
			SET @new_text = @new_text + ISNULL(( SELECT its_opening_conversion FROM @tmp_conversion WHERE special_char = @special_char ), '')
			SET @in_open_tag = 1
			SET @current_enum = @special_char
			SET @special_char = ''
			CONTINUE
		END

		-- convert the special character to the corresponding closing character
		IF EXISTS( SELECT * FROM @tmp_conversion WHERE special_char = @special_char ) AND @in_open_tag = 1 AND @current_enum = @special_char
		BEGIN
			SET @new_text = @new_text + ISNULL(( SELECT its_closing_conversion FROM @tmp_conversion WHERE special_char = @special_char ), '')
			SET @in_open_tag = 0
			SET @special_char = ''
			CONTINUE
		END

		SET @i = @i + 1
		SET @new_text = @new_text + @current_char
	END

	-- if the tag wasn't close
	IF ( @in_open_tag = 1 )
	BEGIN
		SET @new_text = @new_text + ISNULL(( SELECT its_closing_conversion FROM @tmp_conversion WHERE special_char = @current_enum ), '')
	END

	RETURN @new_text
END
