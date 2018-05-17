$PrivateNetworkVirtualSwitchExists = ((Get-VMSwitch | where {$_.name -eq "Private Network" -and $_.SwitchType -eq "Private"}).count -ne 0)

# If statement to check if Private Switch already exists. If it does write a message to the host 
# saying so and if not create Private Virtual Switch
if ($PrivateNetworkVirtualSwitchExists -eq "True")
{
write-host "< Private Network >   ---- switch already Exists"
} 
else
{
$VMSwitch = New-VMSwitch -SwitchName "Private Network" -SwitchType Internal
New-NetIPAddress -IPAddress 172.16.0.1 -PrefixLength 16 -InterfaceIndex $($(get-netadapter -Name "vEthernet ($($VMSwitch.Name))").ifIndex)
New-NetNat -Name NatNetwork -InternalIPInterfaceAddressPrefix 172.16.0.0/16
}