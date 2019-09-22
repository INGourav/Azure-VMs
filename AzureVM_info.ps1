Login-AzureRmAccount

Get-AzureRmSubscription | Out-GridView -OutputMode Single -Title "Please select a subscription" | ForEach-Object {$selectedSubscriptionID = $PSItem.SubscriptionId}
Write-Host "You have selected the subscription: $selectedSubscriptionID. Proceeding with fetching the inventory. `n" -ForegroundColor green

# Setting the selected subscription
Select-AzureRmSubscription -SubscriptionId $selectedSubscriptionID

Function Dump-VirtualMachinesV2($outputPath) {
    $VMs = Get-AzureRmResource -ResourceType 'Microsoft.Compute/virtualMachines' -ExpandProperties | Sort-Object ResourceName

    $output = "Name,Location,IP,VNET,OS,Azure Size,Core,RAM,OS Disks,Temp Disk,Data Disks (TB),Cloud Services,C (OS),Temp, Data,Storage Account,Diagnostics Storage Account,Endpoints,Status,VIP`n"

    foreach ( $vm in $VMs ) {
        $vmSize = FixSize($vm.Properties.HardwareProfile.VMSize)
        $vmCores = (GetVmConfig($vm.Properties.HardwareProfile.VMSize)).Cores
        $vmRAM = (GetVmConfig($vm.Properties.HardwareProfile.VMSize)).RAM
        $diagnosticStorageAccount = GetDiagnosticsStorageAccount($vm.Properties)
        $endpoints = GetEndpoints($vm.Properties)


        $vm.Properties.StorageProfile.OsDisk.VHD -match "https*://(\w+)"
        $osStorageAccount = $matches[1]

        $output += $vm.Name + "," +`
            $vm.Location + "," +`
            $vm.Properties.InstanceView.PrivateIpAddress + "," +`
            $vm.Properties.NetworkProfile.VirtualNetwork.Name + "," +`
            $vm.Properties.StorageProfile.OsDisk.OsType + "," +`
            $vmSize + "," +`
            $vmCores + "," +`
            $vmRAM + "," +`
            "1," + `
            "1," + `
            $vm.Properties.StorageProfile.DataDisks.Count + "," +`
            $vm.Properties.DomainName.Name + "," + `
            "," + `
            "," + `
            "," + `
            $osStorageAccount + "s," +`
            $diagnosticsStorageAccount + "," +`
            $endpoints + "," +`
            $vm.Properties.InstanceView.Status + "," +`
            $vm.Properties.InstanceView.PublicIpAddresses + "`n"
        }
        $output | Out-File -Encoding ascii $outputPath
}



Function FixSize ($size) {
    Switch ($size) {
        'Extra Small' {$size = 'Standard_A0'}
        'Small' {$size = 'Standard_A1'}
        'Medium' {$size = 'Standard_A2'}
        'Large' {$size = 'Standard_A3'}
        'Extra Large' {$size = 'Standard_A4'}
    }
    return $size
}


Function GetVmConfig($size) {
    $size = FixSize($size)
    $vmConfig = @{"Cores" = 0; "RAM" = 0}
    switch -Regex ($size) {
        "A0$" {$vmConfig = @{"Cores" = 1; "RAM" = 0.75}}
        "A1$" {$vmConfig = @{"Cores" = 1; "RAM" = 1.75}}
        "A2$" {$vmConfig = @{"Cores" = 2; "RAM" = 3.5}}
        "A3$" {$vmConfig = @{"Cores" = 4; "RAM" = 7}}
        "A4$" {$vmConfig = @{"Cores" = 8; "RAM" = 14}}
        "A5$" {$vmConfig = @{"Cores" = 2; "RAM" = 14}}
        "A6$" {$vmConfig = @{"Cores" = 4; "RAM" = 28}}
        "A7$" {$vmConfig = @{"Cores" = 8; "RAM" = 56}}
        "A8$" {$vmConfig = @{"Cores" = 8; "RAM" = 56}}
        "A9$" {$vmConfig = @{"Cores" = 16; "RAM" = 112}}
        "A10$" {$vmConfig = @{"Cores" = 8; "RAM" = 56}}
        "A11$" {$vmConfig = @{"Cores" = 16; "RAM" = 112}}
        "DS?1(_v2)?$" {$vmConfig = @{"Cores" = 1; "RAM" = 3.5}}
        "DS?2(_v2)?$" {$vmConfig = @{"Cores" = 2; "RAM" = 7}}
        "DS?3(_v2)?$" {$vmConfig = @{"Cores" = 4; "RAM" = 14}}
        "DS?4(_v2)?$" {$vmConfig = @{"Cores" = 8; "RAM" = 28}}
        "DS?5(_v2)?$" {$vmConfig = @{"Cores" = 16; "RAM" = 56}}
        "DS?11(_v2)?$" {$vmConfig = @{"Cores" = 2; "RAM" = 14}}
        "DS?12(_v2)?$" {$vmConfig = @{"Cores" = 4; "RAM" = 28}}
        "DS?13(_v2)?$" {$vmConfig = @{"Cores" = 8; "RAM" = 56}}
        "DS?14(_v2)?$" {$vmConfig = @{"Cores" = 16; "RAM" = 112}}
        "GS?1$" {$vmConfig = @{"Cores" = 2; "RAM" = 28}}
        "GS?2$" {$vmConfig = @{"Cores" = 4; "RAM" = 56}}
        "GS?3$" {$vmConfig = @{"Cores" = 8; "RAM" = 112}}
        "GS?4$" {$vmConfig = @{"Cores" = 16; "RAM" = 224}}
        "GS?5$" {$vmConfig = @{"Cores" = 32; "RAM" = 448}}
    }
    return $vmConfig
}



Function GetVip($properties) {
    $vip = ''
    $inputEndpoints = $properties.NetworkProfile.InputEndpoints
    if ($inputEndpoints.Count -gt 0) {
        $vip = $inputEndpoints[0].publicIpAddress
    }
    return $vip
}

Function GetEndpoints($properties) {
    $endpoints = ''
    $inputEndpoints = $properties.NetworkProfile.InputEndpoints
    if ($inputEndpoints.Count -gt 0) {
        $endpoints += $inputEndpoints.PublicPort + '  '
    }
    return $endpoints
}

Function GetDiagnosticsStorageAccount($properties) {
    $storageAccount = ''
    foreach ($extension in $properties.Extensions) {
        if ($extension.Extension -eq 'IaaSDiagnostics') {
            $storageAccount = $extension.Parameters.Public.StorageAccount
        }
    }
    return $storageAccount
}



$outputPathV2 = "c:\temp\Q2-VMv2.csv"

Dump-VirtualMachinesV2($outputPathV2)