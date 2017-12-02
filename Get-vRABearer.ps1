<#
.SYNOPSIS
   Get and store bearer token for vRA in header JSON.
   Note that the default tenant is the default setting
   for the tenant switch.
.NOTES
   File Name  : Get-vRABearer.ps1
   Author     : Marcus Puckett
   Version    : 0.1
.INPUTS
   username, password, tenant, vrauri
.OUTPUTS
   Console output
#>
function Get-vRABearer {
	Param(
		[parameter(Mandatory=$true)]
		[String]
		$username,
		[parameter(Mandatory=$true)]
		[String]
		$password,
		[parameter(Mandatory=$true)]
		[String]
		$vrauri,
		[String]
		$tenant='vsphere.local'
	)
	
	## Create base headers
	$headers = New-Object "System.Collections.Generic.Dictionary[[String],[String]]"
	$headers.Add("Accept", "application/json")
	$headers.Add("Content-Type", "application/json")

	## Create object with log in info
	$tokenreqbody = @{
		username=$username
		password=$password
		tenant=$tenant
	}
	## Convert PS object to JSON
	$json = ConvertTo-Json -InputObject $tokenreqbody

	## Request bearer token and add to headers object
	$resp = Invoke-RestMethod -Method POST -Uri ($vrauri + "/identity/api/tokens") -Headers $headers -Body $json
	$headers.Add("Authorization", "Bearer " + $resp.id)
	
	## Return headers
	$headers
}