## When using or sharing this script I am only asking you to have this message still in place
Write-host "#####################################################" -ForegroundColor Green -BackgroundColor Black
Write-host "##                                                 ##" -ForegroundColor Green -BackgroundColor Black
Write-host "##   ChiaMiniPlotter.ps1 v1.0  by  JIRI HERNIK     ##" -ForegroundColor Green -BackgroundColor Black
Write-host "##                                                 ##" -ForegroundColor Green -BackgroundColor Black
Write-host "## Need help setting up your own plotting machine? ##" -ForegroundColor Green -BackgroundColor Black
Write-host "##     Contact me on on rammi.cz@gmail.com         ##" -ForegroundColor Green -BackgroundColor Black
Write-host "##                                                 ##" -ForegroundColor Green -BackgroundColor Black
Write-host "##   Have you farmed some Chia with this script?   ##" -ForegroundColor Green -BackgroundColor Black
Write-host "##  It had cost me a blood and tears to write it.  ##" -ForegroundColor Green -BackgroundColor Black
Write-host "##            Please consider donation.            ##" -ForegroundColor Green -BackgroundColor Black
Write-host "##                                                 ##" -ForegroundColor Green -BackgroundColor Black
Write-host "#####################################################" -ForegroundColor Green -BackgroundColor Black
Write-host ""
Write-host "Donation addresses:"
Write-host "XCH: xch1jen5pdwk8gh2cvntkk2rctzs4fl5gda2p39kzyavg778alpaxxzsje7t3u" 
Write-host "LTC: ltc1qax73qnnn2dd0e3e5htgluawun7kvrq60nwr62w"
Write-host "BTC: bc1qh7urn8upqn9cue9450f563ez4krncz7qa3cge2"
Write-host ""
Write-host "You can find latest version on "
Write-host "https://github.com/rammicz/ChiaMiniPlotter"
Write-host ""
Write-host "Initializing..."

$ErrorActionPreference = "Stop";
$scriptpath = $MyInvocation.MyCommand.Path
$dir = Split-Path $scriptpath
Push-Location $dir
$processes = @{}
$nextSpinup = @{}
$chiaPath
function ChiaMiniPlotter()
{
    $target = ""
    $oldTarget = ""
    $oldConfigFile = $null
    while($true)
    {
        $configFile = Get-Content -Raw -Path ".\ChiaMiniPlotter.json" -ErrorAction Stop

        if($oldConfigFile -ne $configFile)
        {
            $configJson = $configFile | ConvertFrom-Json
            writeout -text "Config loaded." -ForegroundColor white
            $oldConfigFile = $configFile
        }

        $chiaPath = $configJson.chiaPath
        if($target -eq "" -or (checkSpace -path $target -minimalFreeSpace 1000) -eq $false )
        {
            foreach($checkTarget in $configJson.targets)
            {
                if(checkSpace -path $checkTarget -minimalFreeSpace 1000)
                {
                    if($oldTarget -ne $checkTarget)
                    {
                        Write-Host "Changing current target path to $checkTarget"
                        $target = $checkTarget
                    }
                    break
                }else {
                    Write-Host "Not enough space on target"
                }
            }
        }

        if($target -eq "")
        {
            Write-host "Not enough space on all targets, this is end." -ForegroundColor Red
            exit
        }
        
        $oldTarget = $target

        for($configReload=1; $configReload -le 10; $configReload++)
        {
            foreach($plotter in $configJson.plotters)
            {
                for($i=1; $i -le $plotter.plotters; $i++)
                {
                    runPlotter -ssd $plotter.ssd -ssd2 $plotter.ssd2 -instanceNumber $i -targetPath $target -spinupDelayMinutes $plotter.spinupMinutes -threads $plotter.threads -ram $plotter.ram 
                }
            }
            
            start-sleep -s 10
        }

        # Send Shift+F15 
        $wsh = New-Object -ComObject WScript.Shell
        $wsh.SendKeys('+{F15}')
    }
}

function runPlotter()
{
    param (
        $ssd, $ssd2, $instanceNumber, $targetPath, $spinupDelayMinutes, $threads, $ram
    )
    $processKey = $ssd + $instanceNumber
    if($processes.ContainsKey($processKey))
    {
        $process = $processes[$processKey]
        if($process.HasExited)
        {
            $diff= New-TimeSpan -Start $process.StartTime -End $process.ExitTime
            if($process.ExitCode -eq 0)
            {
                writeout -text "$($processKey) Finished - processing time: $([Math]::Floor(($diff.TotalHours))):$([Math]::Round($diff.Minutes))" -ForegroundColor Green
            }else {
                writeout -text "$($processKey) Failed exitcode $($process.ExitCode) processing time: $([Math]::Floor(($diff.TotalHours))):$([Math]::Round($diff.Minutes))" -ForegroundColor Red
            }
            
            $processes.Remove($processKey)
        }else {
            return
        }
    }
    
    if(!$nextSpinup.ContainsKey($ssd) -or (get-date $nextSpinup[$ssd]) -le (Get-Date))
    {
        $tempFolder = checkTemp -diskletter $ssd -instanceNumber $instanceNumber -tempsuffix ""
        $temp2Folder = checkTemp -diskletter $ssd2 -instanceNumber $instanceNumber -tempsuffix "2"

        if($tempFolder -ne "")
        {
            $processes[$processKey] = createPlotterProcess -tempFolder $tempFolder -targetPath $targetPath -instanceNumber $instanceNumber -threads $threads -ram $ram -temp2 $temp2Folder
            $nextSpinup[$ssd] = (Get-Date).AddMinutes($spinupDelayMinutes)
        }
    }
}

function checkTemp()
{
    param(
        $diskletter, $instanceNumber, $tempsuffix
    )

    if($diskletter -ne $null)
    {
        $tempFolder = $($diskletter) + ":\chia" + $($tempsuffix) + "_" + $($instanceNumber)
        if (Test-Path -Path $tempFolder) {
            writeout -text "removing $tempFolder" -ForegroundColor Magenta
            rd $tempFolder -Recurse
        }

        if(checkspace -path $tempFolder -minimalFreeSpace 240 -eq)
        {
            return $tempFolder
        }
    }
    return ""
}

function createPlotterProcess()
{
    param (
        $tempFolder, $targetPath, $instanceNumber, $threads, $ram, $temp2
    )

    $process = $null
    if($temp2 -ne "")
    {
        $process = start-process $chiaPath -ArgumentList "plots create -k 32 -r $threads -b $ram -t $tempFolder -2 $temp2 -d $targetPath" -passthru
    }else {
        $process = start-process $chiaPath -ArgumentList "plots create -k 32 -r $threads -b $ram -t $tempFolder -d $targetPath" -passthru
    }
    writeout -text "$($processKey) STARTED PID: $($process.Id)" -ForegroundColor Green
    return $process
}

function checkSpace()
{
    param ($path, $minimalFreeSpace)

    $diskLetter = $path.substring(0,1).ToUpper()
    if($diskLetter -ne "\")
    {
        $filter = "DeviceID='" + $diskLetter + ":'"
        $disk = Get-CimInstance Win32_LogicalDisk -Filter $filter
        $diskspace = [Math]::Round($disk.FreeSpace / 1GB) 
        if($diskspace -le $minimalFreeSpace)
        {
            writeout -text "$($diskLetter): Not enough free space $diskSpace GB of $minimalFreeSpace GB" -ForegroundColor red
            return $false
        }
    }

    return $true
}

function writeout()
{
    param($text, $ForegroundColor)
    $date = Get-Date -Format("yyyy-MM-dd HH:mm:ss")
    write-host $($date) $text -ForegroundColor $ForegroundColor
}

ChiaMiniPlotter