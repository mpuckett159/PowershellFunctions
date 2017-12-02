<#
.SYNOPSIS
   Add Machine Prefix Reset XaaS to Blueprints
.NOTES
   File Name  : Add-PrefixResetXaaS.ps1
   Author     : Marcus Puckett
   Version    : 0.1
.INPUTS
   
.OUTPUTS
   Console output
#>
function Add-PrefixResetXaaS {
	Param(
		[parameter(Mandatory=$true)]
		[hashtable]
		$headers,
		[parameter(Mandatory=$true)]
		[String]
		$vrauri
	)
	
	## Reset Machine Prefix block for Non-Prod
	$reset_prefix_nonprod = @"
	{
	  "type": "<UUID>",
	  "propertyGroups": null,
	  "dependsOn": [],
	  "data": {
		"_description": "",
		"prefixName": {
		  "editable": true,
		  "readOnly": true,
		  "fixed": [],
		  "refreshOnChange": false,
		  "required": true
		},
		"_declarationId": "<XaaSBlueprintName>"
	  },
	  "componentProfiles": []
	}
"@

	## Reset Machine Prefix block for Non-Prod
	$reset_prefix_prod = @"
	{
      "type": "<UUID>",
      "propertyGroups": null,
      "dependsOn": [],
      "data": {
        "_description": "",
        "prefixName": {
          "editable": true,
          "readOnly": true,
          "fixed": [],
          "refreshOnChange": false,
          "required": true
        },
        "_declarationId": "<XaaSBlueprintName>"
      },
      "componentProfiles": []
    }
"@
	
	Write-Host Getting Blueprints -foregroundcolor "green"
	## Get raw JSON data from vRA API and convert to Powershell object
	$uri = $vrauri + "/composition-service/api/blueprintdocuments"
	$jsonobj = Invoke-RestMethod -Method GET -Uri $uri -Headers $headers
	$bpobj = $jsonobj.content

	## Get the rest of the JSON data from vRA API and convert to Powershell object and attach to existing object
	$i = 2
	while($jsonobj.metadata.number -lt $jsonobj.metadata.totalPages){
		$uri = $vrauri + "/composition-service/api/blueprintdocuments/?page=" + $i
		$jsonobj = Invoke-RestMethod -Method GET -Uri $uri -Headers $headers
		$bpobj += $jsonobj.content
		$i += 1
		Write-Host Continuing blueprint retreival $jsonobj.metadata.number of $jsonobj.metadata.totalPages -foregroundcolor "green"
	}
	
	## Dynamically add Machine Prefix Reset XaaS based on blueprint names
	foreach($bp in $bpobj){
		if(!($bp.components.'<XaaSBlueprintName>') -and !($bp.components.'<XaaSBlueprintName>')){
			## Differentiate between Nonprod and Prod blueprints for different XaaS blocks
			if($bp.name -like "<ComponentName>*" -or $bp.name -like "<ComponentName>*" -or $bp.name -like "<ComponentName>*" -or $bp.name -like "<ComponentName>*" -or $bp.name -like "<ComponentName>*" -or $bp.name -like "<ComponentName>*" -and $bp.name -notlike "*<EnvironmentName>*"){
				## Add the Reset Machine Prefix JSON block to the object
				$bp.components | add-member -Name "<XaaSBlueprintName>" -value (Convertfrom-Json $reset_prefix_nonprod) -MemberType NoteProperty -Force
				$bp.layout | add-member -Name "<XaaSBlueprintName>" -Value "0,0" -MemberType NoteProperty
				foreach($comp in (Get-Member -InputObject $bp.components | Where-Object {$_.MemberType -eq "NoteProperty" -and $_.Name -notlike "<XaasBlueprintName>*"})){
					##Add the machine prefixes from the objects in the blueprint to the XaaS blueprint
					$bp.components.'<XaaSBlueprintName>'.data.prefixName.fixed += $bp.components.($comp.Name).data.machine_prefix.fixed.id
					## Adds the Reset Machine Prefix XaaS as a dependecy for the component
					$bp.components.($comp.Name).dependsOn += '<XaaSBlueprintName>'
				}
				## Remove null entries that may appear
				foreach($name in $bp.components.'<XaaSBlueprintName>'.data.prefixName.fixed){
					$names = @()
					if($name -ne ""){
						$names += $name
					}
				}
				$bp.components.'<XaaSBlueprintName>'.data.prefixName.fixed = $names
				##Convert PSObject into JSON string
				$body = ConvertTo-Json -InputObject $bp -Depth 100
				## Upload the new blueprint document to vRA
				$uri = $vrauri + "/composition-service/api/blueprintdocuments/" + $bp.id
				Try{
					$jsonobj = Invoke-RestMethod -Method PUT -Uri $uri -Headers $headers -body $body
				}
				Catch{
					Write-Host $bp.name failed to update -foregroundcolor "red"
					Write-Host $body
				}
				if(!$error){
					Write-Host $obj.id migrated -foregroundcolor "green"
				}
			}
			elseif($bp.name -like "<ComponentName>*" -or $bp.name -like "<ComponentName>*" -or $bp.name -like "<ComponentName>*" -or $bp.name -like "<ComponentName>*" -or $bp.name -like "<ComponentName>*" -or $bp.name -like "<ComponentName>*" -and $bp.name -like "*<EnvironmentName>*"){
				$bp.components | add-member -Name "<XaaSBlueprintName>" -value (Convertfrom-Json $reset_prefix_prod) -MemberType NoteProperty -Force
				$bp.layout | add-member -Name "<XaaSBlueprintName>" -Value "0,0" -MemberType NoteProperty
				foreach($comp in (Get-Member -InputObject $bp.components | Where-Object {$_.MemberType -eq "NoteProperty" -and $_.Name -notlike '<XaaSBlueprintName>'})){
					##Add the machine prefixes from the objects in the blueprint to the XaaS blueprint
					$bp.components.'<XaaSBlueprintName>'.data.prefixName.fixed += $bp.components.($comp.Name).data.machine_prefix.fixed.id
					## Adds the Reset Machine Prefix XaaS as a dependecy for the component
					$bp.components.($comp.Name).dependsOn += '<XaaSBlueprintName>'
				}
				## Remove null entries that may appear
				foreach($name in $bp.components.'<XaaSBlueprintName>'.data.prefixName.fixed){
					$names = @()
					if($name -ne ""){
						$names += $name
					}
				}
				$bp.components.'<XaaSBlueprintName>'.data.prefixName.fixed = $names
				##Convert PSObject into JSON string
				$body = ConvertTo-Json -InputObject $bp -Depth 100
				## Upload the new blueprint document to vRA
				$uri = $vrauri + "/composition-service/api/blueprintdocuments/" + $bp.id
				Try{
					$jsonobj = Invoke-RestMethod -Method PUT -Uri $uri -Headers $headers -body $body
				}
				Catch{
					Write-Host $bp.name failed to update -foregroundcolor "red"
					Write-Host $bp.components.($comp.Name).data.machine_prefix.fixed.id
					Write-Host $bp.components.'<XaaSBlueprintName>'.data.prefixName.fixed
				}
				if(!$error){
					Write-Host $obj.id migrated -foregroundcolor "green"
				}
			}
		}
	}
}