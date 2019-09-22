# This Script is use to export Disk Encryption Status of Azure VM under a Subscription in a one go.
# Author Gourav Kumar 
# Reach me on gouravrathore23@gmail.com or gouravin@outlook.com

#Getting information about OS Volume for each VM under Subscription using Resource Group
$osVolEncrypted = {(Get-AzureRmVMDiskEncryptionStatus -ResourceGroupName $_.ResourceGroupName -VMName $_.Name).OsVolumeEncrypted}

#Getting information about Data Volume for each VM under Subscription using Resource Group
$dataVolEncrypted= {(Get-AzureRmVMDiskEncryptionStatus -ResourceGroupName $_.ResourceGroupName -VMName $_.Name).DataVolumesEncrypted}

#Now collecting data and exporting data from variables for each VM
Get-AzureRmVm | Select-Object @{Label="MachineName"; Expression={$_.Name}}, @{Label="OsVolumeEncrypted"; Expression=$osVolEncrypted}, @{Label="DataVolumesEncrypted"; Expression=$dataVolEncrypted} |Export-Csv C:\temp\DISKENCRYPTIONREPORT.csv

