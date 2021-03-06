# Version  --  v1.1.1.5
#######################################################################################################
#
#######################################################################################################
$startDate = '2017-02-07'
$endDate = '2017-02-11'
$7zipMod = '7zip4powershell'
$userName = 'gpink003'
$transTypes = 'D1121,D1122'
$destinationRootPath = 'D:\BIT_CRM\Hadoop\'
$archiveRootPath = '\\MS-SSW-CRM-MGMT\Data\BIT_CRM\Hadoop\'
$emailList = 'graham.pinkston@ansira.com'
$failEmailList = 'graham.pinkston@ansira.com'
Switch ($ENV:ComputerName) {
	'BITC-TMP-1' {$searchComp = 'BITC-TMP-4'}
	'BITC-TMP-2' {$searchComp = 'BITC-TMP-1'}
	'BITC-TMP-3' {$searchComp = 'BITC-TMP-2'}
	'BITC-TMP-4' {$searchComp = 'BITC-TMP-3'}
}
$searchPath = "\\MS-SSW-CRM-MGMT\Hadoop\$searchComp\"
$opsLogRootPath = "\\MS-SSW-CRM-MGMT\Hadoop\$ENV:ComputerName\"
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
Add-Content -Value "$(New-TimeStamp -forFileName) :: $($MyInvocation.MyCommand.Name) :: Start" -Path 'C:\Ops_Log\bitc.log'
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
Write-Output "$(New-TimeStamp)  Importing AzureRm, and 7Zip modules as well as custom fuctions..."
Import-Module AzureRM -ErrorAction Stop
Import-Module $7zipMod -ErrorAction Stop
. $($PSScriptRoot + '\Set-SslCertPolicy.ps1')
$range = $(New-TimeSpan -Start $startDateObj -End $endDateObj -ErrorAction Stop).Days + 1
$credential = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $user, $(ConvertTo-SecureString -String $azuPass -ErrorAction Stop) -ErrorAction Stop
While ($y -lt $range) {
	$continue = $null
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
	If ($(Test-Path -Path $archiveRootPath) -eq $false) {
		$message = "Creating $archiveRootPath..."
		Write-Output $message
		Add-Content -Value "$(New-TimeStamp)  $message" -Path $opsLog -ErrorAction Stop
		New-Item -ItemType Directory -Path $archiveRootPath -Force -ErrorAction Stop > $null
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
	Try {
		Add-Content -Value "$(New-TimeStamp)  Waiting for $searchComp to finish downloading raw files..." -Path $opsLog -ErrorAction Stop
		$found = 0
		While ($found -ne 1) {
			$file = Get-ChildItem -Path $searchPath -File | Sort-Object -Property LastWriteTime | Select-Object -Last 1
			If ($file -ne $null) {
				$content = Get-Content -Path $file.FullName
				ForEach ($line in $content) {
					If ($line -like '*Folder /BIT_CRM/* downloaded successfully.*') {
						$found = 1
					} # if
				} # foreach
			} # if
			If ($found -ne 1) {
				Start-Sleep -Seconds 8
			} # if
		} # while
		Add-Content -Value "$(New-TimeStamp)  $searchComp finished downloading raw files." -Path $opsLog -ErrorAction Stop
		$milestone_0 = Get-Date -ErrorAction Stop
		If ($(Test-Path -Path $($destinationRootPath + $processDate + '\')) -eq $true) {
			$message = "$(New-TimeStamp)  Removing folder $($destinationRootPath + $processDate + '\') ..."
			Write-Output $message
			Add-Content -Value $message -Path $opsLog -ErrorAction Stop
			Remove-Item -Path $($destinationRootPath + $processDate + '\') -Force -Recurse -ErrorAction Stop > $null
		}
		$message = "$(New-TimeStamp)  Downloading folder $($dataLakeSearchPathRoot + $processDate)..."
		Write-Output $message
		Add-Content -Value $message -Path $opsLog -ErrorAction Stop
		$exportParams = @{
			Account = $dataLakeStoreName;
			Path = $($dataLakeSearchPathRoot + $processDate);
			Destination = $($destinationRootPath + $processDate + '\');
			Force = $true;
			Concurrency = 256;
			ErrorAction = 'Stop';
		}
		Export-AzureRmDataLakeStoreItem @exportParams
		$message = "$(New-TimeStamp)  Folder $($dataLakeSearchPathRoot + $processDate) downloaded successfully."
		Write-Output $message
		Add-Content -Value $message -Path $opsLog -ErrorAction Stop
		$continue = 1
	}
	Catch {
		$continue = 0
		Add-Content -Value $($Error[0].CategoryInfo.Activity) -Path $opsLog
		Add-Content -Value $($Error[0].Exception.Message) -Path $opsLog
		Add-Content -Value $($Error[0].Exception.InnerExceptionMessage) -Path $opsLog
		Add-Content -Value $($Error[0].RecommendedAction) -Path $opsLog
		$path = 'C:\Ops_Log\ETL\Error\'
		If ($(Test-Path -Path $path) -eq $false) {
			$message = "Creating $path..."
			Write-Verbose -Message $message
			Add-Content -Value "$(New-TimeStamp)  $message" -Path $opsLog
			New-Item -ItemType Directory -Path $path -Force > $null
		}
		If ($(Test-Path -Path $($destinationRootPath + $processDate)) -eq $true) {
			$message = "$(New-TimeStamp)  Moving data to $path..."
			Write-Output $message
			Add-Content -Value $message -Path $opsLog
			Move-Item -Path $($destinationRootPath + $processDate) -Destination $path -Force
		}
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
				$($Error[0].CategoryInfo.Activity)<br>
				$($Error[0].Exception.Message)<br>
				$($Error[0].Exception.InnerExceptionMessage)<br>
				$($Error[0].RecommendedAction)<br>
				$($Error[0].Message)<br>
				</font>
"@
		}
		Send-MailMessage @params
		Set-Content -Value $(New-TimeStamp) -Path $($path + $processDate + '.log')
		Add-Content -Value $($Error[0].CategoryInfo.Activity) -Path $($path + $processDate + '.log')
		Add-Content -Value $($Error[0].Exception.Message) -Path $($path + $processDate + '.log')
		Add-Content -Value $($Error[0].Exception.InnerExceptionMessage) -Path $($path + $processDate + '.log')
		Add-Content -Value $($Error[0].RecommendedAction) -Path $($path + $processDate + '.log')
	}
# Seperate files into 5 folders and decompress in parallel
	If ($continue -eq 1) {
		$continue = $null
		Try {
			$milestone_1 = Get-Date -ErrorAction Stop
			$fileCount = $null
			$files = Get-ChildItem -Path $($destinationRootPath + $processDate + '\') -File -ErrorAction Stop
			$fileCount = $files.Count.ToString()
			$message = "$(New-TimeStamp)  Found $fileCount total files..."
			Write-Output $message
			Add-Content -Value $message -Path $opsLog -ErrorAction Stop
			$i = 1
			$count = 5
			$folderPreFix = 'bucket_'
			While ($i -lt $($count + 1)) {
				$dirName = $folderPreFix + $i
				$dirPath = $($destinationRootPath + $processDate + '\') + $dirName
				If ($(Test-Path -Path $dirPath) -eq $false) {
					$message = "$(New-TimeStamp)  Creating folder:  $dirPath ..."
					Write-Output $message
					New-Item -ItemType Directory -Path $dirPath -Force -ErrorAction Stop > $null
				}
				Else {
					Get-ChildItem -Path $dirPath -Recurse -ErrorAction Stop | Remove-Item -Force -ErrorAction Stop
				}
				$i++
			}
			[int]$divider = $($files.Count / $count) - 0.5
			$i = 0
			$message = "$(New-TimeStamp)  Separating files into bucket folders..."
			Write-Output $message
			Add-Content -Value $message -Path $opsLog -ErrorAction Stop
			While ($i -lt $($files.Count)) {
				If ($i -lt $divider) {
					$movePath = $($destinationRootPath + $processDate + '\') + $folderPreFix + '1'
				}
				ElseIf ($i -ge $divider -and $i -lt $($divider * 2)) {
					$movePath = $($destinationRootPath + $processDate + '\') + $folderPreFix + '2'
				}
				ElseIf ($i -ge $($divider * 2) -and $i -lt $($divider * 3)) {
					$movePath = $($destinationRootPath + $processDate + '\') + $folderPreFix + '3'
				}
				ElseIf ($i -ge $($divider * 3) -and $i -lt $($divider * 4)) {
					$movePath = $($destinationRootPath + $processDate + '\') + $folderPreFix + '4'
				}
				Else {
					$movePath = $($destinationRootPath + $processDate + '\') + $folderPreFix + '5'
				}
				Move-Item -Path $files[$i].FullName -Destination $movePath -Force -ErrorAction Stop
				$i++
			}
			$folders = Get-ChildItem -Path $($destinationRootPath + $processDate + '\') -Directory -ErrorAction Stop
			$jobI = 0
			$jobBaseName = 'unzip_job_'
			ForEach ($folder in $folders) {
				$block = {
					Try {
						[System.Threading.Thread]::CurrentThread.Priority = 'Highest'
						$ProgressPreference = 'SilentlyContinue'
						Import-Module $args[1] -ErrorAction Stop
						$files = Get-ChildItem -Path $args[0] -Filter '*.gz' -File -ErrorAction Stop
						ForEach ($file in $files) {
							Expand-7Zip -ArchiveFileName $($file.FullName) -TargetPath $args[0] -ErrorAction Stop > $null
							Remove-Item -Path $($file.FullName) -Force -ErrorAction Stop > $null
						}
						Return 'pass'
					}
					Catch {
						Return 'fail'
					}
				}
				$message = "$(New-TimeStamp)  Starting decompress job:  $($folder.FullName)..."
				Write-Output $message
				Add-Content -Value $message -Path $opsLog -ErrorAction Stop
				Start-Job -ScriptBlock $block -ArgumentList $($folder.FullName), $7zipMod -Name $($jobBaseName + $jobI.ToString()) -ErrorAction Stop
				$jobI++
			}
			Write-Output "$(New-TimeStamp)  Spliting and decompressing..."
			$r = 0
			While ($r -lt $($folders.Count)) {
				$message = "$(New-TimeStamp)  Waiting for decompress job: $($jobBaseName + $r.ToString())..."
				Write-Output $message
				Add-Content -Value $message -Path $opsLog -ErrorAction Stop
				Get-Job -Name $($jobBaseName + $r.ToString()) -ErrorAction Stop | Wait-Job -ErrorAction Stop
				$message = "$(New-TimeStamp)  Receiving job $($jobBaseName + $r.ToString())..."
				Write-Output $message
				Add-Content -Value $message -Path $opsLog -ErrorAction Stop
				$dJobResult = $null
				$dJobResult = Receive-Job -Name $($jobBaseName + $r.ToString()) -ErrorAction Stop
				If ($dJobResult -ne 'pass') {
					$errorParams = @{
						Message = "Decompression Failed!!!";
						ErrorId = "44";
						RecommendedAction = "Check ops log and GZ files.";
						ErrorAction = "Stop";
					}
					Write-Error @errorParams
				}
				Remove-Job -Name $($jobBaseName + $r.ToString()) -ErrorAction Stop
				$r++
			}
			$continue = 1
		} # try
		Catch {
			$continue = 0
			Add-Content -Value $($Error[0].CategoryInfo.Activity) -Path $opsLog -ErrorAction Stop
			Add-Content -Value $($Error[0].Exception.Message) -Path $opsLog -ErrorAction Stop
			Add-Content -Value $($Error[0].Exception.InnerExceptionMessage) -Path $opsLog -ErrorAction Stop
			Add-Content -Value $($Error[0].RecommendedAction) -Path $opsLog -ErrorAction Stop
			$path = 'C:\Ops_Log\ETL\Error\'
			If ($(Test-Path -Path $path) -eq $false) {
				$message = "Creating $path..."
				Write-Verbose -Message $message
				Add-Content -Value "$(New-TimeStamp)  $message" -Path $opsLog -ErrorAction Stop
				New-Item -ItemType Directory -Path $path -Force -ErrorAction Stop > $null
			}
			If ($(Test-Path -Path $($destinationRootPath + $processDate)) -eq $true) {
				$message = "$(New-TimeStamp)  Moving data to $path..."
				Write-Output $message
				Add-Content -Value $message -Path $opsLog -ErrorAction Stop
				Move-Item -Path $($destinationRootPath + $processDate) -Destination $path -Force -ErrorAction Stop
			}
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
					$($Error[0].CategoryInfo.Activity)<br>
					$($Error[0].Exception.Message)<br>
					$($Error[0].Exception.InnerExceptionMessage)<br>
					$($Error[0].RecommendedAction)<br>
					$($Error[0].Message)<br>
					</font>
"@
			}
			Send-MailMessage @params
			Set-Content -Value $(New-TimeStamp) -Path $($path + $processDate + '.log')
			Add-Content -Value $($Error[0].CategoryInfo.Activity) -Path $($path + $processDate + '.log')
			Add-Content -Value $($Error[0].Exception.Message) -Path $($path + $processDate + '.log')
			Add-Content -Value $($Error[0].Exception.InnerExceptionMessage) -Path $($path + $processDate + '.log')
			Add-Content -Value $($Error[0].RecommendedAction) -Path $($path + $processDate + '.log')
		} # catch
	} # if
# Execute C# app as job on raw files to create CSV's
	If ($continue -eq 1) {
		$continue = $null
		Try {
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
			$continue = 1
		} # try
		Catch {
			$continue = 0
			Add-Content -Value $($Error[0].CategoryInfo.Activity) -Path $opsLog -ErrorAction Stop
			Add-Content -Value $($Error[0].Exception.Message) -Path $opsLog -ErrorAction Stop
			Add-Content -Value $($Error[0].Exception.InnerExceptionMessage) -Path $opsLog -ErrorAction Stop
			Add-Content -Value $($Error[0].RecommendedAction) -Path $opsLog -ErrorAction Stop
			$path = 'C:\Ops_Log\ETL\Error\'
			If ($(Test-Path -Path $path) -eq $false) {
				$message = "Creating $path..."
				Write-Verbose -Message $message
				Add-Content -Value "$(New-TimeStamp)  $message" -Path $opsLog -ErrorAction Stop
				New-Item -ItemType Directory -Path $path -Force -ErrorAction Stop > $null
			}
			If ($(Test-Path -Path $($destinationRootPath + $processDate)) -eq $true) {
				$message = "$(New-TimeStamp)  Moving data to $path..."
				Write-Output $message
				Add-Content -Value $message -Path $opsLog -ErrorAction Stop
				Move-Item -Path $($destinationRootPath + $processDate) -Destination $path -Force -ErrorAction Stop
			}
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
					$($Error[0].CategoryInfo.Activity)<br>
					$($Error[0].Exception.Message)<br>
					$($Error[0].Exception.InnerExceptionMessage)<br>
					$($Error[0].RecommendedAction)<br>
					$($Error[0].Message)<br>
					</font>
"@
			}
			Send-MailMessage @params
			Set-Content -Value $(New-TimeStamp) -Path $($path + $processDate + '.log')
			Add-Content -Value $($Error[0].CategoryInfo.Activity) -Path $($path + $processDate + '.log')
			Add-Content -Value $($Error[0].Exception.Message) -Path $($path + $processDate + '.log')
			Add-Content -Value $($Error[0].Exception.InnerExceptionMessage) -Path $($path + $processDate + '.log')
			Add-Content -Value $($Error[0].RecommendedAction) -Path $($path + $processDate + '.log')
		} # catch
	} # if
# Upload CSV's to blob storage
	If ($continue -eq 1) {
		$continue = $null
		Try {
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
			} # foreach
			$continue = 1
		} # try
		Catch {
			$continue = 0
			Add-Content -Value $($Error[0].CategoryInfo.Activity) -Path $opsLog -ErrorAction Stop
			Add-Content -Value $($Error[0].Exception.Message) -Path $opsLog -ErrorAction Stop
			Add-Content -Value $($Error[0].Exception.InnerExceptionMessage) -Path $opsLog -ErrorAction Stop
			Add-Content -Value $($Error[0].RecommendedAction) -Path $opsLog -ErrorAction Stop
			$path = 'C:\Ops_Log\ETL\Error\'
			If ($(Test-Path -Path $path) -eq $false) {
				$message = "Creating $path..."
				Write-Verbose -Message $message
				Add-Content -Value "$(New-TimeStamp)  $message" -Path $opsLog -ErrorAction Stop
				New-Item -ItemType Directory -Path $path -Force -ErrorAction Stop > $null
			}
			If ($(Test-Path -Path $($destinationRootPath + $processDate)) -eq $true) {
				$message = "$(New-TimeStamp)  Moving data to $path..."
				Write-Output $message
				Add-Content -Value $message -Path $opsLog -ErrorAction Stop
				Move-Item -Path $($destinationRootPath + $processDate) -Destination $path -Force -ErrorAction Stop
			}
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
					$($Error[0].CategoryInfo.Activity)<br>
					$($Error[0].Exception.Message)<br>
					$($Error[0].Exception.InnerExceptionMessage)<br>
					$($Error[0].RecommendedAction)<br>
					$($Error[0].Message)<br>
					</font>
"@
			}
			Send-MailMessage @params
			Set-Content -Value $(New-TimeStamp) -Path $($path + $processDate + '.log')
			Add-Content -Value $($Error[0].CategoryInfo.Activity) -Path $($path + $processDate + '.log')
			Add-Content -Value $($Error[0].Exception.Message) -Path $($path + $processDate + '.log')
			Add-Content -Value $($Error[0].Exception.InnerExceptionMessage) -Path $($path + $processDate + '.log')
			Add-Content -Value $($Error[0].RecommendedAction) -Path $($path + $processDate + '.log')
		} # catch
	} # if
# Delete data from temp drive
	$milestone_4 = Get-Date
<#
	$message = "$(New-TimeStamp)  Deleting $($destinationRootPath + $processDate)..."
	Write-Output $message
	Add-Content -Value $message -Path $opsLog -ErrorAction Stop
	Remove-Item -Path $($destinationRootPath + $processDate) -Recurse -Force -ErrorAction Stop
#>
	If ($(Test-Path -Path $($archiveRootPath + $processDate)) -eq $true) {
		Add-Content -Value "$(New-TimeStamp)  Removing folder: $($archiveRootPath + $processDate)..." -Path $opsLog -ErrorAction Stop
		Remove-Item -Path $($archiveRootPath + $processDate) -Recurse -Force -ErrorAction Stop
		Add-Content -Value "$(New-TimeStamp)  Folder removed successfully." -Path $opsLog -ErrorAction Stop
	}
	Add-Content -Value "$(New-TimeStamp)  Moving $($destinationRootPath + $processDate) to archive: $($archiveRootPath + $processDate)..." -Path $opsLog -ErrorAction Stop
	Move-Item -Path $($destinationRootPath + $processDate) -Destination $archiveRootPath -Force -ErrorAction Stop
# Send report
	If ($continue -eq 1) {
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
		} # params
		Send-MailMessage @params
		Add-Content -Value '::ETL SUCCESSFUL::' -Path $opsLog -ErrorAction Stop
	} # if
	Start-Sleep -Milliseconds 256
	$y++
} # while
If ($range -gt 1) {
	$params = @{
		SmtpServer = $smtpServer;
		Port = $port;
		UseSsl = 0;
		From = $fromAddr;
		To = 'graham.pinkston@ansira.com';
		BodyAsHtml = $true;
		Subject = "AllSpark: Hadoop ETL Process Finished For Range $startDate - $endDate With No Error";
		Body = "Queue up the next range."
	}
	Send-MailMessage @params
}
Get-Job | Remove-Job -Force
Add-Content -Value "$(New-TimeStamp -forFileName) :: $($MyInvocation.MyCommand.Name) :: End" -Path 'C:\Ops_Log\bitc.log'
