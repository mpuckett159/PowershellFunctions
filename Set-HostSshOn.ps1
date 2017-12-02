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
function Set-HostSshOn {
	param([string]$location)

	$hosts = Get-VMHost -Location $location
	Get-VMHostService -VMHost $hosts | Where-Object { $_.Key -eq "TSM-SSH"} | Set-VMHostService -Policy On
}