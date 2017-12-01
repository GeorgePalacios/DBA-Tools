USE [DBA]
GO

/****** Object:  StoredProcedure [dbo].[Database_PermissionsLog]    Script Date: 06/11/2017 10:35:57 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		George Palacios
-- Create date: 09/06/2017
-- Description:	Procedure to log database permissions creating scripts to the [DBA].[dbo].[PermissionsLog] table
-- =============================================
CREATE PROCEDURE [dbo].[Database_PermissionsLog]
	
	@DBName NVARCHAR(128),
	@Debug BIT = 1
	
AS
BEGIN

	SET NOCOUNT ON;

	--Error variables
	DECLARE @Error BIT = 0;
	DECLARE @ErrorMsg NVARCHAR(MAX);

	IF (SELECT database_id
		FROM sys.databases
		WHERE name = @DBName) 
		IS NULL
	BEGIN
		SET @Error = 1;
		SET @ErrorMsg = 'The Database passed in under @DBName doesn''t exist'
	END

	IF @Error = 1
	BEGIN
		GOTO Error_Handling;
	END

	--Dynamic SQL Variables
	DECLARE @SQL NVARCHAR(MAX);
	SET @SQL = '';

	SET @SQL += 'USE [' + @DBName + '];
	'

	SET @SQL += '
	SELECT ''' + @DBName + ''' AS DatabaseName,
		2 AS Ordering,
		CASE
			WHEN per.state <> ''W'' THEN per.state_desc
			ELSE ''GRANT''
		END + 
		'' '' + 
		per.permission_name COLLATE latin1_general_cs_as + 
		'' ON '' + 
		QUOTENAME(sch.name) + 
		''.'' + 
		QUOTENAME(obj.name) + 
		ISNULL('' ('' + QUOTENAME(col.name) + '')'','''') +
		'' TO '' + 
		QUOTENAME(pri.name) + 
		CASE
			WHEN per.state <> ''W'' THEN '';''
			ELSE '' WITH GRANT OPTION;''
		END
	FROM sys.database_permissions per
		INNER JOIN sys.database_principals pri ON per.grantee_principal_id = pri.principal_id
		INNER JOIN sys.objects obj ON per.major_id = obj.object_id
		LEFT JOIN sys.columns col ON per.major_id = col.object_id AND per.minor_id = col.column_id
		INNER JOIN sys.schemas sch ON obj.schema_id = sch.schema_id
	WHERE per.class > 0
	UNION
	SELECT 	''' + @DBName + ''' AS DatabaseName,
		1 AS Ordering,
		CASE
			WHEN per.state <> ''W'' THEN per.state_desc
			ELSE ''GRANT''
		END + 
		'' '' + 
		per.permission_name COLLATE latin1_general_cs_as + 
		'' TO '' + 
		QUOTENAME(pri.name) + 
		CASE
			WHEN per.state <> ''W'' THEN '';''
			ELSE '' WITH GRANT OPTION;''
		END
	FROM sys.database_permissions per
		INNER JOIN sys.database_principals pri ON per.grantee_principal_id = pri.principal_id
	WHERE per.class = 0
		AND name <> ''dbo''
	'

	IF (@Debug = 0)
	BEGIN
		DELETE FROM [DBA].[dbo].[PermissionsLog] WHERE DatabaseName = @DBName;
		INSERT INTO [DBA].[dbo].[PermissionsLog]
		EXEC (@SQL);
	END
	ELSE
	BEGIN
		PRINT (@SQL);
	END

	Error_Handling:

	IF @Error = 1
	BEGIN;
		THROW 51000, @ErrorMsg, 1;
	END;
	
END
GO