<#
.SYNOPSIS
   This script demonstrates an xVC-vMotion where a running Virtual Machine
   is live migrated between two vCenter Servers which are NOT part of the
   same SSO Domain which is only available using the vSphere 6.0 API.
   This script also supports live migrating a running Virtual Machine between
   two vCenter Servers that ARE part of the same SSO Domain (aka Enhanced Linked Mode)
   This script also supports migrating VMs connected to both a VSS/VDS as well as having multiple vNICs
   This script also supports migrating to/from VMware Cloud on AWS (VMC)
.NOTES
   File Name  : xMove-VM.ps1
   Author     : William Lam - @lamw
   Version    : 1.0
   Updated by  : Askar Kopbayev - @akopbayev
   Version     : 1.1
   Description : The script allows to run compute-only xVC-vMotion when the source VM has multiple disks on differnet datastores.
   Updated by  : William Lam - @lamw
   Version     : 1.2
   Description : Added additional parameters to be able to perform cold migration to/from VMware Cloud on AWS (VMC)
                 -ResourcePool
                 -uppercaseuuid
.LINK
    http://www.virtuallyghetto.com/2016/05/automating-cross-vcenter-vmotion-xvc-vmotion-between-the-same-different-sso-domain.html
.LINK
   https://github.com/lamw
.INPUTS
   sourceVCConnection, destVCConnection, vm, switchtype, switch,
   cluster, resourcepool, datastore, vmhost, vmnetworks, $xvctype, $uppercaseuuid
.OUTPUTS
   Console output
#>

Function xMove-VM {
    param(
    [Parameter(
        Position=0,
        Mandatory=$true,
        ValueFromPipeline=$true,
        ValueFromPipelineByPropertyName=$true)
    ]
    [VMware.VimAutomation.ViCore.Util10.VersionedObjectImpl]$sourcevc,
    [VMware.VimAutomation.ViCore.Util10.VersionedObjectImpl]$destvc,
    [String]$vm,
    [String]$sourcedatacenter,
    [String]$destinationdatacenter,
    [String]$switchtype,
    [String]$switch,
    [String]$sourceswitch,
    [String]$cluster,
    [String]$resourcepool,
    [String]$datastore,
    [String]$vmhost,
    [String[]]$vmnetworks,
    [Int]$xvctype,
    [Boolean]$uppercaseuuid
    )

    # Retrieve Source VC SSL Thumbprint
    $vcurl = "https://" + $destVC
add-type @"
        using System.Net;
        using System.Security.Cryptography.X509Certificates;
            public class IDontCarePolicy : ICertificatePolicy {
            public IDontCarePolicy() {}
            public bool CheckValidationResult(
                ServicePoint sPoint, X509Certificate cert,
                WebRequest wRequest, int certProb) {
                return true;
            }
        }
"@
    [System.Net.ServicePointManager]::CertificatePolicy = new-object IDontCarePolicy
    # Need to do simple GET connection for this method to work
    Invoke-RestMethod -Uri $VCURL -Method Get | Out-Null

    $endpoint_request = [System.Net.Webrequest]::Create("$vcurl")
    # Get Thumbprint + add colons for a valid Thumbprint
    $destVCThumbprint = ($endpoint_request.ServicePoint.Certificate.GetCertHashString()) -replace '(..(?!$))','$1:'

    # Source VM to migrate
    $vm_view = Get-View (Get-VM -Server $sourcevc -Name $vm -Location $sourcedatacenter) -Property Config.Hardware.Device

    # Dest Datastore to migrate VM to
    $datastore_view = (Get-Datastore -Server $destVCConn -Name $datastore -Location $destinationdatacenter)

    # Dest Cluster/ResourcePool to migrate VM to
    if($cluster) {
        $cluster_view = (Get-Cluster -Server $destVCConn -Name $cluster -Location $destinationdatacenter)
        $resource = $cluster_view.ExtensionData.resourcePool
    } else {
        $rp_view = (Get-ResourcePool -Server $destVCConn -Name $resourcepool -Location $destinationdatacenter)
        $resource = $rp_view.ExtensionData.MoRef
    }

    # Dest ESXi host to migrate VM to
    $vmhost_view = (Get-VMHost -Server $destVCConn -Name $vmhost)

    # Find all Etherenet Devices for given VM which
    # we will need to change its network at the destination
    $vmNetworkAdapters = @()
    $devices = $vm_view.Config.Hardware.Device
    foreach ($device in $devices) {
        if($device -is [VMware.Vim.VirtualEthernetCard]) {
            $vmNetworkAdapters += $device
        }
    }

    # Relocate Spec for Migration
    $spec = New-Object VMware.Vim.VirtualMachineRelocateSpec
    $spec.datastore = $datastore_view.Id
    $spec.host = $vmhost_view.Id
    $spec.pool = $resource

    # Relocate Spec Disk Locator
    if($xvctype -eq 1){
        $HDs = Get-VM -Server $sourcevc -Name $vm -Location $sourcedatacenter | Get-HardDisk
        $HDs | %{
            $disk = New-Object VMware.Vim.VirtualMachineRelocateSpecDiskLocator
            $disk.diskId = $_.Extensiondata.Key
            $SourceDS = $_.FileName.Split("]")[0].TrimStart("[")
            $DestDS = Get-Datastore -Server $destvc -name $sourceDS -Location $destinationdatacenter
            $disk.Datastore = $DestDS.ID
            $spec.disk += $disk
        }
    }

    # Service Locator for the destination vCenter Server
    # regardless if its within same SSO Domain or not
    $service = New-Object VMware.Vim.ServiceLocator
    $credential = New-Object VMware.Vim.ServiceLocatorNamePassword
    $credential.username = $destVCusername
    $credential.password = $destVCpassword
    $service.credential = $credential
    # For some xVC-vMotion, VC's InstanceUUID must be in all caps
    # Haven't figured out why, but this flag would allow user to toggle (default=false)
    if($uppercaseuuid) {
        $service.instanceUuid = $destVCConn.InstanceUuid
    } else {
        $service.instanceUuid = ($destVCConn.InstanceUuid).ToUpper()
    }
    $service.sslThumbprint = $destVCThumbprint
    $service.url = "https://$destVC"
    $spec.service = $service

    # Create VM spec depending if destination networking
    # is using Distributed Virtual Switch (VDS) or
    # is using Virtual Standard Switch (VSS)
    $count = 0
    if($switchtype -eq "vds") {
        foreach ($vmNetworkAdapter in $vmNetworkAdapters) {
            # New VM Network to assign vNIC
            $vmnetworkname = $vmnetworks[$count]

            # Extract Distributed Portgroup required info
            $dvs = Get-VDSwitch -Name $switch -Location $destinationdatacenter
            $dvpg = Get-VDPortgroup -Server $destvc -Name $vmnetworkname -VDSwitch $dvs
            $vds_uuid = (Get-View $dvpg.ExtensionData.Config.DistributedVirtualSwitch).Uuid
            $dvpg_key = $dvpg.ExtensionData.Config.key

            # Device Change spec for VSS portgroup
            $dev = New-Object VMware.Vim.VirtualDeviceConfigSpec
            $dev.Operation = "edit"
            $dev.Device = $vmNetworkAdapter
            $dev.device.Backing = New-Object VMware.Vim.VirtualEthernetCardDistributedVirtualPortBackingInfo
            $dev.device.backing.port = New-Object VMware.Vim.DistributedVirtualSwitchPortConnection
            $dev.device.backing.port.switchUuid = $vds_uuid
            $dev.device.backing.port.portgroupKey = $dvpg_key
            $spec.DeviceChange += $dev
            $count++
        }
    } else {
        foreach ($vmNetworkAdapter in $vmNetworkAdapters) {
            # New VM Network to assign vNIC
            $vmnetworkname = $vmnetworks[$count]

            # Device Change spec for VSS portgroup
            $dev = New-Object VMware.Vim.VirtualDeviceConfigSpec
            $dev.Operation = "edit"
            $dev.Device = $vmNetworkAdapter
            $dev.device.backing = New-Object VMware.Vim.VirtualEthernetCardNetworkBackingInfo
            $dev.device.backing.deviceName = $vmnetworkname
            $spec.DeviceChange += $dev
            $count++
        }
    }

    Write-Host "`nMigrating $vmname from $sourceVC to $destVC ...`n"

    # Issue Cross VC-vMotion
    $task = $vm_view.RelocateVM_Task($spec,"defaultPriority")
    $task1 = Get-Task -Id ("Task-$($task.value)")
    $task1 | Wait-Task
}
 
function Get-NewVMHost {
    Param (
        [parameter(Mandatory=$true)]
        [String]
        $targetCluster
    )
 
    $vcCluster = Get-Cluster -Name $targetCluster -Server $destVC
    $targetVMHost = get-vmhost -location $vcCluster | Sort-Object -Property @{Expression = { $_.ExtensionData.Vm.count} } | Select-Object -First 1
    return $targetVMHost
}

function xMove-NOAVMs {
    Param(
        [parameter(Mandatory=$false)]
        [String[]]
        $vmNameList,
        [parameter(Mandatory=$true)]
        [String]
        $sourceVC,
        [parameter(Mandatory=$true)]
        [PSCredential]
        $sourceVCCred,
        [parameter(Mandatory=$true)]
        [String]
        $destVC,
        [parameter(Mandatory=$true)]
        [PSCredential]
        $destVCCred,
        [parameter(Mandatory=$false)]
        [bool]
        $dryRun=$true,
        [parameter(Mandatory=$true)]
        [String]
        $statusLogPath
    )

    # Get source and destination vCenter connections from global parameters
    $sourceVCConn = $global:defaultviservers | Where-Object { $_.Name -eq $sourceVC }
    $destVCConn = $global:defaultviservers | Where-Object { $_.Name -eq $destVC }

    ## Setting clear text username/password info necessary for the xMove-VM function
    $destVCusername = $destVCCred.GetNetworkCredential().username
    $destVCpassword = $destVCCred.GetNetworkCredential().password
    $sourceVCusername = $sourceVCCred.GetNetworkCredential().username
    $sourceVCpassword = $sourceVCCred.GetNetworkCredential().password

    # Throw error if you are not connected to the specified vCenter Servers
    if(!($sourceVCConn) -or !($destVCConn)){
        Write-Host "You are not connected to one of the specified vCenter servers"
        Write-Host "Source vCenter = $($sourceVCConn.Name)"
        Write-Host "Destination vCenter = $($destVCConn.Name)"
        Write-Host "Please connect to which ever vCenter setting above is blank, or both if they are both blank, and try again."
        ThrowError "Exiting script"
    }

    # Looping through VMs selected and initiating the transfer
    $vmActionList = @()
    foreach($vmName in $vmNameList){
        # Store current number of errors in $error variable
        $errorCount = $error.count
        
        try{
            # Pulling necessary information and translating names
            $sourceVMObject = Get-VM -Name $vmName -Server $sourceVC
            $sourceDC = Get-Datacenter -VM $sourceVMObject -Server $sourceVC
            $destDCName = Get-Datacenter -Name $sourceDC.Name -Server $destVC
            $sourceCluster = Get-Cluster -VM $sourceVMObject -Server $sourceVC
            $targetClusterName = Get-Cluster -Name $sourceCluster.Name

            # Setting vSphere Switch details
            $switchtype = "vds"
            $switchname = ($destDCName + "-dvSwitch01")
            $sourceswitch = Get-VDSwitch -VM $sourceVMObject

            # Setting VM Folder name and Resource Pool name
            $vmparentfolder = $sourceVMObject.Folder.Parent.Name
            $vmfolder = $sourceVMObject.Folder.Name
            $resourcepool = "Resources"

            # Getting correct VM Folder info
            $vmfolderparentlist = @()
            $sourceVmParentFolderObj = $sourceVMObject.Folder.Parent
            while($sourceVmParentFolderObj.Name -ne "vm" -and $sourceVmParentFolderObj){
                $vmfolderparentlist += $sourceVmParentFolderObj
                $sourceVmParentFolderObj = $sourceVmParentFolderObj.Parent
            }
            [array]::Reverse($vmfolderparentlist)
            $rootVMFolder = Get-Folder -Location $destDCName -Type VM -Name "vm" -Server $destVC
            if($vmfolderparentlist.count -ge 1){
                $i = 1
                $vmfolderplaceholder = Get-Folder -Location $rootVMFolder -Type VM -Name $vmfolderparentlist[0] -Server $destVC -NoRecursion
                while($i -lt $vmfolderparentlist.count){
                    $vmfolderplaceholder = Get-Folder -Location $vmfolderplaceholder -Type VM -Name $vmfolderparentlist[$i] -Server $destVC -NoRecursion
                    $i++
                }
                $vmFolderObj = Get-Folder -Location $vmfolderplaceholder -Type VM -Name $vmfolder -Server $destVC -NoRecursion
            }
            else {
                $vmFolderObj = Get-Folder -Location $rootVMFolder -Type VM -Name $vmfolder -Server $destVC -NoRecursion
            }

            # Getting a VM Host to migrate the VM to
            $vmhostname = (Get-NewVMHost -targetCluster $targetClusterName).Name

            # Getting the datastore name, this is required for the migration but the VM will not move datastores
            $datastorename = (Get-Datastore -Id $sourceVMObject.DatastoreIdList[0] -Server $sourceVC).Name

            # Retrieving all VM NIC networks and creating an ordered list
            $vmnetworks = (Get-NetworkAdapter -VM $sourceVMObject | Select-Object NetworkName).NetworkName

            # Setting migration parameters as necessary, do not change
            $computeXVC = 1
            $UppercaseUUID = $true
        }
        catch{
            Write-Host "Error getting VM information for migration"
            $vmAction = @{
                sourceVC = "$sourceVC"
                destVC = "$destVC"
                VMName = "$vmname"
                SourceDC = "$($sourceDC.Name)"
                DestinationDC = "$destDCName"
                VMFolder = "$vmfolder"
                switchType = "$switchtype"
                resourcePool = "$resourcepool"
                vmHost = "$vmhostname"
                datastore = "$datastorename"
                vmnetworks = $vmnetworks
                computeXVC = "$computeXVC"
                uppercaseuuid = "$UppercaseUUID"
                moveStatus = "Failed to retrieve VM information"
                errorMessage = $error[0]
            }
        }

        if($dryRun -eq $false){
            # Executing the xMove function
            $vmAction = @{
                sourceVC = "$sourceVC"
                destVC = "$destVC"
                VMName = "$vmname"
                SourceDC = "$($sourceDC.Name)"
                DestinationDC = "$destDCName"
                VMFolder = "$vmfolder"
                switchType = "$switchtype"
                resourcePool = "$resourcepool"
                vmHost = "$vmhostname"
                datastore = "$datastorename"
                vmnetworks = $vmnetworks
                computeXVC = "$computeXVC"
                uppercaseuuid = "$UppercaseUUID"
                moveStatus = "Successful"
                errorMessage = "None"
            }
            try {
                $xMoveInputs = @{
                    sourcevc = $sourceVCConn
                    destvc = $destVCConn
                    VM = $vmName
                    sourcedatacenter = $sourceDC
                    destinationdatacenter = $destDCName
                    switchtype = $switchtype
                    switch = $switchname
                    sourceswitch = $sourceswitch.Name
                    vmhost = $vmhostname
                    cluster = $targetClusterName
                    resourcepool = $resourcepool
                    vmnetworks = $vmnetworks
                    datastore = $datastorename
                    xvcType = $computeXVC
                    uppercaseuuid = $UppercaseUUID
                }
                xMove-VM @xMoveInputs
                $destVMObj = Get-VM -Name $vmName -Server $destVC
                if($vmfolder -ne "vm"){
                    try {
                        Move-VM -Server $destVC -VM $destVMObj -Destination $vmhostname -InventoryLocation $vmFolderObj | Out-Null
                    }
                    catch {
                        Write-Host "Error moving VM $vmname to folder $vmfolder"
                        $vmAction.folderMoveStatus = "Failed"
                        $vmAction.folderMoveError = $error[0]
                    }
                }
                Write-Host "Successfully migrated VM $($vmname)"
            }
            catch{
                Write-Host "Error moving VM $vmname"
                $vmAction.moveStatus = "Failed"
                $vmAction.errorMessage = $error[0]
            }
        }
        else{
            # Set dry run variables if there are no errors
            Write-Host "Dry Run enabled, not migrating VM $($vmname), logging data"
            if($error.count -eq $errorCount){
                $vmAction = @{
                    sourceVC = "$sourceVC"
                    destVC = "$destVC"
                    VMName = "$vmname"
                    SourceDC = "$($sourceDC.Name)"
                    DestinationDC = "$destDCName"
                    VMFolder = "$vmfolder"
                    switchType = "$switchtype"
                    resourcePool = "$resourcepool"
                    vmHost = "$vmhostname"
                    datastore = "$datastorename"
                    vmnetworks = $vmnetworks
                    computeXVC = "$computeXVC"
                    uppercaseuuid = "$UppercaseUUID"
                    moveStatus = "dryRun"
                    errorMessage = "None"
                }
            }
        }
        $vmActionList += $vmAction
    }
    ConvertTo-Json -InputObject $vmActionList | Add-Content -Path $statusLogPath
}