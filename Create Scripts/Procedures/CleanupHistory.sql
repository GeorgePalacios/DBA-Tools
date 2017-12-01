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