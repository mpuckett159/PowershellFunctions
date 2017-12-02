<#
.SYNOPSIS
   Updates the template to clone a VM from in a 
   blueprint via API by editing the JSON document
   returned by vRA.
.ROADMAP
   None at this time
.NOTES
   File Name  : Update-BpSourceTemplate.ps1
   Author     : Marcus Puckett
   Version    : 0.1
.INPUTS
   bp_id, env, bp_type, vrauri, username, password, tenant, newtemplatename, sourcevm
.OUTPUTS
   Console output
#>
function Update-BpSourceTemplate{
	Param(
		[parameter(Mandatory=$true)]
		[String]
		$bp_id,
		[parameter(Mandatory=$true)]
		[String]
		$vrauri,
		[parameter(Mandatory=$true)]
		[String]
		$newtemplatename,
		[parameter(Mandatory=$true)]
		[String]
		$username,
		[parameter(Mandatory=$true)]
		[String]
		$password,
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
		password=$password
		tenant=$tenant
	}
	## Convert PS object to JSON
	$json = ConvertTo-Json -InputObject $tokenreqbody

	## Request bearer token and add to headers object
	$resp = Invoke-RestMethod -Method POST -Uri ($vrauri + "/identity/api/tokens") -Headers $headers -Body $json
	$headers.Add("Authorization", "Bearer " + $resp.id)

	## Get raw blueprint JSON data from vRA API and convert to Powershell object
	try
	{
		$uri = $vrauri + "/composition-service/api/blueprintdocuments/" + $bp_id
		$jsonbpobj = Invoke-RestMethod -Method GET -Uri $uri -Headers $headers
	}
	catch
	{
		Write-Host $bp_id does not exist
	}
	
	## Get template information from vRA API
	try
	{
		$uri = $vrauri + "/iaas-proxy-provider/api/source-machines?platformTypeId=Infrastructure.CatalogItem.Machine.Virtual.vSphere&actionId=FullClone&loadTemplates=true&%24filter=name%20eq%20'" + $newtemplatename + "'"
		$jsontempobj = Invoke-RestMethod -Method GET -Uri $uri -Headers $headers
	}
	catch
	{
		Write-Host $newtemplatename does not exist
	}
	
	## Update JSON with new template value
	$components = $jsonbpobj.components | get-member -MemberType "NoteProperty"
	
	foreach($component in $components){
		if($jsonbpobj.components.($component.name).type -eq "Infrastructure.CatalogItem.Machine.Virtual.vSphere"){
			$jsonbpobj.components.($component.name).data.source_machine_name.fixed = $jsontempobj.content.name
			$jsonbpobj.components.($component.name).data.source_machine.fixed.label = $jsontempobj.content.name
			$jsonbpobj.components.($component.name).data.source_machine.fixed.id = $jsontempobj.content.id
		}
	}
	
	## Convert new JSON data in Powershell object into JSON data
	$newjsondata = ConvertTo-Json -InputObject $jsonbpobj -Depth 100

	## Update Blueprint via vRA API
	$uri = $vrauri + "/composition-service/api/blueprintdocuments/" + $bp_id
	Invoke-RestMethod -Method PUT -Uri $uri -Headers $headers -Body $newjsondata
}