--select job, its owner, steps and step run as


SELECT	jobs.name AS 'Job Name',
		logins.name AS 'Owner',
		steps.step_name as 'Step Name',
		proxy.name as 'Step run as',
		jobs.job_id

FROM msdb.dbo.sysjobs jobs INNER JOIN master.dbo.syslogins logins ON jobs.owner_sid = logins.sid
LEFT JOIN msdb.dbo.sysjobsteps steps ON steps.job_id = jobs.job_id
LEFT JOIN msdb.dbo.sysproxies proxy ON steps.proxy_id = proxy.proxy_id
AND jobs.enabled = 1

ORDER BY logins.name asc, proxy.name desc
