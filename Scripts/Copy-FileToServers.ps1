<#
.SYNOPSIS
    Copies a file to the C$ share of a list of remote servers using PowerShell background jobs.

.DESCRIPTION
    This script reads a list of server hostnames from a text file and copies a specified file
    to the root C: drive of each server using background jobs. Logs each success or failure
    to a timestamped log file and prints a final summary.

.PARAMETER ServerListPath
    Path to the text file containing server names (one per line).

.PARAMETER SourceFile
    Full path to the local file to copy.

.PARAMETER LogPath
    Optional: full path to the log file. Defaults to a timestamped log in the current folder.

.EXAMPLE
    .\Copy-FileToServers.ps1 `
        -ServerListPath "C:\Servers\LSSList.txt" `
        -SourceFile "C:\Installers\app.exe"
#>

param (
    [Parameter(Mandatory)]
    [string]$ServerListPath,

    [Parameter(Mandatory)]
    [string]$SourceFile,

    [string]$LogPath = $(Join-Path -Path (Get-Location -PSProvider FileSystem).Path -ChildPath "CopyFileLog_$(Get-Date -Format 'yyyyMMdd_HHmmss').log")
)

function Write-Log {
    param (
        [string]$Message,
        [string]$Level = "INFO",
        [switch]$Silent
    )
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $line = "$timestamp [$Level] $Message"
    Add-Content -Path $LogPath -Value $line
    if (-not $Silent) {
        Write-Host $line
    }
}

Write-Log "Script started. Reading server list from $ServerListPath and copying file: $SourceFile" -Silent

#Validate input paths
if (-not (Test-Path $ServerListPath)) {
    Write-Log "❌ Server list file not found: $ServerListPath" -Level "ERROR"
    exit 1
}
if (-not (Test-Path $SourceFile)) {
    Write-Log "❌ Source file not found: $SourceFile" -Level "ERROR"
    exit 1
}

$servers = Get-Content -Path $ServerListPath
$jobs = @()
$jobMap = @{}

foreach ($server in $servers) {
    Write-Host -NoNewline "`r📁 Copying to: $server     " -ForegroundColor Cyan
    $destinationPath = "\\$server\C$\$(Split-Path $SourceFile -Leaf)"

    $job = Start-Job -ScriptBlock {
        param($src, $dest, $srv)
        try {
            Copy-Item -Path $src -Destination $dest -Force -ErrorAction Stop
            return "SUCCESS:${srv}"
        }
        catch {
            return "FAILURE:${srv}:$($_.Exception.Message)"
        }
    } -ArgumentList $SourceFile, $destinationPath, $server

    $jobs += $job
    $jobMap[$job.Id] = $server
}

#Wait and receive
Wait-Job -Job $jobs

$successCount = 0
$errorCount = 0

foreach ($job in $jobs) {
    $result = Receive-Job -Job $job

    if ($result -like "SUCCESS:*") {
        $server = $result.Split(":")[1]
        Write-Log "Success - File copied to ${server}" -Silent
        $successCount++
    }
    elseif ($result -like "FAILURE:*") {
        $parts = $result.Split(":", 3)
        $server = $parts[1]
        $errorMsg = $parts[2]
        Write-Log "ERROR - Failed to copy to ${server}: $errorMsg" -Level "ERROR" -Silent
        $errorCount++
    }

    Remove-Job -Job $job
}


Write-Host "`n✅ File copy completed: $successCount succeeded, $errorCount failed." -ForegroundColor Yellow
Write-Log "Script complete. $successCount success, $errorCount failure(s)." -Silent
Write-Host "📄 Log saved to: $LogPath" -ForegroundColor DarkGray
