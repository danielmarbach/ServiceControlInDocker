param (
	[Parameter(Mandatory=$true)][string]$SettingKey,
	[Parameter(Mandatory=$true)][string]$SettingValue,
	[switch]$RunTime = $true
)

# Stop the service if it is running
$running = false;
$scservice = Get-Service -Name 'Particular.ServiceControl';
If ($scservice.Status -eq 'Running')
{
	$running = true;
	Stop-Service 'Particular.ServiceControl';
}

# Update the config file
[xml]$appConfig = Get-Content 'C:\ServiceControl\Bin\ServiceControl.exe.config';

If ($SettingKey -eq 'connectionString')
{
	If ($appConfig.configuration.connectionStrings -eq $null)
	{
	    $connectionStrings = $appConfig.CreateElement('connectionStrings');
	    $connectionString = $appConfig.CreateElement('add');
	    $connectionStringName = $appConfig.CreateAttribute('name');
	    $connectionStringName.Value = 'NServiceBus/Transport';
	    $connectionString.SetAttributeNode($connectionStringName);
	    $connectionStringValue = $appConfig.CreateAttribute('connectionString');
	    $connectionStringValue.Value = $SettingValue;
	    $connectionString.SetAttributeNode($connectionStringValue);
	    $connectionStrings.AppendChild($connectionString);
	    $appConfig.configuration.AppendChild($connectionStrings);
	} Else {		
		$appConfig.configuration.connectionStrings.add | foreach { $_.connectionString = $SettingValue }
	}
} Else {
	$appSetting = $appConfig.SelectSingleNode("//appSettings/add[@key='$SettingKey']");
	$appSetting.SetAttribute($SettingKey, $SettingValue);
}
 
$appConfig.Save('C:\ServiceControl\Bin\ServiceControl.exe.config');

# If this isn't running during the build, overwrite the backup with the saved file
If ($RunTime)
{
	Copy-Item -Path C:\ServiceControl\Bin\ServiceControl.exe.config -Destination C:\ServiceControl\DB\backup.config;
}

# Start the service back up if it was running before
If ($running)
{
	Start-Service 'Particular-ServiceControl';
}