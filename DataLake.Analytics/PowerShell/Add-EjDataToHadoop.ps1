# Version  --  v1.0.3.0
#######################################################################################################
#
#######################################################################################################
[CmdletBinding()]
Param(
	[switch]$autoDate,
	[switch]$test
)
Write-Output "Importing AzureRm and 7Zip modules as well as custom fuctions..."
Import-Module AzureRM -ErrorAction Stop
Import-Module 7Zip4powershell -ErrorAction Stop
. $($PSScriptRoot + '\Set-SslCertPolicy.ps1')
. $($PSScriptRoot + '\Get-DataLakeRawFiles.ps1')
. $($PSScriptRoot + '\Expand-FilesInParallel.ps1')
. $($PSScriptRoot + '\Split-FilesAmongFolders.ps1')
If ($autoDate.IsPresent -eq $true) {
	$startDate = $endDate = $(Get-Date).Year.ToString('0000') + '-' + $(Get-Date).Month.ToString('00') + '-' + $(Get-Date).Day.ToString('00')
}
Else {
	$startDate = '1984-08-13'
	$endDate = '1984-08-13'
}
If ($test.IsPresent -eq $true) {
	$emailList = 'graham.pinkston@ansira.com'
	$failEmailList = 'graham.pinkston@ansira.com'
	$opsLogRootPath = '\\MS-SSW-CRM-MGMT\Data\Ops_Log\ETL\Hadoop\Test\'
}
Else {
	[string[]]$emailList = 'Catherine.Wells@Ansira.com', 'Britten.Morse@Ansira.com', 'megan.morace@ansira.com', 'mayank.minawat@ansira.com', 'Cheong.Sin@Ansira.com', 'Graham.Pinkston@Ansira.com', 'Geri.Shaeffer@Ansira.com'
	[string[]]$failEmailList = $emailList
	$opsLogRootPath = '\\MS-SSW-CRM-MGMT\Data\Ops_Log\ETL\Hadoop\'
}
$userName = 'gpink003'
$transTypes = 'D1121,D1122'
$destinationRootPath = 'D:\BIT_CRM\Hadoop\'
$dataLakeSubId = 'ee691273-18af-4600-bc24-eb6768bf9cfa'
$smtpServer = '10.128.1.125'
$port = 25
$fromAddr = 'noreply@7-11.com'
$azuPass = Get-Content -Path "C:\Scripts\Secrets\$userName.cred" -ErrorAction Stop
$user = $userName + '@7-11.com'
$dataLakeSearchPathRoot = '/BIT_CRM/'
$dataLakeStoreName = '711dlprodcons01'
$bumblebee = 'C:\Scripts\C#\Bumblebee\Ansira.Sel.Bitc.Bumblebee.exe'
$optimus = 'C:\Scripts\C#\Optimus\Hadoop\Ansira.Sel.BITC.DataExtract.Optimus.exe'
$121blobPath = 'bitc/121header/'
$122blobPath = 'bitc/122detail/'
$y = 0
#######################################################################################################
Function New-TimeStamp {
	[CmdletBinding()]
	Param(
		[switch]$forFileName
	)
	If ($forFileName -eq $true) {
		$timeStamp = Get-Date -Format 'yyyyMMdd_HHmmss' -ErrorAction Stop
	}
	Else {
		$timeStamp = Get-Date -Format 'yyyy/MM/dd_HH:mm:ss' -ErrorAction Stop
	}
	Return $timeStamp
}
Add-Content -Value "$(New-TimeStamp -forFileName) :: $($MyInvocation.MyCommand.Name) :: Start" -Path '\\MS-SSW-CRM-MGMT\Data\Ops_Log\bitc.log'
# Init
[System.Threading.Thread]::CurrentThread.Priority = 'Highest'
$startDateObj = Get-Date -Date $startDate -ErrorAction Stop
$endDateObj = Get-Date -Date $endDate -ErrorAction Stop
Write-Host '********************************************************************' -ForegroundColor Magenta
Write-Host "Start Date    ::  $startDate"
Write-Host "End Date      ::  $endDate"
Write-Host "Transactions  ::  $transTypes"
Write-Host '********************************************************************' -ForegroundColor Magenta
Write-Host "Starting script in 5..."
Start-Sleep -Seconds 1
Write-Host "4..."
Start-Sleep -Seconds 1
Write-Host "3..."
Start-Sleep -Seconds 1
Write-Host "2..."
Start-Sleep -Seconds 1
Write-Host "1..."
Start-Sleep -Seconds 1
Try {
	$range = $(New-TimeSpan -Start $startDateObj -End $endDateObj -ErrorAction Stop).Days + 1
	$credential = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $user, $(ConvertTo-SecureString -String $azuPass -ErrorAction Stop) -ErrorAction Stop
	While ($y -lt $range) {
		$startTime = Get-Date -ErrorAction Stop
		$startTimeText = $(New-TimeStamp -forFileName)
		$day = $($startDateObj.AddDays($y)).day.ToString("00")
		$month = $($startDateObj.AddDays($y)).month.ToString("00")
		$year = $($startDateObj.AddDays($y)).year.ToString("0000")
		$processDate = $year + $month + $day
		$opsLog = $opsLogRootPath + $processDate + '_' + $startTimeText + '_BITC.log'
		If ($(Test-Path -Path $opsLogRootPath) -eq $false) {
			Write-Output "Creating $opsLogRootPath..."
			New-Item -ItemType Directory -Path $opsLogRootPath -Force -ErrorAction Stop > $null
			Add-Content -Value "$(New-TimeStamp)  Process Date: $processDate" -Path $opsLog -ErrorAction Stop
			Add-Content -Value "$(New-TimeStamp)  Created folder: $opsLogRootPath" -Path $opsLog -ErrorAction Stop
		}
		Else {
			Add-Content -Value "$(New-TimeStamp)  Process Date: $processDate" -Path $opsLog -ErrorAction Stop
		}
		If ($(Test-Path -Path $destinationRootPath) -eq $false) {
			$message = "Creating $destinationRootPath..."
			Write-Output $message
			Add-Content -Value "$(New-TimeStamp)  $message" -Path $opsLog -ErrorAction Stop
			New-Item -ItemType Directory -Path $destinationRootPath -Force -ErrorAction Stop > $null
		}
		$policy = [System.Net.ServicePointManager]::CertificatePolicy.ToString()
		Add-Content -Value "$(New-TimeStamp)  SSL Policy: $policy" -Path $opsLog -ErrorAction Stop
		Set-SslCertPolicy
		$policy = [System.Net.ServicePointManager]::CertificatePolicy.ToString()
		Add-Content -Value "$(New-TimeStamp)  SSL Policy: $policy" -Path $opsLog -ErrorAction Stop
		$message = "Logging into Azure..."
		Write-Output $message
		Add-Content -Value "$(New-TimeStamp)  $message" -Path $opsLog -ErrorAction Stop
		Login-AzureRmAccount -Credential $credential -Subscription $dataLakeSubId -Force -ErrorAction Stop
		$message = "Login successful."
		Write-Output $message
		Add-Content -Value "$(New-TimeStamp)  $message" -Path $opsLog -ErrorAction Stop
# Get raw files
		$retry = 0
		While ($retry -lt 3) {
			Try {
				$milestone_0 = Get-Date -ErrorAction Stop
				Get-DataLakeRawFiles -dataLakeStoreName $dataLakeStoreName -destination $($destinationRootPath + $processDate + '\') -source $($dataLakeSearchPathRoot + $processDate) -log $opsLog
				$fileCount = $(Get-ChildItem -Path $($destinationRootPath + $processDate + '\') -File).Count
# Seperate files into 5 seperate folders for paralell processing
				$milestone_1 = Get-Date
				Split-FilesAmongFolders -rootPath $($destinationRootPath + $processDate + '\') -log $opsLog
# Decompress files in parallel
				Expand-FilesInParallel -rootPath $($destinationRootPath + $processDate + '\') -log $opsLog
				$retry = 3
			}
			Catch {
				Tee-Object -FilePath $opsLog -Append -ErrorAction Stop -InputObject "$(New-TimeStamp)  $($Error[0].Message)."
				$retry++
				If ($retry -eq 3) {
					$errorParams = @{
						Message = "$($Error[0].Message)";
						ErrorId = "69";
						ErrorAction = "Stop";
					}
					Write-Error @errorParams
				}
			}
		}
# Execute C# app as job on raw files to create CSV's
		$milestone_2 = Get-Date
		$folders = Get-ChildItem -Path $($destinationRootPath + $processDate + '\') -Directory -ErrorAction Stop
		ForEach ($folder in $folders) {
			$outputPath = $($folder.Parent.FullName) + '\' + $($folder.Name) + '_Output\'
			If ($(Test-Path -Path $outputPath) -eq $false) {
				$message = "$(New-TimeStamp)  Creating folder:  $outputPath ..."
				Write-Output $message
				Add-Content -Value $message -Path $opsLog -ErrorAction Stop
				New-Item -ItemType Directory -Path $outputPath -Force -ErrorAction Stop > $null
			}
			$block = {
				[System.Threading.Thread]::CurrentThread.Priority = 'Highest'
				& $args[0] $args[1..4];
				Remove-Item -Path $($args[1]) -Recurse -Force -ErrorAction Stop;
			}
			$message = "$(New-TimeStamp)  Starting convert job:  $($folder.FullName)..."
			Write-Output $message
			Add-Content -Value $message -Path $opsLog -ErrorAction Stop
			Start-Job -ScriptBlock $block -ArgumentList "$optimus", "$($folder.FullName)", "$outputPath", "$transTypes", "$($processDate)_$($folder.Name)" -ErrorAction Stop
			Start-Sleep -Milliseconds 128
		}
		Write-Output "$(New-TimeStamp)  Converting..."
		Get-Job | Wait-Job
		Get-Job | Remove-Job -ErrorAction Stop
		Add-Content -Value "$(New-TimeStamp)  Optimus Report:" -Path $opsLog -ErrorAction Stop
		$folders = Get-ChildItem -Path $($destinationRootPath + $processDate + '\') -Directory -ErrorAction Stop
		ForEach ($folder in $folders) {
			$outputFile = Get-ChildItem -Path $($folder.FullName) -Recurse -File -Filter "*output*" -ErrorAction Stop
			$jsonObj = Get-Content -Raw -Path $outputFile.FullName -ErrorAction Stop | ConvertFrom-Json -ErrorAction Stop
			If ($jsonObj.ResponseCode -ne 0) {
				[string]$optimusError = $jsonObj.ResponseMsg
				$errorParams = @{
					Message = "Optimus Failed: $optimusError";
					ErrorId = "$($jsonObj.ResponseCode)";
					RecommendedAction = "Check ops log.";
					ErrorAction = "Stop";
				}
				Write-Error @errorParams
			}
			Else {
				Add-Content -Value "$($folder.FullName)" -Path $opsLog -ErrorAction Stop
				Add-Content -Value "TotalNumRecords: $($jsonObj.TotalNumRecords)" -Path $opsLog -ErrorAction Stop
				Add-Content -Value "TotalNumFiles: $($jsonObj.TotalNumFiles)" -Path $opsLog -ErrorAction Stop
				Add-Content -Value "------------------------------------------------------------------------------------------------------" -Path $opsLog -ErrorAction Stop
			}
		}
# Upload CSV's to blob storage
		$milestone_3 = Get-Date
		$files = Get-ChildItem -Path $($destinationRootPath + $processDate + '\') -Recurse -Filter "*Structured*" -File -ErrorAction Stop
		ForEach ($file in $files) {
			If ($file.Name -like "*D1_121*") {
				$destination = $121blobPath
			}
			ElseIF ($file.Name -like "*D1_122*") {
				$destination = $122blobPath
			}
			Else {
				$errorParams = @{
					Message = "ERROR: File name: $($file.FullName) doesn't match any defined pattern!!!";
					ErrorId = "999";
					RecommendedAction = "Fix it.";
					ErrorAction = "Stop";
				}
				Write-Error @errorParams
			}
			$command = "& $bumblebee $($file.FullName) $destination"
			$message = "$(New-TimeStamp)  Sending To Blob:  $command"
			Write-Output $message
			Add-Content -Value $message -Path $opsLog -ErrorAction Stop
			$result = Invoke-Expression -Command $command -ErrorAction Stop
			If ($result[$result.Count - 1] -notLike "*Successfully*") {
				$errorParams = @{
					Message = "ERROR: Bumblebee failed to upload $($file.FullName)!!!";
					ErrorId = "888";
					RecommendedAction = "Fix it.";
					ErrorAction = "Stop";
				}
				Write-Error @errorParams
			}
			$message = "$(New-TimeStamp)  File uploaded successfully."
			Write-Output $message
			Add-Content -Value $message -Path $opsLog -ErrorAction Stop
		}
# Delete data from temp drive
		$milestone_4 = Get-Date
		$message = "$(New-TimeStamp)  Deleting $($destinationRootPath + $processDate)..."
		Write-Output $message
		Add-Content -Value $message -Path $opsLog -ErrorAction Stop
		Remove-Item -Path $($destinationRootPath + $processDate) -Recurse -Force -ErrorAction Stop
# Send report
		$endTime = Get-Date
		$endTimeText = $(New-TimeStamp -forFileName)
		$iniTime = New-TimeSpan -Start $startTime -End $milestone_0
		$rawTime = New-TimeSpan -Start $milestone_0 -End $milestone_1
		$sepTime = New-TimeSpan -Start $milestone_1 -End $milestone_2
		$exeTime = New-TimeSpan -Start $milestone_2 -End $milestone_3
		$uplTime = New-TimeSpan -Start $milestone_3 -End $milestone_4
		$cleTime = New-TimeSpan -Start $milestone_4 -End $endTime
		$totTime = New-TimeSpan -Start $startTime -End $endTime
		$message02 = "Start Time--------:  $startTimeText"
		$message03 = "End Time----------:  $endTimeText"
		$message04 = "Initialization----:  $($iniTime.Hours.ToString("00")) h $($iniTime.Minutes.ToString("00")) m $($iniTime.Seconds.ToString("00")) s"
		$message05 = "Raw File Download-:  $($rawTime.Hours.ToString("00")) h $($rawTime.Minutes.ToString("00")) m $($rawTime.Seconds.ToString("00")) s"
		$message06 = "Decompression-----:  $($sepTime.Hours.ToString("00")) h $($sepTime.Minutes.ToString("00")) m $($sepTime.Seconds.ToString("00")) s"
		$message07 = "File Processing---:  $($exeTime.Hours.ToString("00")) h $($exeTime.Minutes.ToString("00")) m $($exeTime.Seconds.ToString("00")) s"
		$message08 = "CSV File Upload---:  $($uplTime.Hours.ToString("00")) h $($uplTime.Minutes.ToString("00")) m $($uplTime.Seconds.ToString("00")) s"
		$message09 = "Cleanup-----------:  $($cleTime.Hours.ToString("00")) h $($cleTime.Minutes.ToString("00")) m $($cleTime.Seconds.ToString("00")) s"
		$message10 = "Total Run Time----:  $($totTime.Hours.ToString("00")) h $($totTime.Minutes.ToString("00")) m $($totTime.Seconds.ToString("00")) s"
		$message11 = "Total File Count--:  $fileCount"
		Write-Output $message02
		Write-Output $message03
		Write-Output $message04
		Write-Output $message05
		Write-Output $message06
		Write-Output $message07
		Write-Output $message08
		Write-Output $message09
		Write-Output $message10
		Write-Output $message11
		Add-Content -Value $message02 -Path $opsLog -ErrorAction Stop
		Add-Content -Value $message03 -Path $opsLog -ErrorAction Stop
		Add-Content -Value $message04 -Path $opsLog -ErrorAction Stop
		Add-Content -Value $message05 -Path $opsLog -ErrorAction Stop
		Add-Content -Value $message06 -Path $opsLog -ErrorAction Stop
		Add-Content -Value $message07 -Path $opsLog -ErrorAction Stop
		Add-Content -Value $message08 -Path $opsLog -ErrorAction Stop
		Add-Content -Value $message09 -Path $opsLog -ErrorAction Stop
		Add-Content -Value $message10 -Path $opsLog -ErrorAction Stop
		Add-Content -Value $message11 -Path $opsLog -ErrorAction Stop
		$params = @{
			SmtpServer = $smtpServer;
			Port = $port;
			UseSsl = 0;
			From = $fromAddr;
			To = $emailList;
			BodyAsHtml = $true;
			Subject = "AllSpark: $($processDate): Hadoop ETL Process Finished";
			Body = @"
				Optimus has processed the raw files from<b> $($dataLakeSearchPathRoot + $processDate) </b>and uploaded them to blob storage for hadoop.<br>
				<br>
				<font face='courier'>
				$message02<br>
				$message03<br>
				$message04<br>
				$message05<br>
				$message06<br>
				$message07<br>
				$message08<br>
				$message09<br>
				$message10<br>
				$message11<br>
				</font>
"@
		}
		Send-MailMessage @params
		Add-Content -Value '::ETL SUCCESSFUL::' -Path $opsLog -ErrorAction Stop
		$y++
		If ($y -lt $range) {
			Write-Output "Starting next day in 10..."
			Start-Sleep -Seconds 1
			Write-Output "9..."
			Start-Sleep -Seconds 1
			Write-Output "8..."
			Start-Sleep -Seconds 1
			Write-Output "7..."
			Start-Sleep -Seconds 1
			Write-Output "6..."
			Start-Sleep -Seconds 1
			Write-Output "5..."
			Start-Sleep -Seconds 1
			Write-Output "4..."
			Start-Sleep -Seconds 1
			Write-Output "3..."
			Start-Sleep -Seconds 1
			Write-Output "2..."
			Start-Sleep -Seconds 1
			Write-Output "1..."
			Start-Sleep -Milliseconds 400
			Write-Output "Too late :P"
			Start-Sleep -Milliseconds 256
		}
	} # while
	$exitCode = 0
} # try
Catch {
	Tee-Object -FilePath $opsLog -Append -ErrorAction Stop -InputObject $($Error[0].Message)
	Tee-Object -FilePath $opsLog -Append -ErrorAction Stop -InputObject $($_.Exception.Message)
	Tee-Object -FilePath $opsLog -Append -ErrorAction Stop -InputObject $($_.Exception.InnerException.Message)
	Tee-Object -FilePath $opsLog -Append -ErrorAction Stop -InputObject $($_.Exception.InnerException.InnerException.Message)
	Tee-Object -FilePath $opsLog -Append -ErrorAction Stop -InputObject $($_.CategoryInfo.Activity)
	Tee-Object -FilePath $opsLog -Append -ErrorAction Stop -InputObject $($_.CategoryInfo.Reason)
	Tee-Object -FilePath $opsLog -Append -ErrorAction Stop -InputObject $($_.InvocationInfo.Line)
	$params = @{
		SmtpServer = $smtpServer;
		Port = $port;
		UseSsl = 0;
		From = $fromAddr;
		To = $failEmailList;
		BodyAsHtml = $true;
		Subject = "AllSpark: ::ERROR:: ETL Failed For $processDate!!!";
		Body = @"
			<font face='consolas'>
			Something bad happened!!!<br><br>
			$($Error[0].Message)<br>
			$($_.Exception.Message)<br>
			$($_.Exception.InnerException.Message)<br>
			$($_.Exception.InnerException.InnerException.Message)<br>
			$($_.CategoryInfo.Activity)<br>
			$($_.CategoryInfo.Reason)<br>
			$($_.InvocationInfo.Line)<br>
			</font>
"@
	}
	Send-MailMessage @params
	$exitCode = 1
}
Finally {
	Write-Output 'Finally...'
	Get-Job | Remove-Job -Force
	Remove-Item -Path $destinationRootPath -Recurse -Force -ErrorAction SilentlyContinue
	Add-Content -Value "$(New-TimeStamp -forFileName) :: $($MyInvocation.MyCommand.Name) :: End" -Path '\\MS-SSW-CRM-MGMT\Data\Ops_Log\bitc.log'
}
Return $exitCode
