USE [DBA]
GO

/****** Object:  StoredProcedure [dbo].[Database_Backup_ToURL]    Script Date: 01/12/2017 08:58:49 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

-- =============================================
-- Author:		George Palacios
-- Create date: 05/09/2017
-- Description:	Procedure to back up a single database to an URL
-- =============================================
CREATE PROCEDURE [dbo].[Database_Backup_ToURL] 
	(

		@DBName NVARCHAR(128),
		@BackupURL NVARCHAR(2048),
		@CredentialName NVARCHAR(255), 
		@Debug BIT = 1

	)

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

	--Create backup command
	SET @SQL = '
	BACKUP DATABASE [' + @DBName + '] 
	TO URL = N'''+ @BackupURL + ''' 
	WITH NOFORMAT, 
		NAME = N'''+ @DBName + '-Full Database Backup'', 
		SKIP, 
		NOREWIND, 
		NOUNLOAD, 
		COMPRESSION, 
		STATS = 10, 
		INIT,
		CREDENTIAL = N''' + @CredentialName + ''';'

	IF @Debug = 0
	BEGIN;
		BEGIN TRY
			DECLARE @ErrTxt NVARCHAR(MAX);
			SET @ErrTxt = 'Backing up database ' + @DBName;
			RAISERROR (@ErrTxt,0,1) WITH NOWAIT;
			EXEC(@SQL);
		END TRY
		BEGIN CATCH
			SET @ErrorMsg = ERROR_MESSAGE();
			SET @Error = 1;
		END CATCH
	END;
	ELSE IF @Debug = 1
	BEGIN;
		PRINT @SQL;
	END;

	IF @Error = 1
	BEGIN
		GOTO Error_Handling;
	END

	Error_Handling:

	IF @Error = 1
	BEGIN;
		THROW 51000, @ErrorMsg, 1;
	END;

END
GO
