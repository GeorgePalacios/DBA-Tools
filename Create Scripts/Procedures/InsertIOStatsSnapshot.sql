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