<#
.SYNOPSIS
   Migrate XaaS Blueprints from one 7.x vRA
   to a new 7.x vRA environment.
.NOTES
   File Name  : Migrate-vRAXaaSBlueprints.ps1
   Author     : Marcus Puckett
   Version    : 0.1
.INPUTS
   vrauriold, vraurinew, headersold, headersnew, xaas_bps_obj
.OUTPUTS
   Console output
#>
function Migrate-vRAXaaSBlueprints {
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
		$xaas_bps_obj
	)
	
	## Retrieve Property Groups from source environment if object not already provided
	if(!($xaas_bps_obj)){
		$xaas_bps_obj = Invoke-RestMethod -Uri "$($vrauriold)/advanced-designer-service/api/tenants/vsphere.local/blueprints" -Method GET -Headers $headersold
		if($xaas_bps_obj.metadata.number -ne $xaas_bps_obj.metadata.totalPages){
			$i = 2
			while($i -le ($xaas_bps_obj.metadata.totalPages)){
				$xaas_bps_obj.content += (Invoke-RestMethod -Uri "$($vrauriold)/advanced-designer-service/api/tenants/vsphere.local/blueprints?page=$($i)" -Method GET -Headers $headersold).content
				$i += 1
			}
		}
	}
	
	## Sync XaaS Blueprints to target environment
#	foreach($xaas_bp in $xaas_bps_obj.content){
#		Invoke-RestMethod -Uri "$($vraurinew)/advanced-designer-service/api/tenants/vsphere.local/blueprints" -Method POST -Headers $headersnew -Body (ConvertTo-Json -Depth 100 -InputObject $xaas_bp)
#	}
	$xaas_bps_obj.content[0]
}