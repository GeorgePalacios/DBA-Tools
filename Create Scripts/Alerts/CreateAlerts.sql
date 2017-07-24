DECLARE @JobID UNIQUEIDENTIFIER;
DECLARE @JobIDText NVARCHAR(100);
SET @JobID = (SELECT job_id from MSDB.dbo.sysjobs WHERE name = 'DBA_LogAlert_Error');
SET @JobIDText = CAST(@JobID AS NVARCHAR(100));


IF @JobID IS NULL
BEGIN
	PRINT 'Something is wrong - the log alert job is missing. Please fix this and rerun the script'
END

ELSE
BEGIN

EXEC msdb.dbo.sp_add_alert @name=N'Severity 016',
@message_id=0,
@severity=16,
@enabled=1,
@delay_between_responses=10,
@include_event_description_in=1,
@job_id=@JobIDText;


EXEC msdb.dbo.sp_add_alert @name=N'Severity 017',
@message_id=0,
@severity=17,
@enabled=1,
@delay_between_responses=10,
@include_event_description_in=1,
@job_id=@JobIDText;

EXEC msdb.dbo.sp_add_alert @name=N'Severity 018',
@message_id=0,
@severity=18,
@enabled=1,
@delay_between_responses=10,
@include_event_description_in=1,
@job_id=@JobIDText;


EXEC msdb.dbo.sp_add_alert @name=N'Severity 019',
@message_id=0,
@severity=19,
@enabled=1,
@delay_between_responses=10,
@include_event_description_in=1,
@job_id=@JobIDText;


EXEC msdb.dbo.sp_add_alert @name=N'Severity 020',
@message_id=0,
@severity=20,
@enabled=1,
@delay_between_responses=10,
@include_event_description_in=1,
@job_id=@JobIDText;


EXEC msdb.dbo.sp_add_alert @name=N'Severity 021',
@message_id=0,
@severity=21,
@enabled=1,
@delay_between_responses=10,
@include_event_description_in=1,
@job_id=@JobIDText;


EXEC msdb.dbo.sp_add_alert @name=N'Severity 022',
@message_id=0,
@severity=22,
@enabled=1,
@delay_between_responses=10,
@include_event_description_in=1,
@job_id=@JobIDText;


EXEC msdb.dbo.sp_add_alert @name=N'Severity 023',
@message_id=0,
@severity=23,
@enabled=1,
@delay_between_responses=10,
@include_event_description_in=1,
@job_id=@JobIDText;


EXEC msdb.dbo.sp_add_alert @name=N'Severity 024',
@message_id=0,
@severity=24,
@enabled=1,
@delay_between_responses=10,
@include_event_description_in=1,
@job_id=@JobIDText;


EXEC msdb.dbo.sp_add_alert @name=N'Severity 025',
@message_id=0,
@severity=25,
@enabled=1,
@delay_between_responses=10,
@include_event_description_in=1,
@job_id=@JobIDText;


EXEC msdb.dbo.sp_add_alert @name=N'Error Number 823',
@message_id=823,
@severity=0,
@enabled=1,
@delay_between_responses=10,
@include_event_description_in=1,
@job_id=@JobIDText;


EXEC msdb.dbo.sp_add_alert @name=N'Error Number 824',
@message_id=824,
@severity=0,
@enabled=1,
@delay_between_responses=10,
@include_event_description_in=1,
@job_id=@JobIDText;


EXEC msdb.dbo.sp_add_alert @name=N'Error Number 825',
@message_id=825,
@severity=0,
@enabled=1,
@delay_between_responses=10,
@include_event_description_in=1,
@job_id=@JobIDText;

END
GO
