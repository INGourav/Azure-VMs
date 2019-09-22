<#
param(
[parameter(Mandatory=$False, HelpMessage= "Provide Subscription Name")]
$subscriptionname
)
#>


Login-AzureRmAccount

$Day= (Get-Date).Day
$Month= (Get-Date).Month

# If you want to use check for one particular subscription then uncomment below line and comment 11 line.
#$subscriptionname = Read-Host -Prompt "Enter Your Subscription Name or ID"

#if you have uncomment above line then comment below line (11th line) otherwise it will run for all subscription under your tenat.
$subs= Get-AzureRmSubscription | where{$_.Name -eq "Your Subscription"} | Select-Object -ExpandProperty Name

foreach($subscriptionname in $subs)
{
Set-AzureRmContext -Subscription $subscriptionname -ErrorAction Stop

$VMS= Get-AzureRmVM

foreach($VM in $VMS)
{
$RG= $VM.ResourceGroupName
$VM= $VM.Name
$Extesnion=Get-AzureRmVMExtension -ResourceGroupName $RG -VMName $VM -Name IaaSDiagnostics –Status -ErrorAction SilentlyContinue
if(!$Extesnion)
{
$newObj=New-Object -TypeName psobject
$newObj|Add-Member -MemberType NoteProperty -Name "Subscription" -Value $subscriptionname
$newObj|Add-Member -MemberType NoteProperty -Name "VM Name" -Value $VM
$newObj|Add-Member -MemberType NoteProperty -Name "Resource Group" -Value $RG
$newObj|Add-Member -MemberType NoteProperty -Name "Location" -Value "Not Found"
$newObj|Add-Member -MemberType NoteProperty -Name "Storage Account" -Value "Not Found"
$newObj|Export-Csv C:\Temp\"IaasDiagnostic"$Day$Month.csv -Append -NoTypeInformation
}else
{
$Storage=$Extesnion.PublicSettings.split("{}").replace('"WadCfg":',"")[1]
$StorageAccount=$Storage.Split("")[5]
$newObj=New-Object -TypeName psobject
$newObj|Add-Member -MemberType NoteProperty -Name "Subscription" -Value $subscriptionname
$newObj|Add-Member -MemberType NoteProperty -Name "VM Name" -Value $Extesnion.VMName
$newObj|Add-Member -MemberType NoteProperty -Name "Resource Group" -Value $Extesnion.ResourceGroupName
$newObj|Add-Member -MemberType NoteProperty -Name "Location" -Value $Extesnion.Location
$newObj|Add-Member -MemberType NoteProperty -Name "Storage Account" -Value $StorageAccount
$newObj|Export-Csv C:\Temp\"IaasDiagnostic"$Day$Month.csv -Append -NoTypeInformation
}
}
}
