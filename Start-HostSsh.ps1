## Start SSH on all hosts in cluster
param( [string]$location)

$hosts = Get-VMHost -Location $location
Get-VMHostService -VMHost $hosts | Where-Object { $_.Key -eq "TSM-SSH"} | Start-VMHostService