<#
.SYNOPSIS
   Migrate Blueprints from one 7.x vRA
   to a new 7.x vRA environment.
.NOTES
   File Name  : Migrate-vRABlueprints.ps1
   Author     : Marcus Puckett
   Version    : 0.1
.INPUTS
   vrauriold, vraurinew, headersold, headersnew, comp_bps_obj
.OUTPUTS
   Console output
#>
function Migrate-vRABlueprints {
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
		$comp_bps_obj
	)
	
	## Retrieve Property Groups from source environment if object not already provided
	if(!($comp_bps_obj)){
		$comp_bps_obj = Invoke-RestMethod -Uri "$($vrauriold)/composition-service/api/blueprintdocuments/" -Method GET -Headers $headersold
		if($comp_bps_obj.metadata.number -ne $comp_bps_obj.metadata.totalPages){
			$i = 2
			while($i -le ($comp_bps_obj.metadata.totalPages)){
				$comp_bps_obj.content += (Invoke-RestMethod -Uri "$($vrauriold)/composition-service/api/blueprintdocuments?page=$($i)" -Method GET -Headers $headersold).content
				$i += 1
			}
		}
	}
	
	## Sync Composite Blueprints to target environment
#	foreach($comp_bp in $comp_bps_obj.content){
#		Invoke-RestMethod -Uri "$($vraurinew)/composition-service/api/blueprintdocuments/$($comp_bp.id)" -Method PUT -Headers $headersnew -Body (ConvertTo-Json -Depth 100 -InputObject $comp_bp)
#	}
	$comp_bps_obj.content[0]
}