function Get-VMIPs {
	param([string[]]$vms)
	foreach($vm in $vms){
		Get-VM -Name $vm | Select-Object Name, @{N="IP Address";E={@($_.guest.IPAddress[0])}} | Format-Table
	}
}