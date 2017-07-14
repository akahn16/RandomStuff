$OrigVerbosePreference = $VerbosePreference
$VerbosePreference = "continue"

$Results = @()

# Get Computer Name
$ComputerName = $env:COMPUTERNAME

# Get Computer Mopdel
$ComputerModel = Get-WmiObject Win32_ComputerSystem | Select-Object -ExpandProperty Model

$StoreNVMEStatus = (Get-Service StorNVME).Status


# Get System Drive Details
$DriveInfo = Get-WmiObject Win32_DiskDrive | % {
  $disk = $_
  $partitions = "ASSOCIATORS OF " +
                "{Win32_DiskDrive.DeviceID='$($disk.DeviceID)'} " +
                "WHERE AssocClass = Win32_DiskDriveToDiskPartition"
  Get-WmiObject -Query $partitions | % {
    $partition = $_
    $drives = "ASSOCIATORS OF " +
              "{Win32_DiskPartition.DeviceID='$($partition.DeviceID)'} " +
              "WHERE AssocClass = Win32_LogicalDiskToPartition"
    Get-WmiObject -Query $drives | % {
      New-Object -Type PSCustomObject -Property @{
        Disk        = $disk.DeviceID
        DiskSize    = $disk.Size
        DiskModel   = $disk.Model
        DiskInterface = $disk.InterfaceType
        Partition   = $partition.Name
        RawSize     = $partition.Size
        DriveLetter = $_.DeviceID
        VolumeName  = $_.VolumeName
        Size        = $_.Size
        FreeSpace   = $_.FreeSpace
      }
    }
  }
}
$DriveInfo = $DriveInfo | Where-Object {$_.DriveLetter -eq "C:"}

# Run WinSAT Disk Test and Output Results

if (!($output)) { $output = winsat.exe diskformal }

$tmp = $output -match "Disk  Sequential"
$matches = ([regex]"Disk\s+Sequential\s+(\d+\.\d+)\s+Read\s+(\d+\.\d+)\s+(\S+)\s+(\d+\.\d+)").match($tmp)
if ($matches) {
    $CustomEvent = New-Object -TypeName PSObject
    $CustomEvent | Add-Member -Type NoteProperty -Name "Computer" -Value $ComputerName
    $CustomEvent | Add-Member -Type NoteProperty -Name "ComputerModel" -Value $ComputerModel
    $CustomEvent | Add-Member -Type NoteProperty -Name "Test" -Value "Disk Sequential"
    $CustomEvent | Add-Member -Type NoteProperty -Name "DriveLetter" -Value $DriveInfo.DriveLetter
    $CustomEvent | Add-Member -Type NoteProperty -Name "InterfaceType" -Value $DriveInfo.DiskInterface
    $CustomEvent | Add-Member -Type NoteProperty -Name "DiskModel" -Value $DriveInfo.DiskModel
    $CustomEvent | Add-Member -Type NoteProperty -Name "Size" -Value $matches.Groups[1]
    $CustomEvent | Add-Member -Type NoteProperty -Name "Speed" -Value $matches.Groups[2]
    $CustomEvent | Add-Member -Type NoteProperty -Name "Units" -Value $matches.Groups[3]
    $CustomEvent | Add-Member -Type NoteProperty -Name "Score" -Value $matches.Groups[4]
    $CustomEvent | Add-Member -Type NoteProperty -Name "StoreNVMESvc" -Value $StoreNVMEStatus

    $Results += $CustomEvent
}

$tmp = $output -match "Disk  Random"
$matches = ([regex]"Disk\s+Random\s+(\d+\.\d+)\s+Read\s+(\d+\.\d+)\s+(\S+)\s+(\d+\.\d+)").match($tmp)
if ($matches) {
    $CustomEvent = New-Object -TypeName PSObject
    $CustomEvent | Add-Member -Type NoteProperty -Name "Computer" -Value $ComputerName
    $CustomEvent | Add-Member -Type NoteProperty -Name "ComputerModel" -Value $ComputerModel
    $CustomEvent | Add-Member -Type NoteProperty -Name "Test" -Value "Disk Random"
    $CustomEvent | Add-Member -Type NoteProperty -Name "DriveLetter" -Value $DriveInfo.DriveLetter
    $CustomEvent | Add-Member -Type NoteProperty -Name "InterfaceType" -Value $DriveInfo.DiskInterface
    $CustomEvent | Add-Member -Type NoteProperty -Name "DiskModel" -Value $DriveInfo.DiskModel
    $CustomEvent | Add-Member -Type NoteProperty -Name "Size" -Value $matches.Groups[1]
    $CustomEvent | Add-Member -Type NoteProperty -Name "Speed" -Value $matches.Groups[2]
    $CustomEvent | Add-Member -Type NoteProperty -Name "Units" -Value $matches.Groups[3]
    $CustomEvent | Add-Member -Type NoteProperty -Name "Score" -Value $matches.Groups[4]
    $CustomEvent | Add-Member -Type NoteProperty -Name "StoreNVMESvc" -Value $StoreNVMEStatus
    $Results += $CustomEvent
}

$Results | Out-GridView

$VerbosePreference = $OrigVerbosePreference`
