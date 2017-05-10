
Param
(
    [Parameter(Mandatory=$true,Position=0)]
    [String]$MOCN="",
	[Parameter(Mandatory=$true,Position=1)]
	[String]$Drive=""
	
)
$dest="$Drive"+':\Program Files\Microsoft Learning\VMs\' + "$MOCN" +"\"+"Drives"+"\"

Get-VM $MOCN*|Move-VMStorage -DestinationStoragePath ("$dest"+"$PSItem.Name")
