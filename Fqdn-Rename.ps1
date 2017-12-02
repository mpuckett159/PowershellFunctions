<#
.SYNOPSIS
   Replaces the 
.NOTES
   File Name  : Fqdn-Rename.ps1
   Author     : Marcus Puckett
   Version    : 0.1
.INPUTS
   
.OUTPUTS
   Console output
#>
function Fqdn-Rename {
	Param(
		[parameter(Mandatory=$true)]
		[string]
		$csvpathinput,
		[parameter(Mandatory=$true)]
		[string]
		$csvpathoutput
	)
	
	$servers = Import-Csv $csvpathinput
	$myhash= @{ fqdn=''}
	$newarray = New-Object  PSObject -Property $myhash
	$array1 = @()

	foreach($server in $servers){
		if($server.Blueprint -eq "<BlueprintName>"){
			$myhash= @{ fqdn=$server.Name + "<FQDN>"}
			$newarray = New-Object  PSObject -Property $myhash
			$array1 += $newarray
		}
		if($server.Blueprint -eq "<BlueprintName>"){
			$myhash= @{ fqdn=$server.Name + "<FQDN>"}
			$newarray = New-Object  PSObject -Property $myhash
			$array1 += $newarray
		}
		if($server.Blueprint -eq "<BlueprintName>"){
			$myhash= @{ fqdn=$server.Name + "<FQDN>"}
			$newarray = New-Object  PSObject -Property $myhash
			$array1 += $newarray
		}
		if($server.Blueprint -eq "<BlueprintName>"){
			$myhash= @{ fqdn=$server.Name + "<FQDN>"}
			$newarray = New-Object  PSObject -Property $myhash
			$array1 += $newarray
		}
		if($server.Blueprint -eq "<BlueprintName>"){
			$myhash= @{ fqdn=$server.Name + "<FQDN>"}
			$newarray = New-Object  PSObject -Property $myhash
			$array1 += $newarray
		}
		if($server.Blueprint -eq "<BlueprintName>"){
			$myhash= @{ fqdn=$server.Name + "<FQDN>"}
			$newarray = New-Object  PSObject -Property $myhash
			$array1 += $newarray
		}
		if($server.Blueprint -eq "<BlueprintName>"){
			$myhash= @{ fqdn=$server.Name + "<FQDN>"}
			$newarray = New-Object  PSObject -Property $myhash
			$array1 += $newarray
		}
		if($server.Blueprint -eq "<BlueprintName>"){
			$myhash= @{ fqdn=$server.Name + "<FQDN>"}
			$newarray = New-Object  PSObject -Property $myhash
			$array1 += $newarray
		}
		if($server.Blueprint -eq "<BlueprintName>"){
			$myhash= @{ fqdn=$server.Name + "<FQDN>"}
			$newarray = New-Object  PSObject -Property $myhash
			$array1 += $newarray
		}
		if($server.Blueprint -eq "<BlueprintName>"){
			$myhash= @{ fqdn=$server.Name + "<FQDN>"}
			$newarray = New-Object  PSObject -Property $myhash
			$array1 += $newarray
		}
	}

	$array1 | Export-Csv $csvpathoutput
}