$OrigDebugPreference = $DebugPreference
$DebugPreference = "Continue"

$OrigVerbosePreference = $VerbosePreference
$VerbosePreference = "Continue"

$hostfilepath = "C:\Windows\System32\drivers\etc\hosts"
if (!(Test-Path -Path $hostfile)) {
    Write-Host "hosts file [$($hostfile)] not found; exiting."
    exit
}

function check-hostfile-entry {
    param($hostfilepath,$ip,$name)

    # initialize variable to return
    $linematch = $false

    # check to see if entry pattern is present in hosts file
    $hostfilecontent = Get-Content -Path $hostfilepath
    $matchresults = $hostfilecontent -imatch "($($ip).*$($name))"

    if ($matchresults)  {
        Write-verbose "found $($matchresults.count) possible match(es) in hostfile already."
    
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
                    Write-verbose "entry [$($matchresult)] is not commented."
                    $entryExactAndActive = $true
                }
            }           
        }
    }
    return $linematch = $matchresult
}

function set-hostfile-entry {
    param($hostfilepath,$ip,$name)
    Add-Content -Path $hostfilepath -Value "$($ip)`t$($name)"
}

function remove-hostfile-entry {
    param($hostfilepath,$linetoremove)

    $hostfilecontent = Get-Content -Path $hostfilepath
    remove-item -path $hostfilepath -Force

    foreach ($line in $hostfilecontent) {
        if ($line -inotmatch $linetoremove) {
            Add-Content -Path $hostfilepath -Value $line -Force
        }        
    }
}


# array of entries in "ip;name;action" format.  valid actions are "add" or "remove"
$entries=@(
 "255.255.255.255;wpad;add"
 "255.255.255.255;wpad2;add"
 "255.255.255.255;wpad3;remove"
 )

# loop through desired entries
Write-Verbose "processing $($entries.count) entries."
$counter = 0
foreach ($entry in $entries) {
    $counter++
    $ip = ($entry.split(";")[0]).trim()
    $name = ($entry.split(";")[1]).trim()
    $action = ($entry.split(";")[2]).trim()


    Write-host "processing entry $($counter) of $($entries.count) [$($entry)]"

    # check to see if entry is already in hostfile
    $matchingline = check-hostfile-entry -hostfilepath $hostfilepath -ip $ip -name $name
    if (!($matchingline)) {
        if ($action -ieq "remove") {
            Write-host "-entry not present; skipping."
        }
        if ($action -ieq "add") {
            Write-host "-entry is not present; adding."
            set-hostfile-entry -hostfilepath $hostfilepath -ip $ip -name $name
        }
    } else {
        if ($action -ieq "remove") {
            Write-host "-entry is present; removing."
            remove-hostfile-entry -hostfilepath $hostfilepath -linetoremove $matchingline
        }
        if ($action -ieq "add") {
            Write-host "-entry is already present; skipping."
        }
    }
}

$DebugPreference = $OrigDebugPreference
$VerbosePreference = $OrigVerbosePreference