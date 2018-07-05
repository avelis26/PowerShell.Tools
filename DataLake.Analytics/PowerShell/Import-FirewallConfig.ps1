# v0.9.0
# info https://cwiki.apache.org/confluence/download/attachments/30753712/XML_API_Training.pdf?version=1&modificationDate=1366305635000
########################################################################################################################################
. $($PSScriptRoot + '\Set-SslCertPolicy.ps1')
[System.Net.ServicePointManager]::SecurityProtocol = [System.Net.SecurityProtocolType]::Tls12
Set-SslCertPolicy
$key = Get-Content -Path 'C:\Scripts\Secrets\firewall_key.txt'
$configUrl = "https://xxx.xxx.xxx.xxx/api/?type=import&category=configuration&key=$key"
[xml]$config = Invoke-WebRequest -Uri $configUrl
