function Update-Blueprint{
	Param(
		[parameter(Mandatory=$true)]
		[String]
		$bp_id,	
		[parameter(Mandatory=$true)]
		[String]
		$csv_path,	
		[parameter(Mandatory=$true)]
		[String]
		$env,
		[parameter(Mandatory=$true)]
		[String]
		$bp_type,
		[parameter(Mandatory=$true)]
		[String]
		$username,
		[parameter(Mandatory=$true)]
		[SecureString]
		$password,
		[parameter(Mandatory=$true)]
		[String]
		$uri,
		[parameter]
		[String]
		$tenant="vsphere.local"
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
	## Convert object to JSON doc
	$json = ConvertTo-Json -InputObject $tokenreqbody

	## Request bearer token and add to headers object
	$resp = Invoke-RestMethod -Method POST -Uri ($uri + "/identity/api/tokens") -Headers $headers -Body $json
	$headers.Add("Authorization", "Bearer " + $resp.id)

	## Get raw JSON data from vRA API and convert to Powershell object
	$jsonobj = Invoke-RestMethod -Method GET -Uri ($uri + "composition-service/api/blueprintdocuments/" + $bp_id) -Headers $headers

	## Get CSV data and convert to Powershell object
	$csvdata = Import-Csv -Path $csv_path

	## Loop through VMs
	foreach($vm in $csvdata){
		## Only act on selected BP, Datalex in this case
		if($vm.'BP Name' -eq $bp_type){
			## Extract information from CSV objects
			$vmname = $vm.'VM Name'.SubString(0,3)
			$vmname
			
			## Convert text to variables
			$cpudata = Select-String -InputObject $vm.$env -Pattern "[0-9]* CPU"  | Select-Object Matches
			$memdata = Select-String -InputObject $vm.$env -Pattern "[0-9]*GB RAM"  | Select-Object Matches
			$clusterdata = Select-String -InputObject $vm.$env -Pattern "[0-9]* VM"  | Select-Object Matches
			
			## Parse new variables into number strings only
			$cpudata = Select-String -InputObject $cpudata.Matches.Value -Pattern "[0-9]*"  | Select-Object Matches
			$memdata = Select-String -InputObject $memdata.Matches.Value -Pattern "[0-9]*"  | Select-Object Matches
			$clusterdata = Select-String -InputObject $clusterdata.Matches.Value -Pattern "[0-9]*"  | Select-Object Matches
			
			## Convert number strings to ints
			[int]$intcpu = [convert]::ToInt32($cpudata.Matches.Value, 10)
			[int]$intmem = [convert]::ToInt32($memdata.Matches.Value, 10)
			[int]$intcluster = [convert]::ToInt32($clusterdata.Matches.Value, 10)
			
			## Convert memory to MB
			$memingb = $intmem*1024
			
			## Apply extracted data to JSON object
			$jsonobj.components.$vmname.data.memory.default = $memingb
			$jsonobj.components.$vmname.data.memory.min = $memingb
			$jsonobj.components.$vmname.data.memory.max = $memingb*6
			$jsonobj.components.$vmname.data.cpu.default = $intcpu
			$jsonobj.components.$vmname.data.cpu.min = $intcpu
			$jsonobj.components.$vmname.data.cpu.max = $intcpu*6
			$jsonobj.components.$vmname.data.'_cluster'.default = $intcluster
			$jsonobj.components.$vmname.data.'_cluster'.min = $intcluster
			$jsonobj.components.$vmname.data.'_cluster'.max = $intcluster*6
		}
	}

	## Convert new JSON data in Powershell object into JSON data
	$newjsondata = ConvertTo-Json -InputObject $jsonobj -Depth 100

	## Update Blueprint via vRA API
	Invoke-RestMethod -Method PUT -Uri ($uri + "composition-service/api/blueprintdocuments/" + $bp_id) -Headers $headers -Body $newjsondata
}
