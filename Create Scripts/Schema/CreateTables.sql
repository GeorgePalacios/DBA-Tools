USE [DBA]
GO

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [dbo].[Errors](
	[AlertID] [int] IDENTITY(1,1) NOT NULL,
	[LoggedDateTime] [datetime] NOT NULL,
	[ServerName] [varchar](100) NULL,
	[DatabaseName] [varchar](100) NULL,
	[ErrorNumber] [int] NULL,
	[ErrorSeverity] [int] NULL,
	[ErrorText] [nvarchar](4000) NULL,
	[IsResolved] [bit] NOT NULL,
CONSTRAINT [PK_Errors] PRIMARY KEY CLUSTERED 
	(
		[AlertID] ASC
	) ON [PRIMARY]
) ON [PRIMARY];
GO

ALTER TABLE [dbo].[Errors] ADD DEFAULT (getdate()) FOR [LoggedDateTime];
GO

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [dbo].[IOStats](
	[ID] [int] IDENTITY(1,1) NOT NULL,
	[SnapshotDateTime] [datetime] NULL,
	[DatabaseID] [int] NOT NULL,
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
	[space_used] [bigint] NULL,
CONSTRAINT [PK_IOStats] PRIMARY KEY CLUSTERED 
	(
		[ID] ASC
	) ON [PRIMARY]
) ON [PRIMARY];
GO

ALTER TABLE [dbo].[IOStats] ADD DEFAULT (getdate()) FOR [SnapshotDateTime];
GO

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [dbo].[WaitStats](
	[ID] [int] IDENTITY(1,1) NOT NULL,
	[SnapshotDateTime] [datetime] NULL,
	[Wait_Type] [nvarchar](60) NULL,
	[Waiting_Tasks_Count] [bigint] NULL,
	[Wait_Time_ms] [bigint] NULL,
	[Max_Wait_Time_ms] [bigint] NULL,
	[Signal_Wait_Time_ms] [bigint] NULL,
PRIMARY KEY CLUSTERED 
	(
		[ID] ASC
	) ON [PRIMARY]
) ON [PRIMARY];
GO

ALTER TABLE [dbo].[WaitStats] ADD DEFAULT (getdate()) FOR [SnapshotDateTime];
GO


