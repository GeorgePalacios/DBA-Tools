USE [DBA]
GO

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO


CREATE PROCEDURE [dbo].[CleanupHistory] AS
BEGIN

	DECLARE @DeleteFromDateTime DATETIME;
	SET @DeleteFromDateTime = DATEADD(MM, -1, CURRENT_TIMESTAMP);
	
	DELETE FROM [DBA].[dbo].[WaitStats] WHERE SnapshotDateTime <= @DeleteFromDateTime;
	
	DELETE FROM [DBA].[dbo].[IOStats] WHERE SnapshotDateTime <= @DeleteFromDateTime;

	DELETE FROM [DBA].[dbo].[Errors] WHERE LoggedDateTime <= @DeleteFromDateTime;

END
GO

USE [DBA]
GO

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[DBA_Insert_Error]

	@ServerName NVARCHAR(255),
	@DatabaseName NVARCHAR(255),
	@ErrorNumber INT,
	@ErrorSeverity INT,
	@ErrorText NVARCHAR(4000)

AS
BEGIN

	SET NOCOUNT ON;

	INSERT INTO [DBA].[dbo].[Errors] (
		LoggedDateTime,
		ServerName,
		DatabaseName,
		ErrorNumber,
		ErrorSeverity,
		ErrorText,
		IsResolved)

	SELECT 
		CURRENT_TIMESTAMP,
		@ServerName,
		@DatabaseName,
		@ErrorNumber,
		@ErrorSeverity,
		@ErrorText,
		0

END
GO

USE [DBA]
GO

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[InsertIOStatsSnapshot] AS
BEGIN

	SET NOCOUNT ON;

	DECLARE @SQL NVARCHAR(MAX);
	SET @SQL = N'';

	SET @SQL = '

	CREATE TABLE #TempIOStats (
		[DatabaseID] INT NOT NULL,
		[DatabaseName] [nvarchar](128) NULL,
		[FileType] [nvarchar](128) NULL,
		[PhysicalName] [nvarchar](260) NULL,
		[num_of_reads] [bigint] NULL,
		[num_of_bytes_read] [bigint] NULL,
		[io_stall_read_ms] [bigint] NULL,
		[num_of_writes] [bigint] NULL,
		[num_of_bytes_written] [bigint] NULL,
		[io_stall_write_ms] [bigint] NULL,
		[io_stall] [bigint] NULL,
		[size_on_disk_bytes] [bigint] NULL,
		[space_used] [bigint] NULL
		);

	';

	DECLARE @SQLTemplate NVARCHAR(MAX);
	SET @SQLTemplate = '

	USE [yxy];

	INSERT INTO #TempIOStats (
		DatabaseID,
		DatabaseName,
		FileType,
		PhysicalName,
		num_of_reads,
		num_of_bytes_read,
		io_stall_read_ms,
		num_of_writes,
		num_of_bytes_written,
		io_stall_write_ms,
		io_stall,
		size_on_disk_bytes,
		[space_used])
	SELECT 
		mf.database_id,
		DB_NAME(mf.database_id), 
		mf.type_desc,
		mf.physical_name,
		divfs.num_of_reads , 
		divfs.num_of_bytes_read , 
		divfs.io_stall_read_ms , 
		divfs.num_of_writes , 
		divfs.num_of_bytes_written , 
		divfs.io_stall_write_ms , 
		divfs.io_stall , 
		size_on_disk_bytes,
		CAST(FILEPROPERTY(mf.NAME, ''SPACEUSED'') AS INT)
	FROM sys.dm_io_virtual_file_stats(uyu, NULL) AS divfs 
    JOIN sys.master_files AS mf ON mf.database_id = divfs.database_id 
          AND mf.file_id = divfs.file_id;
	'

	SELECT @SQL += REPLACE(REPLACE(@SQLTemplate, 'yxy', name), 'uyu', database_id)
	FROM sys.databases;

	SET @SQL += '

	INSERT INTO [DBA].[dbo].[IOStats]
	(
		DatabaseID,
		DatabaseName,
		FileType,
		PhysicalName,
		num_of_reads,
		num_of_bytes_read,
		io_stall_read_ms,
		num_of_writes,
		num_of_bytes_written,
		io_stall_write_ms,
		io_stall,
		size_on_disk_bytes,
		[space_used]
	)
	SELECT
		DatabaseID,
		DatabaseName,
		FileType,
		PhysicalName,
		num_of_reads,
		num_of_bytes_read,
		io_stall_read_ms,
		num_of_writes,
		num_of_bytes_written,
		io_stall_write_ms,
		io_stall,
		size_on_disk_bytes,
		[space_used]
	FROM #TempIOStats;
	'

	EXEC ( @SQL );

END
GO

USE [DBA]
GO

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[InsertWaitStatsSnapshot] AS 
BEGIN

	SET NOCOUNT ON;

	INSERT INTO dbo.WaitStats (
		Wait_Type,
		Waiting_Tasks_Count,
		Wait_Time_ms,
		Max_Wait_Time_ms,
		Signal_Wait_Time_ms)

	SELECT Wait_Type,
		waiting_tasks_count,
		wait_time_ms,
		max_wait_time_ms,
		signal_wait_time_ms
	FROM sys.dm_os_wait_stats
	WHERE wait_type not in (
		N'BROKER_EVENTHANDLER',
		N'BROKER_RECEIVE_WAITFOR',
		N'BROKER_TASK_STOP',
		N'BROKER_TO_FLUSH',
		N'BROKER_TRANSMITTER',
		N'CHECKPOINT_QUEUE',
		N'CHKPT',
		N'CLR_AUTO_EVENT',
		N'CLR_MANUAL_EVENT',
		N'CLR_SEMAPHORE',
		N'DBMIRROR_DBM_EVENT',
		N'DBMIRROR_DBM_MUTEX',
		N'DBMIRROR_EVENTS_QUEUE',
		N'DBMIRROR_WORKER_QUEUE',
		N'DBMIRRORING_CMD',
		N'DIRTY_PAGE_POLL',
		N'DISPATCHER_QUEUE_SEMAPHORE',
		N'EXECSYNC',
		N'FSAGENT',
		N'FT_IFTS_SCHEDULER_IDLE_WAIT',
		N'FT_IFTSHC_MUTEX',
		N'HADR_CLUSAPI_CALL',
		N'HADR_FILESTREAM_IOMGR_IOCOMPLETION',
		N'HADR_LOGCAPTURE_WAIT',
		N'HADR_NOTIFICATION_DEQUEUE',
		N'HADR_TIMER_TASK',
		N'HADR_WORK_QUEUE',
		N'LAZYWRITER_SLEEP',
		N'LOGMGR_QUEUE',
		N'MEMORY_ALLOCATION_EXT',
		N'ONDEMAND_TASK_QUEUE',
		N'PREEMPTIVE_HADR_LEASE_MECHANISM',
		N'PREEMPTIVE_OS_AUTHENTICATIONOPS',
		N'PREEMPTIVE_OS_AUTHORIZATIONOPS',
		N'PREEMPTIVE_OS_COMOPS',
		N'PREEMPTIVE_OS_CREATEFILE',
		N'PREEMPTIVE_OS_CRYPTOPS',
		N'PREEMPTIVE_OS_DEVICEOPS',
		N'PREEMPTIVE_OS_FILEOPS',
		N'PREEMPTIVE_OS_GENERICOPS',
		N'PREEMPTIVE_OS_LIBRARYOPS',
		N'PREEMPTIVE_OS_PIPEOPS',
		N'PREEMPTIVE_OS_QUERYREGISTRY',
		N'PREEMPTIVE_OS_VERIFYTRUST',
		N'PREEMPTIVE_OS_WAITFORSINGLEOBJECT',
		N'PREEMPTIVE_OS_WRITEFILEGATHER',
		N'PREEMPTIVE_SP_SERVER_DIAGNOSTICS',
		N'PREEMPTIVE_XE_GETTARGETSTATE',
		N'PWAIT_ALL_COMPONENTS_INITIALIZED',
		N'PWAIT_DIRECTLOGCONSUMER_GETNEXT',
		N'QDS_ASYNC_QUEUE',
		N'QDS_CLEANUP_STALE_QUERIES_TASK_MAIN_LOOP_SLEEP',
		N'QDS_PERSIST_TASK_MAIN_LOOP_SLEEP',
		N'QDS_SHUTDOWN_QUEUE',
		N'REDO_THREAD_PENDING_WORK',
		N'REQUEST_FOR_DEADLOCK_SEARCH',
		N'RESOURCE_QUEUE',
		N'SERVER_IDLE_CHECK',
		N'SLEEP_BPOOL_FLUSH',
		N'SLEEP_DBSTARTUP', 
		N'SLEEP_DCOMSTARTUP',
		N'SLEEP_MASTERDBREADY', 
		N'SLEEP_MASTERMDREADY',
		N'SLEEP_MASTERUPGRADED', 
		N'SLEEP_MSDBSTARTUP',
		N'SLEEP_SYSTEMTASK', 
		N'SLEEP_TASK',
		N'SP_SERVER_DIAGNOSTICS_SLEEP',
		N'SQLTRACE_BUFFER_FLUSH',
		N'SQLTRACE_INCREMENTAL_FLUSH_SLEEP',
		N'SQLTRACE_WAIT_ENTRIES',
		N'UCS_SESSION_REGISTRATION',
		N'WAIT_FOR_RESULTS',
		N'WAIT_XTP_CKPT_CLOSE',
		N'WAIT_XTP_HOST_WAIT',
		N'WAIT_XTP_OFFLINE_CKPT_NEW_LOG',
		N'WAIT_XTP_RECOVERY',
		N'WAITFOR',
		N'WAITFOR_TASKSHUTDOWN',
		N'XE_TIMER_EVENT',
		N'XE_DISPATCHER_WAIT'
	)
	AND wait_time_ms > 0;

END
GO

USE [DBA]
GO
/****** Object:  StoredProcedure [dbo].[Database_Backup]    Script Date: 06/11/2017 10:35:57 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		George Palacios
-- Create date: 05/09/2017
-- Description:	Procedure to back up a single database to disk
-- =============================================
CREATE PROCEDURE [dbo].[Database_Backup_ToDisk] 
	(

		@DBName NVARCHAR(128),
		@FilePath NVARCHAR(255),
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
	TO DISK = N'''+ @FilePath + ''' 
	WITH NOFORMAT, 
		NAME = N'''+ @DBName + '-Full Database Backup'', 
		SKIP, 
		NOREWIND, 
		NOUNLOAD, 
		COMPRESSION, 
		STATS = 10, 
		INIT;'

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
/****** Object:  StoredProcedure [dbo].[Database_Backup_ToURL]    Script Date: 06/11/2017 10:35:57 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		George Palacios
-- Create date: 05/09/2017
-- Description:	Procedure to back up a single database
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
		TRUNCATE TABLE [DBA].[dbo].[PermissionsLog];
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
/****** Object:  StoredProcedure [dbo].[Database_Refresh_FromURL]    Script Date: 06/11/2017 10:35:57 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		George Palacios
-- Create date: 09/08/2017
-- Description:	Procedure to refresh an individual database from an URL
-- =============================================
CREATE PROCEDURE [Junifer].[Database_Refresh_FromURL]
	@DBName NVARCHAR(128),
	@BackupURL NVARCHAR(2048),
	@CredentialName NVARCHAR(255),
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

	IF (SELECT ID
		FROM dbo.DatabaseRefreshList
		WHERE DatabaseName = @DBName)
		IS NULL
	BEGIN
		SET @Error = 1;
		SET @ErrorMsg = 'The database passed in under @DBName doesn''t have a record in the DBA.dbo.DatabaseRefreshList table'
	END

	IF @Error = 1
	BEGIN
		GOTO Error_Handling;
	END

	DECLARE @DataFolder NVARCHAR(255);
	DECLARE @LogFolder NVARCHAR(255);

	SET @DataFolder = (SELECT datafolder FROM dbo.DatabaseRefreshList WHERE DatabaseName = @DBName);
	SET @LogFolder = (SELECT logfolder FROM dbo.DatabaseRefreshList WHERE DatabaseName = @DBName);

	IF (@DataFolder IS NULL)
	BEGIN
		SET @Error = 1;
		SET @ErrorMsg = 'The @DataFolder parameter retrieved from the DBA.dbo.DatabaseRefreshList table is null. Please debug'
	END

	IF @Error = 1
	BEGIN
		GOTO Error_Handling;
	END

	IF (@LogFolder IS NULL)
	BEGIN
		SET @Error = 1;
		SET @ErrorMsg = 'The @LogFolder parameter retrieved from the DBA.dbo.DatabaseRefreshList table is null. Please debug'
	END

	IF @Error = 1
	BEGIN
		GOTO Error_Handling;
	END

	IF (@DBName IN ('Junifer_SYS','Junifer_SIT','Junifer_Obfuscation','Junifer_TRG','Junifer_UAT'))
	BEGIN
		EXEC Junifer.Database_MetadataLog 
			@DBName = @DBname,
			@Debug = @Debug;
	END

	EXEC dbo.Database_PermissionsLog 
		@DBName = @DBName, 
		@Debug = @Debug;

	EXEC dbo.Database_Restore_FromURL 
		@BackupURL = @BackupURL, 
		@CredentialName = @CredentialName, 
		@DBName = @DBName, 
		@DataFolder = @DataFolder, 
		@LogFolder = @LogFolder, 
		@Debug = @Debug;

	EXEC dbo.Database_PermissionsApply
		@DBName = @DBName,
		@Debug = @Debug

	IF (@DBName IN ('Junifer_SYS','Junifer_SIT','Junifer_Obfuscation','Junifer_TRG','Junifer_UAT'))
	BEGIN

		EXEC Junifer.Database_MetadataApply
			@DBName = @DBname,
			@Debug = @Debug;

		EXEC Junifer.Database_Obfuscate 
			@DBName = @DBName,
			@Debug = 0;

	END

	Error_Handling:

	IF @Error = 1
	BEGIN;
		THROW 51000, @ErrorMsg, 1;
	END;
	
END
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

