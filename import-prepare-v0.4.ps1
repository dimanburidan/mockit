# import-prepare-v0.4.ps1     #
# Copyleft 2018               #
# A MOC Deploy Solution       #
# Created by Dmitry Mischenko #
# dmitrymis@outlook.com       #

Param
(
    [Parameter(Mandatory=$true,Position=0)]
    [String]$MOCN="1234A",

    [Parameter(Mandatory=$true,Position=1)]
	[String]$SourcePath="d:\Microsoft Learning\moc",
    
    [Parameter(Mandatory=$false,Position=2)]
	[String]$DestPath="C:\Program Files\Microsoft Learning",
                
    [Parameter(Mandatory=$false)]
    [switch]$NocopyVM,
    
    [Parameter(Mandatory=$false)]
    [switch]$NocopyBASE,

    [Parameter(Mandatory=$false)]
    [switch]$Norepack,    
    
    [Parameter(Mandatory=$false)]
    [switch]$NoRearm,
    
    [Parameter(Mandatory=$false)]
    [switch]$NoStartingImage,

    [Parameter(Mandatory=$false)]
    [String]$Password="Pa`$`$w0rd",    

    [Parameter(Mandatory=$false)]
    [switch]$Restart

)

$host.UI.RawUI.BackgroundColor = "Black"; Clear-Host
# Elevate
Write-Host "Checking for elevation... " -NoNewline
$CurrentUser = New-Object Security.Principal.WindowsPrincipal $([Security.Principal.WindowsIdentity]::GetCurrent())
if (($CurrentUser.IsInRole([Security.Principal.WindowsBuiltinRole]::Administrator)) -eq $false)  {
    $ArgumentList = "-noprofile -noexit -file `"{0}`" -Path `"$Path`""
    If ($DeploymentOnly) {$ArgumentList = $ArgumentList + " -DeploymentOnly"}
    Write-Host "elevating"
    Start-Process powershell.exe -Verb RunAs -ArgumentList ($ArgumentList -f ($myinvocation.MyCommand.Definition))
    Exit
}

$Host.UI.RawUI.BackgroundColor = "Black"; Clear-Host
$StartTime = Get-Date
$Validate = $true

Write-Host ""
Write-Host "Start time:" (Get-Date)


function convert-vhd-my ([string]$vhdpath) 
{
        $vhdxpath =$vhdpath+"x"
        If (Test-Path $vhdxpath)
            { 
                # "We will delete existing vhdx on path $vhdxpath"
                Remove-Item $vhdxpath
            }

        $vhd= Mount-VHD -Path $vhdpath -Passthru -NoDriveLetter -ReadOnly
        
        $vhdx=New-VHD -Path $vhdxpath -Dynamic -SourceDisk $vhd.Number
        Dismount-VHD $vhdpath
        #vhdx with 4k may have some good performance effect on AF disks
		#have compability problem with Exchange 2010 DAG. 
        Set-VHD -Path $vhdx.Path -PhysicalSectorSizeBytes 4096
        [string]$vhdx.Path
}

function prepare-vol ($vl,$filename,$content)
{
    $DL = $vl.DriveLetter + "`:"
	New-item -type file "$DL\ProgramData\Microsoft\Windows\Start Menu\Programs\StartUp\$filename"  -Force -Value $content
	reg load HKLM\TempHive $DL\Windows\System32\config\SOFTWARE
	$regkey = "HKLM:\TempHive\Microsoft\Windows\CurrentVersion\Authentication\LogonUI"
	$useranddomain= get-itemproperty -path $regkey -name LastLoggedOnSAMUser
	$user = ($useranddomain.LastLoggedOnSAMUser).split("\").item(1)
	$domain = ($useranddomain.LastLoggedOnSAMUser).split("\").item(0)
	$regkey = "HKLM:\TempHive\Microsoft\Windows NT\CurrentVersion\Winlogon"
	set-itemproperty -path $regkey -name AutoAdminLogon -value 1
	set-itemproperty -path $regkey -name DefaultUserName -value $user
	set-itemproperty -path $regkey -name DefaultPassword -value $Password
	set-itemproperty -path $regkey -name DefaultDomainName -value $domain
	$regkey = "HKLM:\TempHive\Microsoft\Windows\CurrentVersion\RunOnce" 
	set-itemproperty -Path $regkey  -name $filename -value "c:\ProgramData\Microsoft\Windows\Start Menu\Programs\StartUp\$filename"
	[gc]::collect()
	reg unload HKLM\TempHive
	#Lets try add autologon bat file for administrator user account
	$ntuserpaths=Get-ChildItem "$DL\Users\Administrator*\NTUSER.DAT" -Force -Recurse -ErrorAction SilentlyContinue
	foreach ($ntuser in $ntuserpaths.Fullname)
		{
				Write-Host "reg load HKLM\TempHive $ntuser"
				reg load HKLM\TempHive "$ntuser"
				$regkey = "HKLM:\TempHive\Software\Microsoft\Windows\CurrentVersion\Policies\System"
				#some vms disable registry editing tools so try to enable it.
                set-itemproperty -Path $regkey -name DisableRegistryTools -value 0
				[gc]::collect()
				reg unload HKLM\TempHive
				}

}


$Host.UI.RawUI.BackgroundColor = "Black"; Clear-Host
$StartTime = Get-Date
$Validate = $true

Write-Host ""
Write-Host "Start time:" (Get-Date)

# $Sourcepach is a file share with files of MOC files.
# File can be a share, that must contain unpacked course vm files from Download Centre
# It files usually looks like
# \\fileserver\share\
#                  |- 1234A\             - we will name it $MOCN
#                  |       |- Drives\
#                  |-Base\
#                  |     |-Base???-W*.vhd
#                  |     |-Drives\
#                  |     |       |-WS*.vhd
#                  |     |       |-WS08R2-NYC-DC1.vhd

$MSDir= "C:\Program Files\Microsoft Learning"
$MOC=$MOCN.Substring(0,$MOCN.Length-1)

[string]$Source= "$SourcePath\$MOCN"
[string]$Dest="$DestPath\$MOC"


##
## Jason Kline
## CopyFiles-Bits.ps1
## 01/19/2015
##

function CopyFiles-Bits
{
# Set Parameters
Param (
[Parameter(Mandatory=$true)]
[String]$Source,
[Parameter(Mandatory=$true)]
[String]$Destination
)

# Read all directories located in the sorce directory
$dirs = Get-ChildItem -Name -Path $Source -Directory -Recurse
$files = Get-ChildItem -Name -Path $Source -File
# Start Bits Transfer for all items in each directory. Create Each directory if they do not exist at destination.

$exists = Test-Path $Destination
if ($exists -eq $false) {New-Item $Destination -ItemType Directory}

foreach ($f in $files)
    {
    $srcname = $source + "\" + $f.PSChildName
    $dstname = $Destination + "\" + $f.PSChildName
    Start-BitsTransfer -Source $srcname -Destination $Destination -Description "to $dstname" -DisplayName "Copying $srcname"
    }

foreach ($d in $dirs)
    {
    $srcsubdir = $Source +"\" + $d
    $dstsubdir = $Destination + "\" + $d
    
    $exists = Test-Path $dstsubdir
    if ($exists -eq $false) {New-Item $dstsubdir -ItemType Directory}
    
    $files = Get-ChildItem -Name -Path $srcsubdir -File
    foreach ($f in $files)
        {
        $srcfilename = $srcsubdir + "\" + $f.PSChildName
        $dstfilename = $dstsubdir + "\" + $f.PSChildName
        Start-BitsTransfer -Source $srcfilename -Destination $dstsubdir -Description "to $dstfilename" -DisplayName "Copying $srcfilename"
        }
   
    }

}


if(!($NocopyVM))
{
if (!(Test-Path $Source)) {throw "SourcePath seems do not exists or cannot connect"}
  Write-Verbose "lets copy all VM files that we need"
  mkdir "$Dest"
  mkdir "$Dest\Drives"
  CopyFiles-Bits "$Source\Drives\" "$Dest\Drives\"
  }

 
if(!($NocopyBASE))
{


# Check if hard links of Base files has already prepared with script Make-BaseHardlinks.bat
# If subdir Base exist then copy from if else we will parse txt's.
 
if (test-path "$Source\Base")
	{
	CopyFiles-Bits "$Source\Base" "$MSDir\Base"
	}
else
	{
	$TXTs = Get-ChildItem "$SourcePath\$MOCN\Drives" | ? {$_.FullName -like "*.txt"}

	foreach ($TxtFile in $TXTs)
		{
		#convert txt name to vhd name. Name of txt is like Base11A-WS08R2SP1.txt
		#We will change *.txt to *.vhd in name.
		$FirstDefis = $TxtFile.Name.IndexOf('-')
  		$Dot = $TxtFile.Name.IndexOf('.')
  		#$VHDName = $TxtFile.Name.Substring($FirstDefis+1,$Dot - $FirstDefis-1)+".vhd"
		$VHDName = $TxtFile.Name.Substring(0,$Dot)+".vhd"
  		If ($VHDName -like "*Base*")
  			{
			Start-BitsTransfer -Source "$SourcePath\Base\$VHDName" -Destination "$MSdir\Base\" -Description "to $MSdir\Base\$VHDName" -DisplayName "Copying $SourcePath\Base\$VHDName"
  			}
  		else
  			{
			Start-BitsTransfer -Source "$SourcePath\Base\Drives\$VHDName" "$MSdir\Base\Drives\" -Description "to $MSdir\Base\Drives\$VHDName" -DisplayName "Copying $SourcePath\Base\Drives\$VHDName"
  			}
		}
  
	}
}

# To make this script work please remove all Read-host and pause strings in original VM-Pre-Import-*.ps1 and *_ImportVirtualMachines.ps1 files, set $drive $drive2 variable with string "C".

# Lets create VM networks for $MOC 
powershell.exe -executionpolicy bypass -File "$MSDir\$MOC\Drives\CreateVirtualSwitches.ps1"

# Lets attach VM vhd to Base and middle vhd  
powershell.exe -executionpolicy bypass -File "$MSDir\$MOC\Drives\VM-Pre-Import-$($MOCN).ps1"

# Lets Import VMs
powershell.exe -executionpolicy bypass -File "$MSDir\$MOC\Drives\$($MOCN)_ImportVirtualMachines.ps1"


$vms = Get-VM "$MOCN*"

# Repack vhd files to vhdx and reconnect it to VM in not disabled by switch $repacktovhdx

if(!($Norepack))
{   
    foreach ($vm in $vms)
    {
    Write-host We will work with $vm.Name
    
    Write-host Before
    $vhd= Get-VMHardDiskDrive $vm | ? {$_.path -ilike "*vhd"}	
    $vhd |ft  Path,VhdFormat,VhdType,FileSize,Size,LogicalSect,PhysicalSec -AutoSize
    foreach ($v in $vhd )
     {
        
        $vhdxpath =convert-vhd-my $v.Path
       
        # "we will Re-Attach new vhdx to vm"
        Set-VMHardDiskDrive -VMName $v.VMName `
                            -Path $vhdxpath `
                            -ControllerType $v.ControllerType `
                            -ControllerNumber $v.ControllerNumber `
                            -Controllerlocation  $v.ControllerLocation
        
     }
    
    Write-host After
    $vhdx= Get-VMHardDiskDrive $vm
    $vhdx |ft  Path,VhdFormat,VhdType,FileSize,Size,LogicalSect,PhysicalSec -AutoSize
    }
}

$shutdown = '
rem plan to shutdown the system in 10 secs.
shutdown /s /c "system is prepared" /f /t 10
rem killing myself
del /f /q %0
'

$rearm = '
rem rearming windows
@cscript //nologo %windir%\System32\slmgr.vbs /rearm

rem Lets try to rearm office 2013 if present
"%ProgramFiles(x86)%\Microsoft Office\Office15\ospprearm.exe"

rem revert back start of server manager at logon
reg add "HKLM\Software\Microsoft\ServerManager" /v DoNotOpenServerManagerAtLogon /t REG_DWORD /f /d 0
	
rem Enable host to remote administration 
reg add "HKLM\System\CurrentControlSet\Control\Terminal Server" /v fDenyTSConnections /t REG_DWORD /f /d 0
rem Everyone can use remote desktop
net localgroup "remote desktop users" everyone /add

netsh advfirewall firewall set rule group="@FirewallAPI.dll,-28752" new enable=Yes
	
rem remove autoadminlogon
reg add    "HKLM\Software\Microsoft\Windows NT\CurrentVersion\Winlogon" /v AutoAdminLogon  /t REG_SZ /f /d 0
reg delete "HKLM\Software\Microsoft\Windows NT\CurrentVersion\Winlogon" /v DefaultUserName /f
reg delete "HKLM\Software\Microsoft\Windows NT\CurrentVersion\Winlogon" /v DefaultPassword /f
reg delete "HKLM\Software\Microsoft\Windows NT\CurrentVersion\Winlogon" /v DefaultDomainName /f

rem killing myself
del /f /q %0
'

if(!($NoRearm))
{


#Prepare each VM with autologon $rearm.bat file
foreach ($VM in $vms)  
	{
	 # Check for vhd's based of name.
     Write-host We will prepare $vm.Name
	 $vmvhd=$vm.HardDrives
	 foreach ($vhd in $vmvhd)
	 {
        $vh= Mount-VHD -Path $vhd.Path -Passthru 
        Start-Sleep -Seconds 3
        $disk = Get-Disk $vh.Number
        $part = $disk| Get-Partition
        # no partitions exist, so nothing to do
        if(!($part)) {Dismount-VHD -Path $vhd.Path; continue};


        $vol =  $part| Get-Volume                      # |?{$DL=$_.DriveLetter; New-PSDrive -Name $DL -PSProvider FileSystem -Root "$DL`:" ;Test-Path -PathType Container -Path "$DL`:\Windows" }
		

        foreach ($vl in $vol) 
		{
         $DL=$vl.DriveLetter
         New-PSDrive -Name $DL -PSProvider FileSystem -Root "$DL`:"
		 if(Test-Path -PathType Container -Path "$DL`:\Windows")
         {
          prepare-vol $vl rearm.cmd $rearm
          prepare-vol $vl shutdown.cmd $shutdown

         }
         Remove-PSDrive $DL
		}
        Dismount-VHD -Path $vhd.Path
     }

     Start-VM $VM
     Write-Host we will wait until $VM.Name is started, apply rearm and then shutdown.
     do {Start-Sleep -milliseconds 300} 
      until ($VM.state -eq "Off")
     }
}


# Lets create StartingImage snapshot on all $VM
if(!($NoStartingImage)) { foreach ($VM in $vms) { Checkpoint-VM $VM -SnapshotName StartingImage }; };

