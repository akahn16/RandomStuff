###########################################################
### PARAMETERS
###########################################################

Param
(
    # Param1 help description
    [Parameter(Mandatory=$true, 
                Position=0,
                ParameterSetName='action')]
    [ValidateNotNull()]
    [ValidateNotNullOrEmpty()]
    [ValidateSet("remove", "add")]
    $action,

    # Param2 help description
    [ValidatePattern("\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}")]
    [ValidateLength(6,15)]
    [ValidateNotNull()]
    [ValidateNotNullOrEmpty()]
    [String]
    $ip,
    
    # Param3 help description
    [ValidatePattern("\w+")]
    [ValidateNotNull()]
    [ValidateNotNullOrEmpty()]
    [String]
    $name
)



###########################################################
### FUNCTIONS
###########################################################

function check-hostfile-entry {
    param($hostfile,$ip,$name)

    # initialize variable to return
    $linematch = @()

    # check to see if entry pattern is present in hosts file
    $hostfilecontent = Get-Content -Path $hostfile
    $matchresults = $hostfilecontent -imatch "($($ip).*$($name))"

    if ($matchresults)  {
        Write-verbose "found $($matchresults.count) pattern match(es) already in hostfile."
    
        # enumerate each possible match
        foreach ($matchresult in $matchresults) {           
            Write-verbose "inspecting content of hostfile entry [$($matchresult)]."

            # get rid of whitepaces
            $matchresulttrimmed = $matchresult.trim()

            # check to ensure entry name is exact
            if ($matchresulttrimmed -imatch "(\s{1}$($name)$)") {
                Write-verbose "entry [$($matchresult)] is an exact match on name."                    

                # check to ensure that exact entry is not commented (first non-whitepace is comment char)
                if (!($matchresulttrimmed -imatch "(\s*#)")) {
                    Write-verbose "entry [$($matchresult)] is active (not commented)."
                    $linematch += $matchresult
                } else {
                    Write-verbose "entry [$($matchresult)] is not active (commented)."
                }
            } else {
                Write-verbose "entry [$($matchresult)] is not an exact match on name."
            }
        }
    }
    return $linematch
}

function set-hostfile-entry {
    param($hostfile,$ip,$name)
    Add-Content -Path $hostfile -Value "$($ip)`t$($name)"
}

function remove-hostfile-entry {
    param($hostfile,$linetoremove)

    $hostfilecontent = Get-Content -Path $hostfile
    remove-item -path $hostfile -Force

    foreach ($line in $hostfilecontent) {
        if ($line -inotmatch $linetoremove) {
            Add-Content -Path $hostfile -Value $line -Force
        }        
    }
}



###########################################################
### MAIN
###########################################################

$OrigDebugPreference = $DebugPreference
$DebugPreference = "Continue"

$OrigVerbosePreference = $VerbosePreference
$VerbosePreference = "Continue"

$hostfile = "C:\Windows\System32\drivers\etc\hosts"
if (!(Test-Path -Path $hostfile)) {
    Write-Host "hosts file [$($hostfile)] not found; exiting."
    exit
}

# check to see if entry is already in hostfile
$matchinglines = @()
$matchinglines = check-hostfile-entry -hostfile $hostfile -ip $ip -name $name

if (!($matchinglines)) {
    if ($action -ieq "add") {
        set-hostfile-entry -hostfile $hostfile -ip $ip -name $name
        Write-host "-entry added."
    }   
    if ($action -ieq "remove") {
        Write-host "-entry not present."
    }    
     
} else {
    foreach ($matchingline in $matchinglines) {

        if ($action -ieq "remove") {
            remove-hostfile-entry -hostfile $hostfile -linetoremove $matchingline
            Write-host "-entry removed."
        }

        if ($action -ieq "add") {
            Write-host "-entry already present."
        }
    }
}

$DebugPreference = $OrigDebugPreference
$VerbosePreference = $OrigVerbosePreference
