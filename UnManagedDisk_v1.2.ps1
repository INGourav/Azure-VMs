$subs =  Get-AzureRmSubscription | Select -ExpandProperty Name
foreach($sub in $subs)
{
Set-AzureRmContext -Subscription $sub
$storageAccounts = Get-AzureRmStorageAccount
 foreach($storageAccount in $storageAccounts){
   $storageacname = $storageAccount | Select -ExpandProperty StorageAccountName
    $storageKey = (Get-AzureRmStorageAccountKey -ResourceGroupName $storageAccount.ResourceGroupName -Name $storageAccount.StorageAccountName)[0].Value
      $context = New-AzureStorageContext -StorageAccountName $storageAccount.StorageAccountName -StorageAccountKey $storageKey
       $containers = Get-AzureStorageContainer -Context $context
 foreach($container in $containers){
    $blobs = Get-AzureStorageBlob -Container $container.Name -Context $context
     $blobs | Where-Object {$_.BlobType -eq 'PageBlob' -and $_.Name.EndsWith('.vhd')} | Select *
    ForEach($blob in $blobs)
{
      if($_.ICloudBlob.Properties.LeaseStatus -eq 'Unlocked'){
     $blob | Select  @{N='Subscription'; E={$sub}}, @{N='StorageAccountName'; E={$storageacname}}, Name, LastModified,  Length, ContentType| Export-Csv C:\temp\UnManagedUnAttached26.csv -Append -NoTypeInformation
      }
else{
     $blobs | Select @{N='Subscription'; E={$sub}}, @{N='StorageAccountName'; E={$storageacname}}, Name, LastModified,  Length, ContentType| Export-Csv C:\temp\UnManagedAttached26.csv -Append -NoTypeInformation
    }
   }
  }
 }
}
