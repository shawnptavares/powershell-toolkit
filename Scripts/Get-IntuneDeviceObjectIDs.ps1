<#
.SYNOPSIS
    Exports Azure AD Object IDs for a list of Intune device names into a bulk import CSV format.

.DESCRIPTION
    Reads device names from a text file, queries Microsoft Graph for each Object ID,
    and outputs them in a CSV formatted for bulk group import.
    Logs all processing details to a separate log file.

.PARAMETER InputFilePath
    Path to the text file with one device name per line.

.PARAMETER OutputCSVPath
    Path to the desired output CSV file.

.PARAMETER LogPath
    Optional: Path to the log file. If not provided, a timestamped log is created in the same folder as the CSV.

.EXAMPLE
    .\Export-DeviceObjectIDs.ps1 -InputFilePath "devices.txt" -OutputCSVPath "export.csv"
#>

param (
    [Parameter(Mandatory)]
    [string]$InputFilePath,

    [Parameter(Mandatory)]
    [string]$OutputCSVPath,

    [string]$LogPath = "$(Split-Path $OutputCSVPath)\DeviceExportLog_$(Get-Date -Format 'yyyyMMdd_HHmmss').log"
)

function Write-Log {
    param (
        [string]$Message,
        [string]$Level = "INFO",
        [switch]$Silent
    )
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logLine = "$timestamp [$Level] $Message"
    Add-Content -Path $LogPath -Value $logLine
    if (-not $Silent) {
        Write-Host $logLine
    }
}

Write-Host "`n✅ Script Started! Reading device names from '${InputFilePath}'" -ForegroundColor Green
Write-Log "Script started. Reading device names from '${InputFilePath}'" -Silent

#Connect to MgGraph
try {
    Connect-MgGraph -Scopes "Directory.Read.All" -NoWelcome
    Write-Host "`n✅ Connected to Microsoft Graph with the required permissions!" -ForegroundColor Green

    Write-Log "Connected to Microsoft Graph." -Silent
}
catch {
    Write-Log "ERROR - Failed to connect to Microsoft Graph: $($_.Exception.Message)" -Level "ERROR"
    exit 1
}

#Gather device names
$deviceNames = Get-Content -Path $InputFilePath

#Create CSV
@(
    "version:v1.0"
    "Member object ID or user principal name [memberObjectIdOrUpn] Required"
) | Out-File -FilePath $OutputCSVPath -Encoding UTF8 -Force
Write-Log "Initialized CSV at '${OutputCSVPath}'" -Silent

#cleaning up how records are shown...
$progressMessage = "Processing device: "

#Process each device
foreach ($deviceName in $deviceNames) {
   Write-Host -NoNewline "`r🔍 $progressMessage $deviceName   " -ForegroundColor Cyan

    Write-Log "Processing device: ${deviceName}" -Silent

    try {
        $aadDevices = Get-MgDevice -Filter "displayName eq '$deviceName'" -ErrorAction Stop

        if ($aadDevices.Count -eq 1) {
            $objectID = $aadDevices[0].Id
            $objectID | Out-File -FilePath $OutputCSVPath -Encoding UTF8 -Append
            Write-Log "SUCCESS - Found ObjectID for ${deviceName}: $objectID" -Silent
        }
        elseif ($aadDevices.Count -gt 1) {
            Write-Log "WARNING - Multiple devices found for ${deviceName}, skipping to avoid ambiguity." -Level "WARN" -Silent
        }
        else {
            Write-Log "WARNING - Device not found: ${deviceName}" -Level "WARN" -Silent
        }
    }
    catch {
        Write-Log "ERROR - Failed to retrieve ObjectID for '${deviceName}': $($_.Exception.Message)" -Level "ERROR" -Silent
    }
}

Write-Log "✅ Script complete. CSV saved to '${OutputCSVPath}'. Log saved to '${LogPath}'." -Silent
Write-Host "`n✅ Done! CSV saved to '${OutputCSVPath}', Log file: $LogPath" -ForegroundColor Green
