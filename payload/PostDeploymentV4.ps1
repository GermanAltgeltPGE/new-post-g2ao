$filename = Join-Path -Path D:\installs -ChildPath "${env:COMPUTERNAME}_$(get-date -f yyyyMMdd).txt"
New-Item -Path 'D:\installs' -ItemType Directory -Force
systeminfo  | findstr /C:'Host Name' /C:'System Model' /C:'System Type' /C:’Total Physical Memory’ /c:’OS Name’ /C:’Processor(s)’ /C:’Network Card(s)’ | Out-File -FilePath $filename
if ((Get-ItemProperty HKLM:\System\CurrentControlSet\control\SecureBoot\State -ErrorAction SilentlyContinue) -eq $null ) {
"BIOS" | Out-File -FilePath $filename -Append
} else {
"UEFI" | Out-File -FilePath $filename -Append
} 

Set-DnsClientGlobalSetting -SuffixSearchList @("utility.pge.com", "comp.pge.com" ,"net.pge.com","pge.com")
Get-DnsClientGlobalSetting | Out-File -FilePath $filename -Append
Get-WMIObject -Query "SELECT * FROM Win32_Product Where Vendor Like '%VM%'" | FT | Out-File -FilePath $filename -Append
Get-HotFix | ? installedon -gt 1/1/2022  | Out-File -FilePath $filename -Append
Write-Host "Drive information for $env:ComputerName" 
Get-WmiObject -Class Win32_LogicalDisk |
    Where-Object {$_.DriveType -ne 5} |
    Sort-Object -Property Name | 
    Select-Object Name, VolumeName, VolumeSerialNumber,SerialNumber, FileSystem, Description, VolumeDirty, `
        @{"Label"="DiskSize(GB)";"Expression"={"{0:N}" -f ($_.Size/1GB) -as [float]}}, `
        @{"Label"="FreeSpace(GB)";"Expression"={"{0:N}" -f ($_.FreeSpace/1GB) -as [float]}}, `
        @{"Label"="%Free";"Expression"={"{0:N}" -f ($_.FreeSpace/$_.Size*100) -as [float]}} |
Format-Table -AutoSize | Out-File -FilePath $filename -Append 
Get-ADPrincipalGroupMembership (Get-ADComputer $env:ComputerName) | Where-Object{$_.Name -match 'SCCM'}|select-object @{N=’Patch Cycle’; E={$_.Name}}| Out-File -FilePath $filename -Append
Get-ADPrincipalGroupMembership (Get-ADComputer $env:ComputerName) | select-object | Out-File -FilePath $filename -Append
Add-LocalGroupMember -Group "Remote Desktop Users" -Member "L1-enocoperations"
Add-LocalGroupMember -Group "Remote Desktop Users" -Member "PS-2476-QA-Requestors"
Get-LocalGroupMember -Group "Remote Desktop Users" | select-object @{N=’Remote Desktop User Member’; E={$_.Name}} | Out-File -FilePath $filename -Append 
Get-LocalGroupMember -Group "Administrators" | select-object @{N=’LocalAdministrator Member’; E={$_.Name}} | Out-File -FilePath $filename -Append 
start windowsdefender:
C:\Windows\CCM\SCClient.exe
notepad.exe C:\Program Files\IBM\WinCollect\logs\wincollect.log
$adapter.SetTcpIPNetbios(1) | Select ReturnValue
$NICs = Get-WmiObject Win32_NetworkAdapter -filter "AdapterTypeID = '0' AND PhysicalAdapter = 'true' AND NOT Description LIKE '%wireless%' AND NOT Description LIKE '%virtual%' AND NOT Description LIKE '%WiFi%' AND NOT Description LIKE '%Bluetooth%'"
Foreach ($NIC in $NICs)
{
    $powerMgmt = Get-WmiObject MSPower_DeviceEnable -Namespace root\wmi | where {$_.InstanceName -match [regex]::Escape($nic.PNPDeviceID)}
    If ($powerMgmt.Enable -eq $True)
    {
         $powerMgmt.Enable = $False
         $powerMgmt.psbase.Put()
    }
}
services.msc
compmgmt.msc
get-service HealthService | select Displayname,Status,ServiceName,Can | Out-File -FilePath $filename -Append
    get-service WinCollect | select Displayname,Status,ServiceName,Can | Out-File -FilePath $filename -Append
    #Checking For TripWire Installed
$a = new-object -comobject wscript.shell
if (Test-Path -Path "C:\Program Files\Tripwire\TE\Agent\bin\uninstall.cmd") {
    "TripWire is Installed!"
} else {
    "TripWire is not present."
}
#Uninstall of TripWire
$shell = New-Object -ComObject "Shell.Application"
$shell.minimizeall()
start-sleep 5  # This is where the pop-up would be called.  It is just a placeholder.
$shell = New-Object -ComObject "Shell.Application"
$shell.undominimizeall()
$intAnswer = $a.popup("Do you want to uinstall TripWire?", `
0,"Delete Files",4)
If ($intAnswer -eq 6) {
  $a.popup("You answered yes.")
  Uninstall-Package -Name “Tripwire Enterprise Agent" 
} else {
  $a.popup("You answered no.")
}
notepad.exe $filename