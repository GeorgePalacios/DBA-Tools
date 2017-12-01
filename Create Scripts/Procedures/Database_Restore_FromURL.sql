USE [DBA]
GO

/****** Object:  StoredProcedure [dbo].[Database_Restore_FromURL]    Script Date: 06/11/2017 10:35:57 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		George Palacios
-- Create date: 06/09/2017
-- Description:	Procedure to restore a single database from an URL
-- =============================================
CREATE PROCEDURE [dbo].[Database_Restore_FromURL]
	@BackupURL NVARCHAR(2048),
	@CredentialName NVARCHAR(255),
	@DBName NVARCHAR(128),
	@DataFolder NVARCHAR(255),
	@LogFolder NVARCHAR(255),
	@Debug BIT = 1

AS
BEGIN

	SET NOCOUNT ON;

	--Error variables
	DECLARE @Error BIT = 0;
	DECLARE @ErrorMsg NVARCHAR(MAX);

	IF (SELECT credential_id
		FROM sys.credentials
		WHERE name = @CredentialName)
		IS NULL
	BEGIN
		SET @Error = 1;
		SET @ErrorMsg = 'The credential passed in under @CredentialName doesn''t exist'
	END

	IF @Error = 1
	BEGIN
		GOTO Error_Handling;
	END;

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

	--Create table to hold filelist from backup
	CREATE TABLE #Files (
		LogicalName varchar(128),
		[PhysicalName] varchar(128), 
		[Type] varchar, 
		[FileGroupName] varchar(128), 
		[Size] varchar(128), 
		[MaxSize] varchar(128), 
		[FileId]varchar(128), 
		[CreateLSN]varchar(128), 
		[DropLSN]varchar(128), 
		[UniqueId]varchar(128), 
		[ReadOnlyLSN]varchar(128), 
		[ReadWriteLSN]varchar(128), 
		[BackupSizeInBytes]varchar(128), 
		[SourceBlockSize]varchar(128), 
		[FileGroupId]varchar(128), 
		[LogGroupGUID]varchar(128), 
		[DifferentialBaseLSN]varchar(128), 
		[DifferentialBaseGUID]varchar(128), 
		[IsReadOnly]varchar(128), 
		[IsPresent]varchar(128), 
		[TDEThumbprint]varchar(128)
	);

	INSERT INTO #Files
	EXEC('RESTORE FILELISTONLY FROM URL = N''' + @BackupURL + '''
		WITH CREDENTIAL = ''' + @CredentialName + ''',
		BLOCKSIZE = 4096;');

	IF ISNULL((SELECT COUNT(*) FROM #Files),0) = 0
	BEGIN
		SET @Error = 1
		SET @ErrorMsg = 'The backup file is not valid'
	END
	
	IF @Error = 1
	BEGIN
		GOTO Error_Handling;
	END;

	--Ensure formatting for @DataFolder and @LogFolder
	IF RIGHT(@DataFolder,1) <> '\'
	BEGIN
		SET @DataFolder += '\';
	END

	IF RIGHT(@LogFolder,1) <> '\'
	BEGIN
		SET @LogFolder += '\';
	END

	--Construct the restore statements
	DECLARE @SQL NVARCHAR(MAX);
	SET @SQL = '';

	IF EXISTS (SELECT database_id FROM sys.databases WHERE name = @DBName)
	BEGIN

		SET @SQL = 'ALTER DATABASE [' + @DBName + '] SET OFFLINE WITH ROLLBACK IMMEDIATE;
		DROP DATABASE [' + @DBName + '];
		'
	END

	--Set the database to restore
	SET @SQL += 'RESTORE DATABASE [' + @DBName + ']
	'

	--Set the backup URL to use
	SET @SQL += 'FROM URL = ''' + @BackupURL + '''
	'

	--Set the access credential to use
	SET @SQL += 'WITH CREDENTIAL = ''' + @CredentialName + '''
	'

	--Set the blocksize (Azure stores page blobs in 4096 block size)
	SET @SQL += ', BLOCKSIZE = 4096
	'
	
	--Set location for Data files
	SELECT @SQL += ', MOVE ''' + LogicalName + ''' TO ''' + @DataFolder + @DBName + '_' + LogicalName + '''
	'
	FROM #Files
	WHERE Type = 'D'

	--Set location for log files
	SELECT @SQL += ', MOVE ''' + LogicalName + ''' TO ''' + @LogFolder + @DBName + '_' + LogicalName + '''
	'
	FROM #Files
	WHERE Type = 'L'

	IF (@Debug = 0)
	BEGIN
		EXEC (@SQL);
	END
	ELSE
	BEGIN
		PRINT @SQL;
	END

	Error_Handling:

	IF @Error = 1
	BEGIN;
		THROW 51000, @ErrorMsg, 1;
	END;

END
GO

