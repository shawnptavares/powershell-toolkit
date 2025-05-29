<#
.SYNOPSIS
    Bulk-adds devices to an SCCM device collection using hostnames.

.DESCRIPTION
    Reads a list of computer names from a text file, resolves them to ResourceIDs in SCCM,
    and adds each as a direct membership rule to a specified collection.
    Outputs live terminal feedback and saves a log to a timestamped file.

.AUTHOR
    Shawn Tavares

.PARAMETER DeviceListPath
    Path to the .txt file with one hostname per line.

.PARAMETER SiteServer
    The SCCM Site Server name.

.PARAMETER SiteCode
    The SCCM Site Code (e.g., "ABC").

.PARAMETER CollectionName
    The name of the target device collection.

.PARAMETER LogPath
    Optional: full path to a custom log file. If omitted, a timestamped log is created in the current file system path.

.EXAMPLE
    .\Add-SCCMDevicesToCollection.ps1 `
        -DeviceListPath "C:\Devices\OfficeList.txt" `
        -SiteServer "SCCM-Server01" `
        -SiteCode "001" `
        -CollectionName "MSO365 Force Update"
#>

param (
    [Parameter(Mandatory)]
    [string]$DeviceListPath,

    [Parameter(Mandatory)]
    [string]$SiteServer,

    [Parameter(Mandatory)]
    [string]$SiteCode,

    [Parameter(Mandatory)]
    [string]$CollectionName,

    [string]$LogPath = $(Join-Path -Path (Get-Location -PSProvider FileSystem).Path -ChildPath "SCCM_AddDevicesLog_$(Get-Date -Format 'yyyyMMdd_HHmmss').log")
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

Write-Log "Script started. Reading device list from: $DeviceListPath" -Silent

if (-not (Test-Path $DeviceListPath)) {
    Write-Log "❌ Device list not found at: $DeviceListPath" -Level "ERROR"
    exit 1
}

#Import SCCM module
try {
    Import-Module "$($ENV:SMS_ADMIN_UI_PATH)\..\ConfigurationManager.psd1" -ErrorAction Stop
    Set-Location "$SiteCode`:"
    Write-Log "SCCM module imported and site code set to $SiteCode" -Silent
}
catch {
    Write-Log "❌ Failed to import SCCM module or set location: $($_.Exception.Message)" -Level "ERROR"
    exit 1
}

$deviceNames = Get-Content -Path $DeviceListPath
$foundDevices = @()
$notFound = @()

#Lookup Resource IDs
foreach ($device in $deviceNames) {
    Write-Host -NoNewline "`r Checking: $device       " -ForegroundColor Cyan
    try {
        $cmDevice = Get-CMDevice -Name $device -ErrorAction Stop
        if ($cmDevice) {
            $foundDevices += $cmDevice.ResourceID
            Write-Log "Found: $device (ResourceID: $($cmDevice.ResourceID))" -Silent
        }
    }
    catch {
        $notFound += $device
        Write-Log "Not Found: $device" -Level "WARN" -Silent
    }
}

#Add to collection
$added = 0
foreach ($resID in $foundDevices) {
    try {
        Add-CMDeviceCollectionDirectMembershipRule -CollectionName $CollectionName -ResourceID $resID -ErrorAction Stop
        $added++
    }
    catch {
        Write-Log "ERROR - Failed to add ResourceID $resID to collection: $($_.Exception.Message)" -Level "ERROR"
    }
}

#Reset to filesystem provider (in case user needs to write)
Set-Location C:\

Write-Host "`n✅ Added $added devices to collection '$CollectionName'" -ForegroundColor Green
Write-Log "✅ Added $added devices to collection '$CollectionName'"

if ($notFound.Count -gt 0) {
    Write-Host "⚠️ Devices not found in SCCM:" -ForegroundColor Yellow
    $notFound | ForEach-Object { Write-Host $_ -ForegroundColor Yellow }
    Write-Log "⚠️ $($notFound.Count) devices were not found." -Level "WARN"
}
Write-Host "`n📄 Log saved to: $LogPath" -ForegroundColor DarkGray
