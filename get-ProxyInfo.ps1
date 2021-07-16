#
# Get-ProxyInfo 
#
# By Steven Wight 
#
# Input is CSV file with username,hostname 



$infile = "C:\temp\posh_inputs\ProxyMachines.CSV"
$outfile = "C:\temp\Posh_outputs\ProxyPacs_$(get-date -f yyyy-MM-dd-HH-mm)_LOG.csv"
$domain = 'POSHYT'



Import-Csv -Path $infile -Header username,Computer | foreach-object {

$results = $Computer = $Username = $searchScopes = $user = $objUser = $uptime = $PathTest = $strSID = $null

$Username = $_.Username
$Computer = Get-ADComputer $_.Computer -server $domain
$user = get-aduser $Username -properties * -server $domain

$PathTest = Test-Connection -Computername $Computer.DNShostname -BufferSize 16 -Count 1 -Quiet

if($PathTest -eq $True) {
$objUser = New-Object System.Security.Principal.NTAccount($domain, $user.name)
$strSID = $objUser.Translate([System.Security.Principal.SecurityIdentifier])
$searchScopes = "registry::HKEY_USERS\$($strSID.Value)\SOFTWARE\Microsoft\Windows\CurrentVersion\Internet Settings"
try{
$results =  Invoke-Command -ComputerName $Computer.DNShostname -ScriptBlock  {
$Browsersettings = Get-ItemProperty $using:searchScopes
Return $Browsersettings}
}catch{
$results = $_.Exception.Message
}
if($null -eq $results){
$username = (Get-WmiObject –ComputerName $Computer.DNShostname –Class Win32_ComputerSystem | Select-Object UserName)
$username = ($username -split "\\" )[1]
$username = $username.substring(0,8)
$user = get-aduser $Username -properties * -server $domain
$objUser = New-Object System.Security.Principal.NTAccount($domain, $user.name)
$strSID = $objUser.Translate([System.Security.Principal.SecurityIdentifier])
$searchScopes = "registry::HKEY_USERS\$($strSID.Value)\SOFTWARE\Microsoft\Windows\CurrentVersion\Internet Settings"
try{
$results =  Invoke-Command -ComputerName $Computer.DNShostname -ScriptBlock  {
$Browsersettings = Get-ItemProperty $using:searchScopes
Return $Browsersettings}
}catch{
$results = $_.Exception.Message
}
}
Try {
$uptime = (Get-Date) - [Management.ManagementDateTimeConverter]::ToDateTime((Get-WmiObject Win32_OperatingSystem -ComputerName $Computer.DNShostname).LastBootUpTime) 
$uptime = "$($Uptime.Days) D $($Uptime.Hours) H $($Uptime.Minutes) M"
}catch{
$uptime = $_.Exception.Message
}
[pscustomobject][ordered] @{
autdetect = $results.AutoDetect
proxypac= $results.AutoConfigURL
ProxyEnable = $results.ProxyEnable
ProxyServer = $results.ProxyServer
ProxyOverride = $results.ProxyOverride
MigrateProxy = $results.MigrateProxy 
"uptime (days)" = $uptime
Computer = $COMPUTER.name
"original Username" = $_.Username
"loggedon username" = $user.name
Displayname = $user.displayname
Email = $user.Emailaddress
} | Export-csv -Path $outfile -NoTypeInformation  -Append -Force

}else{
[pscustomobject][ordered] @{
autdetect = "N/A"
proxypac= "N/A"
ProxyEnable = "N/A"
ProxyServer = "N/A"
ProxyOverride = "N/A"
MigrateProxy = "N/A" 
"uptime (days)" = "OFFLINE"
Computer = $COMPUTER.name
"original Username" = $_.Username
"loggedon username" = $user.name
Displayname = $user.displayname
Email = $user.Emailaddress
} | Export-csv -Path $outfile -NoTypeInformation  -Append -Force}
}
