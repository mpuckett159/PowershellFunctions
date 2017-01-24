## Iterative VM clone operation
 
function New-VMIterative
{
                param( [int]$startInt, [int]$endInt, [string]$sourceVM, [string]$vmNameBase )
                $vmVar = Get-VM -Name $sourceVM
                $vmHost = Get-VM -Name $sourceVM | Get-VMHost
                $datastore = Get-VM -Name $sourceVM | Get-Datastore
                $num = $startInt
                $diff = $endInt - $startInt
                if($([string]$startInt).length -eq $([string]$endInt).length){
                                while($num -le $endInt){
                                                $vmnamefinal = $vmNameBase + $num
                                                $writehostteext = "Creating new VM - " + $vmnamefinal
                                                Write-Host $writehosttext
                                                New-VM -VM $vmVar -VMHost $vmHost -Datastore $datastore -Name $vmnamefinal
                                                $num += 1
                                }
                }
                if($([string]$startInt).length -ne $([string]$endInt).length){
                                $len = $([string]$startInt).length
                                while($num -lt $endInt){
                                                while($([string]$num).length -eq $len -and $num -lt $endInt){
                                                                $vmnamefinal = $vmNameBase + $num
                                                                $writehostteext = "Creating new VM - " + $vmnamefinal
                                                                Write-Host $writehosttext
                                                                New-VM -VM $vmVar -VMHost $vmHost -Datastore $datastore -Name $vmnamefinal
                                                                $num += 1
                                                }
                                                $len += 1
                                                $vmNameBase = $vmNameBase.Substring(0,$vmNameBase.Length-1)
                                }
                }
}
