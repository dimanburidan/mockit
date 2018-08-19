


if ((Get-VMSwitch | ? {$_.name -eq "Private Network"}).count -ne 0)
{
$VMSwitch = Get-VMSwitch "Private Network"| ? {$_.SwitchType -eq "Private"} | Set-VMSwitch -SwitchType Internal 
}
else
{
$VMSwitch = New-VMSwitch -SwitchName "Private Network" -SwitchType Internal
}

if ((Get-NetIPAddress -IPAddress "172.16.0.1").count -eq 0)
{
New-NetIPAddress -IPAddress 172.16.0.1 -PrefixLength 16 -InterfaceIndex $($(get-netadapter -Name "vEthernet ($($VMSwitch.Name))").ifIndex)
}

if ((Get-NetNat | ? {$_.InternalIPInterfaceAddressPrefix -eq "172.16.0.0/16" }).count -eq 0)
{
 New-NetNat -Name NatNetwork -InternalIPInterfaceAddressPrefix 172.16.0.0/16
}
