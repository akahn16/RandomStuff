$OrigVerbosePreference = $VerbosePreference
$OrigDebugPreference = $DebugPreference
$VerbosePreference = "Continue"
$DebugPreference = "Continue"

function Get-PowerScheme-Active {
    $output = & powercfg.exe LIST
    $output = $output -imatch "(^Power Scheme GUID.*)\*$"
    $output = $output.split("(")[1]
    $ActiveScheme = $output.split(")")[0]
    return $ActiveScheme
}

function Get-PowerScheme-Guid {
    param ($SchemeName)
    $output = & powercfg.exe LIST
    $output = $output -imatch "(^Power Scheme GUID.*)"
    $output = $output -imatch "(\($($SchemeName)\))"
    $SchemeGuid = ([regex]"(\w+-\w+-\w+-\w+-\w+)").match($output).Groups[1].Value
    return $SchemeGuid   
}

function Set-PowerScheme {
    param ($SchemeName)
    $ActiveScheme = Get-PowerScheme-Active
    if ($ActiveScheme -eq $SchemeName) {
        Write-Verbose "Power scheme is already in the desired state ($($SchemeName))."
    } else {
        Write-Verbose "Power scheme requires change from ($($ActiveScheme)) to ($($SchemeName))."
        $SchemeGuid = Get-PowerScheme-Guid -SchemeName $SchemeName
        write-Debug "Executing PowerCfg.exe /SETACTIVE $($SchemeGuid)"
        $output = & powercfg.exe /SETACTIVE $SchemeGuid
        $ActiveScheme = Get-PowerScheme-Active
    }
    return $ActiveScheme
}

function Get-ChasisType-Desc {
    $ChassisTypes = Get-WmiObject -Class Win32_SystemEnclosure | Select-Object -ExpandProperty ChassisTypes

    switch ($ChassisTypes)
        { 
            1 { $ChassisTypesText =  "Other" }
            2 { $ChassisTypesText =  "Unknown" }
            3 { $ChassisTypesText =  "Desktop" }
            4 { $ChassisTypesText =  "Low Profile Desktop" }
            5 { $ChassisTypesText =  "Pizza Box" }
            6 { $ChassisTypesText =  "Mini Tower" }
            7 { $ChassisTypesText =  "Tower" }
            8 { $ChassisTypesText =  "Portable" }
            9 { $ChassisTypesText =  "Laptop" }
            10 { $ChassisTypesText =  "Notebook" }
            11 { $ChassisTypesText =  "Hand Held" }
            12 { $ChassisTypesText =  "Docking Station" }
            13 { $ChassisTypesText =  "All in One" }
            14 { $ChassisTypesText =  "Sub Notebook" }
            15 { $ChassisTypesText =  "Space-Saving" }
            16 { $ChassisTypesText =  "Lunch Box" }
            17 { $ChassisTypesText =  "Main System Chassis" }
            18 { $ChassisTypesText =  "Expansion Chassis" }
            19 { $ChassisTypesText =  "SubChassis" }
            20 { $ChassisTypesText =  "Bus Expansion Chassis" }
            21 { $ChassisTypesText =  "Peripheral Chassis" }
            22 { $ChassisTypesText =  "Storage Chassis" }
            23 { $ChassisTypesText =  "Rack Mount Chassis" }
            24 { $ChassisTypesText =  "Sealed-Case PC" }
            default { $ChassisTypesText =  "Unknown" }
        }

    return $ChassisTypesText
}

function Get-ComputerSystem-Model {
    $ComputerSystemModel = Get-WmiObject -Class Win32_ComputerSystem | Select-Object -ExpandProperty Model
    return $ComputerSystemModel
}

$BuiltInPowerSchemes = @("Power saver","Balanced","High performance")
$ChassisBlacklist = @("Portable","Laptop","Notebook","Hand Held","Sub Notebook")
$ModelBlacklist = @("Latitude E6510")

$ChassisTypeText = Get-ChasisType-Desc
$ComputerSystemModel = Get-ComputerSystem-Model

$DesiredScheme = "High performance"

if (($ChassisBlacklist -imatch "(^$($ChassisTypeText)$)") -or ($ModelBlacklist -imatch "(^$($ComputerSystemModel)$)")) {
    write-host "Skipped changing power scheme to [$($DesiredScheme)] on system model [$($ComputerSystemModel)] with chassis type [$($ChassisTypeText)] due to model or chassis blacklist."
} else {    
    write-host "Changing power scheme to [$($DesiredScheme)] on system model [$($ComputerSystemModel)] with chassis type [$($ChassisTypeText)]."
    $Scheme = Set-PowerScheme -SchemeName $DesiredScheme
}

$VerbosePreference = $OrigVerbosePreference
$DebugPreference = $OrigDebugPreference

