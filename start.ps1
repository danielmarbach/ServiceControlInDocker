# start the service
Write-Verbose "Upgrading Particular.ServiceControl"

# patch app.config with values from function params

Invoke-ServiceControlInstanceUpgrade -Name Particular.ServiceControl

start-service Particular.ServiceControl

Write-Verbose "Started Particular.ServiceControl."

$lastCheck = (Get-Date).AddSeconds(-2) 
while ($true) 
{ 
    #Get-EventLog -LogName Application -Source "Particular.ServiceControl" -After $lastCheck | Select-Object TimeGenerated, EntryType, Message	 
    $lastCheck = Get-Date 
    Start-Sleep -Seconds 2 
}
