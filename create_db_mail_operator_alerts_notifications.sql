-=====================================================

-- This script performs the following tasks:
--

-- Create a Database Mail account
-- Create a Database Mail Profile
-- Create an operator
-- Create alerts and set an operator
-- Create email notifications for all active jobs on the SQL instance    

  
  --==========================================================
  -- Create a Database Mail account
  --==========================================================
  
  --declare variables

  declare @acct_name varchar(100)
  declare @desc varchar(100)
  declare @email varchar(100)
  declare @reply varchar(100)
  declare @display varchar(100)
  declare @mailserver varchar(100)
  declare @port varchar(100)
  
   --Parameters list, please check before running the script

  set @acct_name = 'SQL Notifications'
  set @desc = 'SQL Server Notification Service'
  set @email = 'email@domain.com' -- change this -- Account from which the emails will be sent
  set @reply = 'email@domain.com' -- change this
  set @display = 'SQL Jobs Notifications'

  --Use relay with SSL DISABLED - change implemented on 03/04/2019

  set @mailserver = 'relay.domain.com' -- change this
  set @port = '25' -- change this if needed
  
  ---------------------------------------------------------
  
  declare @account_check int
  
  --Check if the account already exists in the database

  set @account_check = (select count(*)
  from msdb.dbo.sysmail_account
  where name = @acct_name)
  
  if @account_check > 0
  begin
  print 'ERROR: An account called '+@acct_name+' already exists, execution stopped'
  set noexec on --don't add account if exists
  end


  -- create new SMTP mail account
  EXECUTE msdb.dbo.sysmail_add_account_sp
  @account_name = @acct_name,--'SQL Notifications',
  @description = @desc,
  @email_address = @email,
  @replyto_address = @reply,
  @display_name = @display, 
  @mailserver_name = @mailserver,
  @port = @port,
  @enable_ssl = '0' -- this is set to 0 for unauthenticated relay


  /* use anonymous authentication

  --The mail configuration uses basic authentication, these are the credentials to be used:
  @username = 'email@domain.com', -- change this
  @password = 'AD/mailbox password'; -- change this
  */

--==========================================================
--Create a Database Mail Profile
--==========================================================

DECLARE @profile_id INT, @profile_description sysname;

-- get next available profile ID
SELECT @profile_id = COALESCE(MAX(profile_id),1) FROM msdb.dbo.sysmail_profile
SELECT @profile_description = 'Database Mail Profile for ' + @@servername 


EXECUTE msdb.dbo.sysmail_add_profile_sp
@profile_name = 'SQL Notifications Profile',
@description = @profile_description;

-- Add the SMTP account to the profile
EXECUTE msdb.dbo.sysmail_add_profileaccount_sp
@profile_name = 'SQL Notifications Profile',
@account_name = 'SQL Notifications',
@sequence_number = @profile_id;

-- seet as default profile
EXECUTE msdb.dbo.sysmail_add_principalprofile_sp
@profile_name = 'SQL Notifications Profile',
@principal_id = 0,
@is_default = 1 ;

--==========================================================
-- Enable Database Mail
--==========================================================
USE master;
GO

sp_CONFIGURE 'show advanced', 1
GO
RECONFIGURE
GO
sp_CONFIGURE 'Database Mail XPs', 1
GO
RECONFIGURE
GO 

-- emails to be saved in the mailbox's sent items
EXEC msdb.dbo.sp_set_sqlagent_properties @email_save_in_sent_folder = 1
GO

--==========================================================
-- Review Outcomes
--==========================================================

SELECT * FROM msdb.dbo.sysmail_profile;
SELECT * FROM msdb.dbo.sysmail_account;
GO

--==========================================================
-- Test Database Mail
--==========================================================

DECLARE @sub VARCHAR(100)
DECLARE @body_text NVARCHAR(MAX)
DECLARE @current_user VARCHAR(100) = (SELECT SYSTEM_USER)

SELECT @sub = 'Test from a New SQL Database Mail set up on ' + @@servername
SELECT @body_text = N'This is a test of Database Mail.' + CHAR(13) + CHAR(13) + 'SQL Server Version Info: ' + CAST(@@version AS VARCHAR(500))
					+ CHAR(13) + CHAR(13) + 'Set up by ' + @current_user

EXEC msdb.dbo.[sp_send_dbmail] 
@profile_name = 'SQL Notifications Profile'
, @recipients = 'email@domain.com' -- change this; who should get the test email
, @subject = @sub
, @body = @body_text

--================================================================
-- SQL Agent Properties Configuration
--================================================================

--enable mail profile !! doesn't work on SQL2008 - update it manually !!
EXEC msdb.dbo.sp_set_sqlagent_properties 
@databasemail_profile = N'SQL Notifications Profile'
, @use_databasemail=1


--==========================================================
--  Create an operator
--==========================================================

  EXEC msdb.dbo.sp_add_operator  
    @name = N'New Operator',  --Operator's name
    @enabled = 1,  
    @email_address = N'email@domain.com';  --email address for the alerts to be send to
  GO  


--==========================================================
-- Create alerts and set an operator
--==========================================================

-- declare operator
declare @operator nchar(30)
set @operator = 'New Operator' --operator as set in the SQL instance


-- add alerts
-- modified @include_event_description_in = 1 which will include error info in the email
EXEC msdb.dbo.sp_add_alert @name = N'Severity 19 Error', 
  @message_id = 0,   @severity = 19,  @include_event_description_in = 1;
 
EXEC msdb.dbo.sp_add_notification @alert_name = N'Severity 19 Error', 
  @operator_name = @operator, @notification_method = 1;
 
EXEC msdb.dbo.sp_add_alert @name = N'Severity 20 Error', 
  @message_id = 0,   @severity = 20,  @include_event_description_in = 1;
 
EXEC msdb.dbo.sp_add_notification @alert_name = N'Severity 20 Error', 
  @operator_name = @operator, @notification_method = 1;
 
EXEC msdb.dbo.sp_add_alert @name=N'Severity 21 Error', 
  @message_id = 0,   @severity = 21,  @include_event_description_in = 1;
 
EXEC msdb.dbo.sp_add_notification @alert_name = N'Severity 21 Error', 
  @operator_name = @operator, @notification_method = 1;
 
EXEC msdb.dbo.sp_add_alert @name = N'Severity 22 Error', 
  @message_id = 0,   @severity = 22,  @include_event_description_in = 1;
 
EXEC msdb.dbo.sp_add_notification @alert_name = N'Severity 22 Error', 
  @operator_name = @operator, @notification_method = 1;
 
EXEC msdb.dbo.sp_add_alert @name = N'Severity 23 Error', 
  @message_id = 0,   @severity = 23,  @include_event_description_in = 1;
 
EXEC msdb.dbo.sp_add_notification @alert_name = N'Severity 23 Error', 
  @operator_name = @operator, @notification_method = 1;
 
EXEC msdb.dbo.sp_add_alert @name = N'Severity 24 Error', 
  @message_id = 0,   @severity = 24,  @include_event_description_in = 1;
 
EXEC msdb.dbo.sp_add_notification @alert_name = N'Severity 24 Error', 
  @operator_name = @operator, @notification_method = 1;
 
EXEC msdb.dbo.sp_add_alert @name = N'Severity 25 Error', 
  @message_id = 0,   @severity = 25,  @include_event_description_in = 1;
 
EXEC msdb.dbo.sp_add_notification @alert_name = N'Severity 25 Error',
  @operator_name = @operator, @notification_method = 1;
 
EXEC msdb.dbo.sp_add_alert @name = N'Error 825', 
  @message_id = 825,  @severity = 0,  @include_event_description_in = 1;
 
EXEC msdb.dbo.sp_add_notification @alert_name = N'Error 825',
  @operator_name = @operator, @notification_method = 1;

--==================================================================
--Create email notifications for all active jobs on the SQL instance    
--==================================================================

declare @sqljob_cursor cursor
declare @job_ref varchar(100)
--declare @operator varchar(100)

--set the name of the operator to be used for notifications.
set @operator = 'New Operator'

 SET NOCOUNT ON;
--get the job id for all active jobs that don't have a current notification

SET @sqljob_cursor = CURSOR FAST_FORWARD 
FOR 
select job_id
from msdb.dbo.sysjobs
where enabled = 1
--and notify_email_operator_id = 0

OPEN @sqljob_cursor
FETCH NEXT FROM @sqljob_cursor
INTO  @job_ref

WHILE @@FETCH_STATUS = 0 
BEGIN -- LOOP

EXEC msdb.dbo.sp_update_job @job_id=@job_ref, 
 @notify_level_email=2, 
 @notify_level_netsend=2, 
 @notify_level_page=2, 
 @notify_email_operator_name=@operator,
 @notify_level_eventlog=2
 
FETCH NEXT FROM @sqljob_cursor
INTO  @job_ref

END --Loop

CLOSE @sqljob_cursor
DEALLOCATE @sqljob_cursor

SET NOEXEC OFF
GO
