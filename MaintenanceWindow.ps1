$OrigVerbosePreference = $VerbosePreference
$OrigDebugPreference = $DebugPreference
$VerbosePreference = "Continue"
$DebugPreference = "Continue"
<#
.Synopsis
   Maintenance window manager
.DESCRIPTION
   -Verify we are initiated by a scheduled task between 00:00 and 05:00 (done)
   -Verify that host has not rebooted already within maintenance window (done)
   -Sleep random number of seconds between now and 0500 (done)
   -Verify that windows update is not in progress
   -Verify that a user is not logged on 
   -Verify that setup is not in progress
   -Verify that windows installer is not in progress
   -Initiate group policy update
   -Restart
#>

# Verify we are initiated by a scheduled task between 00:00 and 05:00 (done)
[int]$hour = get-date -format HH
$maintHourStart = 0
$maintHourEnd = 5

#
#if (!($hour -ge $maintHourStart -and $hour -lt $maintHourEnd)) { 
#    write-host "script has been executed outside of maintenance window, exiting."
#    exit
#}


# Verify that host has not rebooted already within maintenance window (done)
$secondsSinceMidnight = [int](new-timespan -start "00:00" -end (get-date)).TotalSeconds
Write-debug "The number of seconds since midnight is $($secondsSinceMidnight)."

$LastBootupTime = (Get-CimInstance -ClassName Win32_OperatingSystem -ErrorAction SilentlyContinue).LastBootupTime
$secondsSinceLastBootupTime = [int](new-timespan -start $LastBootupTime -end (get-date)).TotalSeconds
Write-debug "The number of seconds since LastBootupTime is $($secondsSinceLastBootupTime)."
if ($LastBootupTime -le $secondsSinceMidnight) {
    write-host "host has restarted since midnight already, exiting."
} else {
    Write-Verbose "host has not restarted since midnight."
}


# Sleep random number of seconds between now and 0500 (done)
$SecondsUntilMaintEnd = [int](New-TimeSpan -start (Get-Date) -end "0$($maintHourEnd):00").TotalSeconds
Write-Verbose "There are $($SecondsUntilMaintEnd) seconds until end of maintenance window"
    #Random time generator over a 5 hour period
    $RandomHour = Get-Random -Minimum 0 -Maximum 4
    $RandomMinute = Get-Random -Minimum 0 -Maximum 59
    $RandomSecond = Get-Random -Minimum 0 -Maximum 59
    #$RandomTime is in seconds
    $RandomTime = (($RandomHour * 3600) + ($RandomMinute * 60) + ($RandomSecond * 1))

# overide random wait for testing purposes
if ($DebugPreference -eq "Continue") {
    Write-Debug "Overriding sleep duration from $($RandomWait) to 5 seconds for testing"
    $RandomWait = 5
}

Write-Verbose "Sleeping for random duration of $($RandomWait) seconds."
$counter = 0
do
{
    $counter++
    sleep -Seconds 1
    Write-Verbose "slept for $($counter) of $($RandomWait) seconds.."   
}
until ($counter -eq $RandomWait)

while((get-process) -match "(explorer2)") {   
    write-host "windows shell (explorer) is running; a user is logged on. Waiting 60 seconds."
    sleep 60
}

# wait up to 5 minutes for any setups to complete.
while((get-process) -match "(msiexec|setup)") {   
    write-host "an install package is executing, waiting 60 seconds."
    sleep 60
}

# Cleanup debug related variables
$VerbosePreference = $OrigVerbosePreference
$DebugPreference = $OrigDebugPreference


# Initiating update with reboot option
write-host "initiating computer group policy update."
& gpupdate /target:computer /force /boot /sync

#write-host "restarting computer if gpupdate did already do so."
#Restart-Computer -Force



