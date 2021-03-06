# Version  --  v1.1.4.3
###################################################################################
# Scheduled Task Details:
# Program/script: C:\Windows\System32\WindowsPowerShell\v1.0\powershell.exe
# Add arguments (optional): -MTA -File "C:\Scripts\PowerShell\Invoke-AllSpark.ps1" -scheduled -store -exit
###################################################################################
[CmdletBinding()]
Param(
	[switch]$maintenance,
	[switch]$scheduled,
	[switch]$store,
	[switch]$ceo,
	[switch]$exit
)
Write-Output "Importing AzureRM and SQL Server modules as well as custom functions..."
Import-Module SqlServer -ErrorAction Stop
Import-Module AzureRM -ErrorAction Stop
. $($PSScriptRoot + '\New-TimeStamp.ps1')
. $($PSScriptRoot + '\Set-SslCertPolicy.ps1')
. $($PSScriptRoot + '\Invoke-ErrorReport.ps1')
###################################################################################
# Hard vars
Add-Content -Value "$(Get-Date -Format 'yyyyMMdd_HHmmss') :: $($MyInvocation.MyCommand.Name) :: Start" -Path '\\MS-SSW-CRM-MGMT\Data\Ops_Log\bitc.log'
$opsLogRootPath = '\\MS-SSW-CRM-MGMT\Data\Ops_Log\AllSpark\'
$AddEjDataToSqlScript = 'C:\Scripts\PowerShell\Add-EjDataToSql.ps1'
$InvokeStoreReportScript = 'C:\Scripts\PowerShell\Invoke-StoreReport.ps1'
$InvokeCeoReportScript = 'C:\Scripts\PowerShell\Invoke-CeoReport.ps1'
$sqlServer = 'MS-SSW-CRM-SQL'
$database = '7ELE'
$sqlUser = 'sqladmin'
$sqlPass = Get-Content -Path 'C:\[censored].cred' -ErrorAction Stop
$userName = 'gpink003'
$user = $userName + '@7-11.com'
$subId = '[censored]'
$azuPass = Get-Content -Path "C:\[censored]\$userName.cred"
$credential = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $user, $(ConvertTo-SecureString -String $azuPass)
###################################################################################
# Init
If ($([System.Diagnostics.EventLog]::SourceExists('AllSpark')) -eq $false) {
	[System.Diagnostics.EventLog]::CreateEventSource('AllSpark', 'Application')
}
$eventMessage = @"
AllSpark has started with the following configuration:
maintenance = $($maintenance.IsPresent.ToString())
scheduled = $($scheduled.IsPresent.ToString())
store = $($store.IsPresent.ToString())
ceo = $($ceo.IsPresent.ToString())
exit = $($exit.IsPresent.ToString())
"@
$params = @{
	LogName = 'Application';
	Source = 'AllSpark';
	EventID = 6969;
	EntryType = 'Information';
	Message = $eventMessage;
}
Write-EventLog @params
$opsLog = $opsLogRootPath + "$(Get-Date -Format 'yyyyMMdd_HHmmss')_AllSpark.log"
If ($(Test-Path -Path $opsLogRootPath) -eq $false) {
	New-Item -Path $opsLogRootPath -ItemType Directory -ErrorAction Stop -Force > $null
}
Connect-AzureRmAccount -Subscription $subId -Credential $credential
###################################################################################
# Starting Up SQL Server
Try {
	$message = "$(New-TimeStamp)  Starting up SQL server..."
	Write-Output $message
	Add-Content -Value $message -Path $opsLog -ErrorAction Stop
	Start-AzureRmVM -ResourceGroupName "CRM-SQL" -Name "MS-SSW-CRM-SQL" -ErrorAction Stop
	$message = "$(New-TimeStamp)  Waiting 10 minutes for SQL server to warm up..."
	Write-Output $message
	Add-Content -Value $message -Path $opsLog -ErrorAction Stop
	Start-Sleep -Seconds 600
}
Catch {
	Invoke-ErrorReport -Subject 'AllSpark: SQL Server Startup Failed!!!' -log $opsLog
}
###################################################################################
# Data to SQL - Store
Try {
	If ($scheduled.IsPresent -eq $true) {
		$continue = 0
		$startTime = Get-Date -Hour 5 -Minute 50 -Second 0
		While ($continue -ne 1) {
			$now = Get-Date
			If ($now.TimeOfDay -gt $startTime.TimeOfDay) {
				$continue = 1
			}
			Else {
				Start-Sleep -Seconds 1
			}
		}
	}
	$start = Get-Date
	$message = "$(New-TimeStamp)  Adding store EJ data to SQL..."
	Write-Output $message
	Add-Content -Value $message -Path $opsLog -ErrorAction Stop
	$EtlResult = Invoke-Expression -Command "$AddEjDataToSqlScript -report 's' -autoDate" -ErrorAction Stop
	If ($EtlResult[$EtlResult.Count - 1] -ne 0) {
		$errorParams = @{
			Message = "$AddEjDataToSqlScript Failed!!!";
			ErrorId = "01";
			RecommendedAction = "Fix it.";
			ErrorAction = "Stop";
		}
		Write-Error @errorParams
	}
	$end = Get-Date
	$run = New-TimeSpan -Start $start -End $end
	$message = "$(New-TimeStamp)  Store EJ data added to SQL successfully."
	Write-Output $message
	Add-Content -Value $message -Path $opsLog -ErrorAction Stop
	$message = "$(New-TimeStamp)  Run Time: $($run.Hours.ToString('00')) h $($run.Minutes.ToString('00')) m $($run.Seconds.ToString('00')) s"
	Write-Output $message
	Add-Content -Value $message -Path $opsLog -ErrorAction Stop
}
Catch {
	Invoke-ErrorReport -Subject 'AllSpark: Add-EjDataToSql - Store Failed!!!' -log $opsLog
}
###################################################################################
# Data to SQL - CEO
Try {
	$start = Get-Date
	$message = "$(New-TimeStamp)  Adding CEO EJ data to SQL..."
	Write-Output $message
	Add-Content -Value $message -Path $opsLog -ErrorAction Stop
	$EtlResult = Invoke-Expression -Command "$AddEjDataToSqlScript -report 'c' -autoDate" -ErrorAction Stop
	If ($EtlResult[$EtlResult.Count - 1] -ne 0) {
		$errorParams = @{
			Message = "$AddEjDataToSqlScript Failed!!!";
			ErrorId = "02";
			RecommendedAction = "Fix it.";
			ErrorAction = "Stop";
		}
		Write-Error @errorParams
	}
	$end = Get-Date
	$run = New-TimeSpan -Start $start -End $end
	$message = "$(New-TimeStamp)  CEO EJ data added to SQL successfully."
	Write-Output $message
	Add-Content -Value $message -Path $opsLog -ErrorAction Stop
	$message = "$(New-TimeStamp)  Run Time: $($run.Hours.ToString('00')) h $($run.Minutes.ToString('00')) m $($run.Seconds.ToString('00')) s"
	Write-Output $message
	Add-Content -Value $message -Path $opsLog -ErrorAction Stop
}
Catch {
	Invoke-ErrorReport -Subject 'AllSpark: Add-EjDataToSql - CEO Failed!!!' -log $opsLog
}
###################################################################################
# Perform SQL Maintenance 
Try {
	If ($maintenance.IsPresent -eq $true) {
		$message = "$(New-TimeStamp)  Shrinking database log..."
		Write-Output $message
		Add-Content -Value $message -Path $opsLog -ErrorAction Stop	
		$sqlTruncateParams = @{
			query = 'EXECUTE [dbo].[usp_Shrink_Log]';
			ServerInstance = $sqlServer;
			Database = $database;
			Username = $sqlUser;
			Password = $sqlPass;
			QueryTimeout = 0;
			ErrorAction = 'Stop';
		}
		Invoke-Sqlcmd @sqlTruncateParams
###################################################################################
# Delete Old Data From Store
		$message = "$(New-TimeStamp)  Removing old data from store database..."
		Write-Output $message
		Add-Content -Value $message -Path $opsLog -ErrorAction Stop	
		$sqlTruncateParams = @{
			query = 'EXECUTE [dbo].[usp_Delete_Old_Data]';
			ServerInstance = $sqlServer;
			Database = $database;
			Username = $sqlUser;
			Password = $sqlPass;
			QueryTimeout = 0;
			ErrorAction = 'Stop';
		}
		Invoke-Sqlcmd @sqlTruncateParams
###################################################################################
# Delete Old Data From CEO
		$message = "$(New-TimeStamp)  Removing old data from CEO database..."
		Write-Output $message
		Add-Content -Value $message -Path $opsLog -ErrorAction Stop	
		$sqlTruncateParams = @{
			query = 'EXECUTE [dbo].[usp_Delete_Old_Data_CEO]';
			ServerInstance = $sqlServer;
			Database = $database;
			Username = $sqlUser;
			Password = $sqlPass;
			QueryTimeout = 0;
			ErrorAction = 'Stop';
		}
		Invoke-Sqlcmd @sqlTruncateParams
###################################################################################
# Rebuild SQL Indexs
		$message = "$(New-TimeStamp)  Rebuilding SQL indexes..."
		Write-Output $message
		Add-Content -Value $message -Path $opsLog -ErrorAction Stop	
		$sqlTruncateParams = @{
			query = 'EXECUTE [dbo].[usp_Rebuild_Indexs]';
			ServerInstance = $sqlServer;
			Database = $database;
			Username = $sqlUser;
			Password = $sqlPass;
			QueryTimeout = 0;
			ErrorAction = 'Stop';
		}
		Invoke-Sqlcmd @sqlTruncateParams
###################################################################################
# Update SQL Stats
		$message = "$(New-TimeStamp)  Updating SQL stats..."
		Write-Output $message
		Add-Content -Value $message -Path $opsLog -ErrorAction Stop	
		$sqlTruncateParams = @{
			query = 'EXECUTE [dbo].[usp_Update_Statistics]';
			ServerInstance = $sqlServer;
			Database = $database;
			Username = $sqlUser;
			Password = $sqlPass;
			QueryTimeout = 0;
			ErrorAction = 'Stop';
		}
		Invoke-Sqlcmd @sqlTruncateParams
		$message = "$(New-TimeStamp)  SQL maintenance completed successfully."
		Write-Output $message
		Add-Content -Value $message -Path $opsLog -ErrorAction Stop
	}
	$exitCode = 0
}
Catch {
	Invoke-ErrorReport -Subject 'AllSpark: SQL Maintenance Failed!!!' -log $opsLog
}
###################################################################################
# Execute Store Report
Try {
	If ($store.IsPresent -eq $true) {
		$start = Get-Date
		$message = "$(New-TimeStamp)  Executing SQL store report..."
		Write-Output $message
		Add-Content -Value $message -Path $opsLog -ErrorAction Stop
		$EtlResult = Invoke-Expression -Command "$InvokeStoreReportScript" -ErrorAction Stop
		If ($EtlResult[$EtlResult.Count - 1] -ne 0) {
			$errorParams = @{
				Message = "$InvokeStoreReportScript Failed!!!";
				ErrorId = "01";
				RecommendedAction = "Fix it.";
				ErrorAction = "Stop";
			}
			Write-Error @errorParams
		}
		$end = Get-Date
		$run = New-TimeSpan -Start $start -End $end
		$message = "$(New-TimeStamp)  SQL store report executed successfully."
		Write-Output $message
		Add-Content -Value $message -Path $opsLog -ErrorAction Stop
		$message = "$(New-TimeStamp)  Run Time: $($run.Hours.ToString('00')) h $($run.Minutes.ToString('00')) m $($run.Seconds.ToString('00')) s"
		Write-Output $message
		Add-Content -Value $message -Path $opsLog -ErrorAction Stop
	}
}
Catch {
	Invoke-ErrorReport -Subject 'AllSpark: Store Report Failed!!!' -log $opsLog
}
###################################################################################
# Execute CEO Report
Try {
	If ($ceo.IsPresent -eq $true) {
		$start = Get-Date
		$message = "$(New-TimeStamp)  Executing SQL CEO report..."
		Write-Output $message
		Add-Content -Value $message -Path $opsLog -ErrorAction Stop
		$EtlResult = Invoke-Expression -Command "$InvokeCeoReportScript" -ErrorAction Stop
		If ($EtlResult[$EtlResult.Count - 1] -ne 0) {
			$errorParams = @{
				Message = "$InvokeCeoReportScript Failed!!!";
				ErrorId = "01";
				RecommendedAction = "Fix it.";
				ErrorAction = "Stop";
			}
			Write-Error @errorParams
		}
		$end = Get-Date
		$run = New-TimeSpan -Start $start -End $end
		$message = "$(New-TimeStamp)  SQL CEO report executed successfully."
		Write-Output $message
		Add-Content -Value $message -Path $opsLog -ErrorAction Stop
		$message = "$(New-TimeStamp)  Run Time: $($run.Hours.ToString('00')) h $($run.Minutes.ToString('00')) m $($run.Seconds.ToString('00')) s"
		Write-Output $message
		Add-Content -Value $message -Path $opsLog -ErrorAction Stop
	}
}
Catch {
	Invoke-ErrorReport -Subject 'AllSpark: CEO Report Failed!!!' -log $opsLog
}
Finally {
	$message = "$(New-TimeStamp)  Shutting down SQL server..."
	Write-Output $message
	Add-Content -Value $message -Path $opsLog -ErrorAction Stop
	Select-AzureRmSubscription -Subscription $subId -ErrorAction Stop
	Stop-AzureRmVM -ResourceGroupName "CRM-SQL" -Name "MS-SSW-CRM-SQL" -ErrorAction Stop -Force
	Add-Content -Value "$(New-TimeStamp -forFileName) :: $($MyInvocation.MyCommand.Name) :: End" -Path '\\MS-SSW-CRM-MGMT\Data\Ops_Log\bitc.log'
	Add-Content -Value "----------------------------------------------------------------------------------" -Path '\\MS-SSW-CRM-MGMT\Data\Ops_Log\bitc.log'
	If ($exit.IsPresent -eq $true) {	
		[Environment]::Exit($exitCode)	
	}
}
