
#$removeall = { 

Import-Module Hyper-V
get-VM * |Stop-VM -Force -TurnOff -AsJob
get-vm * |Get-VMHardDiskDrive |Remove-VMHardDiskDrive 
get-VM * |Remove-VM -Force 
Get-VMSwitch * |Remove-VMSwitch -Force 
Get-Item "C:\Program Files\Microsoft Learning\*" |Remove-Item -Force -Recurse
#}


#Invoke-Command -ComputerName ws01-cl03-nsk01 -ScriptBlock $removeall
