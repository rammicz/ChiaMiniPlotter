$drive = New-PsDrive Z -PSProvider FileSystem -Root \\cirkus\share
$filter = "DeviceID='Z:'"
$disk = Get-CimInstance Win32_LogicalDisk -Filter $filter
$diskspace = [Math]::Round($disk.FreeSpace / 1GB) 
write-host $diskspace
Remove-PsDrive Z