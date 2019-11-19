<#
Version 1.0
Author - Gourav Kumar
#>

[CmdletBinding()]

Param(
[parameter (Mandatory=$True, ValueFromPipeLine=$True)]
[Alias('Provide the subscription Name Under which we want to create VM')]
[string]$subscriptionName,
[parameter (Mandatory=$True, ValueFromPipeLine=$True)]
[Alias('Resource Group under which all resources are sitting and going to spin-up')]
[string]$resourceGroupName,
[parameter (Mandatory=$True, ValueFromPipeLine=$True)]
[Alias('Name of the snapshot that will be used to create OS disk')]
[string]$snapshotName,
[parameter (Mandatory=$True, ValueFromPipeLine=$True)]
[Alias('Provide the name of the OS disk that will be created using the snapshot')]
[string]$osDiskName,
[parameter (Mandatory=$True, ValueFromPipeLine=$True)]
[Alias('Virtual Nwtwork Name VNET')]
[string]$virtualNetworkName,
[parameter (Mandatory=$True, ValueFromPipeLine=$True)]
[Alias('Name of The Virtial Machine')]
[string]$virtualMachineName,
[parameter (Mandatory=$True, ValueFromPipeLine=$True)]
[Alias('VM size that we want to create')]
[string]$virtualMachineSize
)

#Set the context to the subscription Id where Managed Disk will be created
Set-AzureRmContext -SubscriptionName $subscriptionName

$snapshot = Get-AzureRMSnapshot -ResourceGroupName $resourceGroupName -SnapshotName $snapshotName

$diskConfig = New-AzureRMDiskConfig -Location $snapshot.Location -SourceResourceId $snapshot.Id -CreateOption Copy

$disk = New-AzureRMDisk -Disk $diskConfig -ResourceGroupName $resourceGroupName -DiskName $osDiskName

#Initialize virtual machine configuration
$VirtualMachine = New-AzureRMVMConfig -VMName $virtualMachineName -VMSize $virtualMachineSize

#Use the Managed Disk Resource Id to attach it to the virtual machine. Please change the OS type to linux if OS disk has linux OS
$VirtualMachine = Set-AzureRMVMOSDisk -VM $VirtualMachine -ManagedDiskId $disk.Id -CreateOption Attach -Windows

#Create a public IP for the VM
$publicIp = New-AzureRMPublicIpAddress -Name ($VirtualMachineName.ToLower()+'_ip') -ResourceGroupName $resourceGroupName -Location $snapshot.Location -AllocationMethod Dynamic

#Get the virtual network where virtual machine will be hosted
$vnet = Get-AzureRMVirtualNetwork -Name $virtualNetworkName -ResourceGroupName $resourceGroupName

# Create NIC in the first subnet of the virtual network
$nic = New-AzureRMNetworkInterface -Name ($VirtualMachineName.ToLower()+'_nic') -ResourceGroupName $resourceGroupName -Location $snapshot.Location -SubnetId $vnet.Subnets[0].Id -PublicIpAddressId $publicIp.Id

$VirtualMachine = Add-AzureRMVMNetworkInterface -VM $VirtualMachine -Id $nic.Id

#Create the virtual machine with Managed Disk
New-AzureRMVM -VM $VirtualMachine -ResourceGroupName $resourceGroupName -Location $snapshot.Location
