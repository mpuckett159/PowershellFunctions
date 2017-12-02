<#
.SYNOPSIS
   Enables SSH on all hosts in a given cluster or vCenter
.NOTES
   File Name  : Set-HostSshOn.ps1
   Author     : Marcus Puckett
   Version    : 0.1
.INPUTS
   location
.OUTPUTS
   Console output
#>
function Suppress-SshWarning {
	param(
		[string]$location,
		[string]$name
	)

	if($location -ne $null -and $name -ne $null){
		Get-VMHost -Location $location -Name $name | Get-AdvancedSetting UserVars.SuppressShellWarning | Set-AdvancedSetting -Value 1 -Confirm:$false
	}
	elseif($location -ne $null -and $name -eq $null){
		Get-VMHost -Location $location | Get-AdvancedSetting UserVars.SuppressShellWarning | Set-AdvancedSetting -Value 1 -Confirm:$false
	}
	elseif($location -eq $null -and $name -ne $null){
		Get-VMHost -Name $name | Get-AdvancedSetting UserVars.SuppressShellWarning | Set-AdvancedSetting -Value 1 -Confirm:$false
	}
	else{
		Write-Error "Please specify host name or cluster name"
	}
}