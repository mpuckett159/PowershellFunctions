<#
.SYNOPSIS
   Gets JSON doc representing blueprint via
   the blueprint ID.
.ROADMAP
   None
.NOTES
   File Name  : Get-Blueprint.ps1
   Author     : Marcus Puckett
   Version    : 0.1
.INPUTS
   bp_id, vrauri, username, password, tenant
.OUTPUTS
   Console output
#>
function Get-Blueprint{
	Param(
		[parameter(Mandatory=$true)]
		[String]
		$bp_id,
		[parameter(Mandatory=$true)]
		[String]
		$username,
		[parameter(Mandatory=$true)]
		[SecureString]
		$password,
		[parameter(Mandatory=$true)]
		[String]
		$vrauri,
		[String]
		$tenant='vsphere.local'
    )
	
	## Create headers for bearer token retrieval
	$headers = New-Object "System.Collections.Generic.Dictionary[[String],[String]]"
	$headers.Add("Accept", "application/json")
	$headers.Add("Content-Type", "application/json")

	## Create object with log in info
	$tokenreqbody = @{
		username=$username
		password=(ConvertFrom-SecureString $password)
		tenant=$tenant
	}
	## Convert PS object to JSON
	$json = ConvertTo-Json -InputObject $tokenreqbody

	## Request bearer token and add to headers object
	$resp = Invoke-RestMethod -Method POST -Uri ($vrauri + "/identity/api/tokens") -Headers $headers -Body $json
	$headers.Add("Authorization", "Bearer " + $resp.id)
	
	## Retrieve blueprint
	$uri = $vrauri + "/composition-service/api/blueprintdocuments/" + $bp_id
	Invoke-RestMethod -Method GET -Uri $uri -Headers $headers
}