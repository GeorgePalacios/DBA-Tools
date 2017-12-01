USE [DBA]
GO

/****** Object:  StoredProcedure [dbo].[Database_PermissionsApply]    Script Date: 06/11/2017 10:35:57 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		George Palacios
-- Create date: 08/09/2017
-- Description:	Procedure to take logged procedures from the [DBA].[dbo].[PermissionsLog] table and apply them to the database supplied in @DBName
-- =============================================
CREATE PROCEDURE [dbo].[Database_PermissionsApply]

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

	IF NOT EXISTS (SELECT 1 FROM [DBA].[dbo].[PermissionsLog] WHERE DatabaseName = @DBName)
	BEGIN
		SET @Error = 1;
		SET @ErrorMsg = 'There are no logged permissions for the database passed in under @DBName'
	END

	IF @Error = 1
	BEGIN
		GOTO Error_Handling;
	END
	
	--Dynamic sql variable to hold commands
	DECLARE @SQL NVARCHAR(MAX);
	SET @SQL = '';

	SELECT @SQL += Command + CHAR(13) + CHAR(10)
	FROM [DBA].[dbo].[PermissionsLog]
	WHERE DatabaseName = @DBName
	ORDER BY Ordering

	IF (@Debug = 0)
	BEGIN
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