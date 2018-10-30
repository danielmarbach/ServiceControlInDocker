
# start the service
Write-Verbose "Upgrading Particular.ServiceControl";

# If a backup config exists, overwrite the current one
If (Test-Path C:\ServiceControl\DB\backup.config)
{
	Copy-Item -Path C:\ServiceControl\DB\backup.config -Destination C:\ServiceControl\Bin\ServiceControl.exe.config
} Else {
	Write-Verbose "New Installation Detected"
	# Back up the current config created by the build	
	Copy-Item -Path C:\ServiceControl\Bin\ServiceControl.exe.config -Destination C:\ServiceControl\DB\backup.config
	# Write out the current version as well
	Set-Content -Path C:\ServiceControl\DB\currentscversion -Value $env:sc_version;
	# Run setup again so queues can be created. May need a loop for orchestration with brokers like RabbitMq that may not be ready yet.
	C:\ServiceControl\Bin\ServiceControl.exe --setup --serviceName=Particular.ServiceControl;
}

# Pull the database version out
$db_version = Get-Content -Path C:\ServiceControl\DB\currentscversion -Raw;

If ($db_version -ne $env:sc_version) {
	Write-Verbose "Upgrading existing Particular.ServiceControl version $db_version to $env:sc_version.";
	
	Import-Module C:\Program` Files` `(x86`)\Particular` Software\ServiceControl` Management\ServiceControlMgmt.psd1;
	
	Invoke-ServiceControlInstanceUpgrade -Name Particular.ServiceControl;

	# Update the db version file with the latest version
	Set-Content -Path C:\ServiceControl\DB\currentscversion -Value $env:sc_version;
}

start-service Particular.ServiceControl;

Write-Verbose "Started Particular.ServiceControl.";

$lastCheck = (Get-Date).AddSeconds(-2);
while ($true) 
{ 
    $lastCheck = Get-Date;
    Start-Sleep -Seconds 2; 
}
