Function Get-ToolsStatus {
	param(
		[Parameter(Mandatory=$true)]
		[String]$cluster
	)

	foreach($rp in (Get-ResourcePool -Location $cluster)){
		foreach($vm in (Get-VM -Location $rp)){
			$report += Get-HardDisk -VM $vm |
			Select @{N='Cluster';E={$cluster.Name}},
				@{N='ResourcePool';E={$rp.Name}},
				@{N='VM';E={$vm.Name}},
				@{N="Tools Status";E={$vm.ExtensionData.Guest.ToolsStatus}},
				@{N='HD';E={$_.Name}},
				@{N='Datastore';E={($_.Filename.Split(']')[0]).TrimStart('[')}},
				@{N='Filename';E={($_.Filename.Split(' ')[1]).Split('/')[0]}},
				@{N='VMDK Path';E={$_.Filename}},
				@{N='Format';E={$_.StorageFormat}},
				@{N='Type';E={$_.DiskType}},
				@{N='CapacityGB';E={$_.CapacityGB}}
		}
	}

	$report
}