<#
.SYNOPSIS
   Migrate Property Definitions from one 7.x vRA
   to a new 7.x vRA environment.
.NOTES
   File Name  : Migrate-vRAPropertyDefinitions.ps1
   Author     : Marcus Puckett
   Version    : 0.1
.INPUTS
   vrauriold, vraurinew, headersold, headersnew, prop_defs_obj
.OUTPUTS
   Console output
#>
function Migrate-vRAPropertyDefinitions {
	Param(
		[parameter(Mandatory=$true)]
		[String]
		$vrauriold,
		[parameter(Mandatory=$true)]
		[String]
		$vraurinew,
		[parameter(Mandatory=$true)]
		[Collections.IDictionary]
		$headersold,
		[parameter(Mandatory=$true)]
		[Collections.IDictionary]
		$headersnew,
		[Object[]]
		$prop_defs_obj
	)
	
	## Retrieve Property Groups from source environment if object not already provided
	if(!($prop_defs_obj)){
		$prop_defs_obj = Invoke-RestMethod -Uri "$($vrauriold)/properties-service/api/propertydefinitions" -Method GET -Headers $headersold
		if($prop_defs_obj.metadata.number -ne $prop_defs_obj.metadata.totalPages){
			$i = 2
			while($i -le ($prop_defs_obj.metadata.totalPages)){
				$prop_defs_obj.content += (Invoke-RestMethod -Uri "$($vrauriold)/properties-service/api/propertydefinitions?page=$($i)" -Method GET -Headers $headersold).content
				$i += 1
			}
		}
	}
	
	## Sync Property Definitions to target environment
#	foreach($prop_def in $prop_defs_obj.content){
#		Invoke-RestMethod -Uri "$($vraurinew)/properties-service/api/propertydefinitions" -Method POST -Headers $headersnew -Body (ConvertTo-Json -Depth 100 -InputObject $prop_def)
#	}	
	$prop_defs_obj.content[0]
}