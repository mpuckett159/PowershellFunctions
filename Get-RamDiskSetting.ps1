<#
.SYNOPSIS
   Gets JSON doc representing blueprint via
   the blueprint ID.
.ROADMAP
   None
.NOTES
   File Name  : Get-RamDiskSetting.ps1
   Author     : Marcus Puckett
   Version    : 0.1
.INPUTS
   vcservers
.OUTPUTS
   Console output
#>
function Get-RamDiskSetting{
	Param(
		[String]
		$vcservers
	)
	
	$badhosts = @()
	
	#pull together list of hosts
	foreach($vcserver in $vcservers){
		$vmhosts += Get-VMHost -Server $vcserver
	}
	
	foreach($vmhost in $vmhosts){
		try{
			$value = Get-AdvancedSetting -Entity $vmhost -Name "UserVars.ToolsRamDisk"
			if($value.Value -ne "1"){
				$badhosts += $vmhost.Name
			}
		}
		catch{
			$badhosts += $vmhost.Name
		}
	}
	
	$badhosts
}