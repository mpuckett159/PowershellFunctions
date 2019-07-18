<#
.SYNOPSIS
   Migrate Property Groups from one 7.x vRA
   to a new 7.x vRA environment.
.NOTES
   File Name  : Migrate-vRAPropertyGroups.ps1
   Author     : Marcus Puckett
   Version    : 0.1
.INPUTS
   vrauriold, vraurinew, headersold, headersnew, prop_groups_obj
.OUTPUTS
   Console output
#>
function Migrate-vRAPropertyGroups {
	Param(
		[parameter(Mandatory=$true)]
		[String]
		$vrauriold,
		[parameter(Mandatory=$true)]
		[Collections.IDictionary]
		$headersold,
		[parameter(Mandatory=$true)]
		[Collections.IDictionary]
		$headersnew,
		[parameter]
		[String]
		$vraurinew,
		[Object[]]
		$prop_groups_obj,
		[parameter]
		[String]
		$out_file,
		[parameter]
		[Boolean]
		$store_values
	)
	
	## Retrieve Property Groups from source environment if object not already provided
	if(!($prop_groups_obj)){
		$prop_groups_obj = Invoke-RestMethod -Uri "$($vrauriold)/properties-service/api/propertygroups" -Method GET -Headers $headersold
		if($prop_groups_obj.metadata.number -ne $prop_groups_obj.metadata.totalPages){
			$i = 2
			while($i -le ($prop_groups_obj.metadata.totalPages)){
				$prop_groups_obj.content += (Invoke-RestMethod -Uri "$($vrauriold)/properties-service/api/propertygroups?page=$($i)" -Method GET -Headers $headersold).content
				$i += 1
			}
		}
	}
	
	## Sync Property Groups to target environment
	if($store_values){
		foreach($prop_group in $prop_groups_obj.content){
			Invoke-RestMethod -Uri "$($vraurinew)/properties-service/api/propertygroups" -Method POST -Headers $headersnew -Body (ConvertTo-Json -Depth 100 -InputObject $prop_group) 
		}
	}
	else{
		$prop_groups_obj.content[0] | Out-File -FilePath $out_file
	}
}