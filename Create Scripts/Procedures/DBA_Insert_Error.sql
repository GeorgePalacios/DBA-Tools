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