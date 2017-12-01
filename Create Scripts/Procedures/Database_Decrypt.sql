USE [DBA]
GO

/****** Object:  StoredProcedure [dbo].[Database_Decrypt]    Script Date: 06/11/2017 10:35:57 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROCEDURE [dbo].[Database_Decrypt]

	(
		@DBName NVARCHAR(128),
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

	--Dynamic SQL Variable
	DECLARE @SQL NVARCHAR(MAX);
	SET @SQL = '';

	--Create commands to set encryption to off
	SET @SQL = '
		USE [master];
		ALTER DATABASE [' + @DBName + ']
		SET ENCRYPTION OFF;
		'

	IF @Debug = 0
	BEGIN;
		BEGIN TRY
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

	--Wait for database to decrypt using a loop
	IF @Debug = 0
	BEGIN
		DECLARE @State TINYINT = 0;

		SET @State = (
			SELECT COUNT(*)
			FROM sys.databases db
				LEFT JOIN sys.dm_database_encryption_keys dm
				ON db.database_id = dm.database_id
			WHERE dm.encryption_state = 1
				AND db.is_encrypted = 0
				AND db.name = @DBName);

		WHILE (@State = 0)
		BEGIN

			WAITFOR DELAY '00:01:00';
			RAISERROR('Waiting for database to decrypt',0,1) WITH NOWAIT;

			SET @State = (
				SELECT COUNT(*)
				FROM sys.databases db
					LEFT JOIN sys.dm_database_encryption_keys dm
					ON db.database_id = dm.database_id
				WHERE dm.encryption_state = 1
					AND db.is_encrypted = 0
					AND db.name = @DBName);		
		END
	END

	--Reset the variables for reuse
	SET @SQL = '';

	SELECT @SQL += 'USE [' + @DBName + '];
		
	DROP DATABASE ENCRYPTION KEY;

	WAITFOR DELAY ''00:00:20'';'

	SELECT @SQL +=
	'
	DBCC SHRINKFILE (''' + name + ''');
	'
	FROM sys.master_files
	WHERE DB_NAME(database_ID) = @DBName
		AND type = 1;

	--Shrink the log files
	IF @Debug = 0
	BEGIN;
		BEGIN TRY
			RAISERROR('Shrinking log files',0,1) WITH NOWAIT;
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