
Param
(
    [Parameter(Mandatory=$true,Position=0)]
    [String]$vm="",
	[Parameter(Mandatory=$true,Position=1)]
	[String]$NewPath=""
	
)
#$dest="$Drive"+':\Program Files\Microsoft Learning\VMs\' + "$MOCN" +"\"+"Drives"+"\"

Get-VM $vm|Move-VMStorage -DestinationStoragePath ("$NewPath"+"\"+"{$_.Name}")
