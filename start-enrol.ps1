$existingDCCert = Get-ChildItem "Cert:\LocalMachine\My" | Where-Object {$_.FriendlyName -match "Modern Domain Controller Authentication"}
$dnsName1 = (([System.Net.Dns]::GetHostByName(($env:computerName))).Hostname)
$dnsName2 = ((([System.Net.Dns]::GetHostByName(($env:computerName))).Hostname).ToString().Split(".")[0]) 
$dnsName3 = ((Get-NetIPAddress -AddressFamily IPv4 | where { $_.InterfaceAlias -notmatch 'Loopback'}).IPAddress)

if ($existingDCCert -eq $null){
Write-Host "..enrolling for new certificate" -ForegroundColor Yellow
$subName = ("CN = " + ([System.Net.Dns]::GetHostByName(($env:computerName))).Hostname).ToString()
$newDCCert = Get-Certificate -SubjectName $subName -Template DomainControllerAuthenticationKerberosV2 -DnsName $dnsName1,$dnsName2,$dnsName3 -CertStoreLocation cert:\LocalMachine\My
Write-Host "..esetting friendly name"-ForegroundColor Yellow
(Get-ChildItem "Cert:\LocalMachine\My" | Where-Object {$_.Thumbprint -eq ($newDCCert | select -ExpandProperty Certificate).Thumbprint}).FriendlyName = "Modern Domain Controller Authentication"
}

Else{
Write-Host "..already enrolled with thumbprint: " -ForegroundColor Yellow -NoNewline
$existingDCCert.Thumbprint 
Write-Host "..supported DNS names" -ForegroundColor Yellow
$dnsNamesList = ((Get-ChildItem "Cert:\LocalMachine\My" | Where-Object {$_.Thumbprint -eq $existingDCCert.Thumbprint}).DNSNameList).unicode
$dnsNamesList
}


Write-Host "..testing dns names" -ForegroundColor Yellow
foreach ($name in $dnsNamesList){
Write-Host "$name - " -NoNewline -ForegroundColor Green
if ((Test-Certificate -ErrorAction SilentlyContinue -Policy SSL -DNSName $name -Cert Cert:\localMachine\My\$($existingDCCert.Thumbprint)) -ne $true){
Write-Host "..certificate chain may be broken - please copy the root certificate and run the script again " -ForegroundColor Red
}
Elseif ((Test-Certificate -ErrorAction SilentlyContinue -Policy SSL -DNSName $name -Cert Cert:\localMachine\My\$($existingDCCert.Thumbprint)) -eq $true) {
Write-Host "..certificate chain healthy " -ForegroundColor Green
}
}
