FROM microsoft/dotnet-framework
LABEL vendor="Particular Software"
LABEL net.particular.servicecontrol.version="3.2.3"

ENV exe "https://github.com/Particular/ServiceControl/releases/download/3.2.3/Particular.ServiceControl-3.2.3.exe"

ENV transport_type="MSMQ" \
    connection_string="" \
    port="33333" \
    management_port="33334" \
    audit_queue="audit" \
    audit_retention="01:00:00" \
    error_queue="error" \
    error_retention="10:00:00:00"

SHELL ["powershell", "-Command", "$ErrorActionPreference = 'Stop'; $ProgressPreference = 'SilentlyContinue';"]

# For now
RUN Enable-WindowsOptionalFeature -Online -FeatureName "MSMQ" -All -LimitAccess; \
    Enable-WindowsOptionalFeature -Online -FeatureName "MSMQ-Server" -All -LimitAccess;

# MSMQ ports
# https://support.microsoft.com/en-us/help/183293/how-to-configure-a-firewall-for-msmq-access
EXPOSE 1801/tcp 3527/udp 1801/udp 135 2101 2103 2105

# make install files accessible
COPY start.ps1 /
WORKDIR /

RUN [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12; \
        Invoke-WebRequest -Uri $env:exe -OutFile installer.exe ; \
        Start-Process -Wait -FilePath .\installer.exe -ArgumentList /qn ; \
        Remove-Item -Recurse -Force installer.exe

RUN Import-Module C:\Program` Files` `(x86`)\Particular` Software\ServiceControl` Management\ServiceControlMgmt.psd1 ;\
        New-ServiceControlInstance -Name Particular.ServiceControl -InstallPath C:\ServiceControl\Bin -DBPath C:\ServiceControl\DB -LogPath C:\ServiceControl\Logs -Port $env:port -DatabaseMaintenancePort $env:management_port -Transport $env:transport_type -ErrorQueue $env:error_queue  -AuditQueue $env:audit_queue -ForwardAuditMessages:$false -AuditRetentionPeriod $env:audit_retention -ErrorRetentionPeriod $env:error_retention; \
        Stop-Service Particular.
        
CMD .\start -transport_type $env:transport_type -Verbose        
