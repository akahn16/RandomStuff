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
        exit
    } else {
        Write-Verbose "Power scheme requires change from ($($ActiveScheme)) to ($($SchemeName))."
        $SchemeGuid = Get-PowerScheme-Guid -SchemeName $SchemeName
        write-Debug "Executing PowerCfg.exe /SETACTIVE $($SchemeGuid)"
        $output = & powercfg.exe /SETACTIVE $SchemeGuid
        $ActiveScheme = Get-PowerScheme-Active
    }
    return $ActiveScheme
}

<# Built-In Power Schemes: 
"Power saver"
"Balanced"
"High performance"
#>

Set-PowerScheme -SchemeName "Power saver"
Set-PowerScheme -SchemeName "Balanced"
Set-PowerScheme -SchemeName "High performance"

$VerbosePreference = $OrigVerbosePreference
$DebugPreference = $OrigDebugPreference

