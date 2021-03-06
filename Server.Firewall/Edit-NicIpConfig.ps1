#Install-Module AzureRM -AllowClobber -Force
Update-Module -Name AzureRM
Import-Module AzureRM
$password = Get-Content "C:\Users\graham.pinkston\Documents\Secrets\op1.txt" | ConvertTo-SecureString
$user = "gpink003@7-11.com"
$credential = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $user, $password
Login-AzureRmAccount -Credential $credential
Set-AzureRmContext -Subscription 'da908b26-f6f8-4d61-bf60-b774ff3087ec'
$vmList = Get-AzureRmVM | Where-Object -FilterScript {$_.Name -like "mssslcrmfw*"}
ForEach ($vm in $vmList) {
	$nics = $vm.NetworkProfile.NetworkInterfaces
	ForEach ($nic in $nics) {
		$nicName = [regex]::Split($nic.Id, '^.+\/(.+)$')
		$nicObj = Get-AzureRmNetworkInterface -Name $nicName -ResourceGroupName $vm.ResourceGroupName
	}
	Write-Host 'god just killed a kitten'
	#Get-AzureRmNetworkInterfaceIpConfig
}
