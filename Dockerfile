FROM microsoft/dotnet-framework
LABEL vendor="Particular Software"
LABEL net.particular.servicecontrol.version="3.2.3"

ENV sc_version="3.2.3"

ENV transport_type="MSMQ" \
    connection_string="" \
    port="33333" \
    management_port="33334" \
    audit_queue="audit" \
    audit_retention="01:00:00" \
    error_queue="error" \
    error_retention="10:00:00:00"

SHELL ["powershell", "-Command", "$ErrorActionPreference = 'Stop'; $ProgressPreference = 'SilentlyContinue';"]

# For now, should be a new image FROM this one when we can use LearningTransport
RUN Enable-WindowsOptionalFeature -Online -FeatureName "MSMQ" -All -LimitAccess; \
    Enable-WindowsOptionalFeature -Online -FeatureName "MSMQ-Server" -All -LimitAccess;

# MSMQ ports
# https://support.microsoft.com/en-us/help/183293/how-to-configure-a-firewall-for-msmq-access
EXPOSE 1801/tcp 3527/udp 1801/udp 135 2101 2103 2105

# make install files accessible
COPY *.ps1 /
WORKDIR /

# Download SC installer and run it
RUN [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12; \
        Invoke-WebRequest -Uri "https://github.com/Particular/ServiceControl/releases/download/$env:sc_version/Particular.ServiceControl-$env:sc_version.exe" -OutFile installer.exe ; \
        Start-Process -Wait -FilePath .\installer.exe -ArgumentList /qn ; \
        Remove-Item -Recurse -Force installer.exe

# Install SC instance using MSMQ
RUN Import-Module C:\Program` Files` `(x86`)\Particular` Software\ServiceControl` Management\ServiceControlMgmt.psd1 ;\
        New-ServiceControlInstance -Name Particular.ServiceControl -InstallPath C:\ServiceControl\Bin -DBPath C:\ServiceControl\DB -LogPath C:\ServiceControl\Logs -Port $env:port -DatabaseMaintenancePort $env:management_port -Transport MSMQ -ErrorQueue $env:error_queue  -AuditQueue $env:audit_queue -ForwardAuditMessages:$false -AuditRetentionPeriod $env:audit_retention -ErrorRetentionPeriod $env:error_retention; \
        (Get-Service -Name 'Particular.ServiceControl').WaitForStatus('Running'); \
        Stop-Service -Name 'Particular.ServiceControl'; \
        (Get-Service -Name 'Particular.ServiceControl').WaitForStatus('Stopped'); \
        Set-Service -Name 'Particular.ServiceControl' -StartupType Manual;

# Remove the generated DB and Logs directories
RUN Remove-Item -path C:\ServiceControl\DB -force -recurse -ErrorAction Ignore; \
        Move-Item C:\ServiceControl\DB C:\ServiceControl\DB2; \
	Remove-Item -path C:\ServiceControl\Logs -force -recurse;

# Update ServiceControl.exe.config with correct transport type and, if not MSMQ, connectionstring. This is messed up, no capability to use the passed in transport, so we have to create our own switching logic to translate the transport_type (simple name) to ServiceControl/TransportType (TransportCustomization assemblyqualified name) if we don't write more code
RUN .\configsc --SettingKey 'ServiceControl/TransportType' --SettingValue 'ServiceControl.Transports.ASB.ASBForwardingTopologyTransportCustomization, ServiceControl.Transports.ASB' --Runtime $false; \
    .\configsc --SettingKey 'connectionString' --SettingValue '$env:connection_string' --Runtime $false;

# Just start SC, the start script will do the rest
CMD .\start -Verbose        
