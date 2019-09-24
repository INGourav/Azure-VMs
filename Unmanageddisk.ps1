Set-AzureRmContext -Subscription "SUBSCRIPTION NAME"
$storageAccounts = Get-AzureRmStorageAccount
 foreach($storageAccount in $storageAccounts){
    $storageKey = (Get-AzureRmStorageAccountKey -ResourceGroupName $storageAccount.ResourceGroupName -Name $storageAccount.StorageAccountName)[0].Value
      $context = New-AzureStorageContext -StorageAccountName $storageAccount.StorageAccountName -StorageAccountKey $storageKey
       $containers = Get-AzureStorageContainer -Context $context
 foreach($container in $containers){
    $blobs = Get-AzureStorageBlob -Container $container.Name -Context $context
     $blobs | Where-Object {$_.BlobType -eq 'PageBlob' -and $_.Name.EndsWith('.vhd')} | ForEach-Object { 
      if($_.ICloudBlob.Properties.LeaseStatus -eq 'Unlocked'){
     $blobs | Select * | Export-Csv C:\temp\unmanagedunattached.csv -append -notypembuormation
      }
else{
     $blobs | Select * | Export-Csv C:\temp\unmanagedattached.csv -append -notypembuormation
      }
 }
   }
     }
