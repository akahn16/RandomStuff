$msdnurl = 'https://msdn.microsoft.com/en-us/library/aa394363(v=vs.85).aspx'

$page = Invoke-WebRequest -Uri $msdnurl -MaximumRedirection 0

$outerText = ($page.ParsedHtml.body.outerText).split("`n")

$prevline = Out-Null
$counter = 1
$bNewSection = $False

<#
switch ($a) 
    { 
        1 {"The color is red."} 
        2 {"The color is blue."} 
        3 {"The color is green."} 
        4 {"The color is yellow."} 
        5 {"The color is orange."} 
        6 {"The color is purple."} 
        7 {"The color is pink."}
        8 {"The color is brown."} 
        default {"The color could not be determined."}
    }
#>

$lastSectionLine = Out-Null
foreach ($line in $outerText) {
    if ($line -match 'Data type:') {
        $section = $outerText[$counter-2]
        $section = $section.Substring(0,($section.Length - 2))
        $bNewSection = $True
    }

    if ($line -match '\(\d+\)[^, ]') {
        if ($bNewSection) {
            if ($lastSectionLine) { write-host $lastSectionLine ; write-host "    } " }
            write-host ""
            write-host "switch (`$$($Section)`)"
            write-host "    { "
            $bNewSection = $False
        }
        $text = $line -replace " \(\d+\)",""
        $number = $line.Split("(")[1]
        $number = $number.Split(")")[0]
        write-host "        $($number) `{ `$$($section)Text `=  `"$($text)`" `}"
        $lastSectionLine = "        default `{ `$$($section)Text `=  `"unknown`" `}"
    }

    $counter++
}
if ($lastSectionLine) { write-host $lastSectionLine ; write-host "    } " }