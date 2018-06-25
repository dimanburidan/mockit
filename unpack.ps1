# import-prepare-v0.4.ps1     #
# Copyleft 2018               #
# A MOC Deploy Solution       #
# Created by Dmitry Mischenko #
# dmitrymis@outlook.com       #

Param
(
    [Parameter(Mandatory=$true,Position=1)]
	[String]$Source="d:\Microsoft Learning\moc",
    
    [Parameter(Mandatory=$false,Position=2)]
	[String]$Dest="C:\Program Files\Microsoft Learning",



#We can Unpack files or copy already unpacked files script assumes, that you have 7-zip or WinRar installed on x64 computer.

if ($Unpack -eq "True")
 {
 
 if (Test-Path  "C:\Program Files\WinRAR\UnRaR.exe" )
 {
  #Unrar file exists, so we can use it
  cmd.exe -c "C:\Program Files\WinRAR\UnRaR.exe" x -r "$Source\*.exe" "$Dest"
 } 
  elseif (Test-Path "C:\Program Files\7zip\7z.exe" )
 {
  cmd.exe -c "C:\Program Files\7zip\7z.exe" x -o "$Dest" "$Source\*.exe"
 }
}

