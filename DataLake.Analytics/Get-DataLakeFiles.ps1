$VerbosePreference = 'Continue'
Import-Module AzureRM
$password = Get-Content "C:\Users\graham.pinkston\Documents\Secrets\op1.txt" | ConvertTo-SecureString
$user = "gpink003@7-11.com"
$credential = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $user, $password
$seiDataLakeName = '711dlprodcons01'
$ansiraDataLakeName = 'mscrmprodadls'
$targetFolder = '20171129'
$dataLakeRootPath = "/BIT_CRM/$targetFolder/"
$destinationRootPath = 'C:\Temp\'
$i = 0
Try {
	Write-Verbose -Message 'Logging into Azure...'
	Login-AzureRmAccount -ErrorAction Stop
	Write-Verbose -Message 'Setting subscription...'
	Set-AzureRmContext -Subscription 'ee691273-18af-4600-bc24-eb6768bf9cfa' -ErrorAction Stop
	Write-Verbose -Message "Getting list of files in $dataLakeRootPath ..."
	$dataLakeFiles = Get-AzureRmDataLakeStoreChildItem -Account $seiDataLakeName -Path $dataLakeRootPath -ErrorAction Stop
	Write-Verbose -Message "$($dataLakeFiles.Length) files found..."
	$percent = $($i/$($dataLakeFiles.Length)*100)
	If (!(Test-Path -LiteralPath $destinationRootPath)) {
		Write-Verbose -Message "Creating folder:  $destinationRootPath ..."
		New-Item -ItemType Directory -Path $destinationRootPath -Force
	}
	ForEach ($file in $dataLakeFiles) {
		Write-Progress -Activity 'Downloading files...' -Status "$($percent.ToString("##"))% Complete:" -PercentComplete $percent
		Export-AzureRmDataLakeStoreItem -Account $seiDataLakeName -Path $file.Path -Destination $($destinationRootPath + $targetFolder + '\' + $($file.Name))
		$i++
	}
}
Catch {
	throw $_
}