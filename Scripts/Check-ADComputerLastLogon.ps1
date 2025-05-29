<#
.SYNOPSIS
    Checks if computer accounts exist in Active Directory from a list of device names and exports their last logon timestamps.

.DESCRIPTION
    Reads a list of hostnames from a text file, queries Active Directory for each, and exports those that exist along with their
    LastLogonDate to a CSV file for reporting or auditing purposes.

.PARAMETER ComputerListPath
    The full path to the .txt file containing one hostname per line.

.AUTHOR
Shawn Tavares

.PARAMETER ReportOutputPath
    The destination path for the resulting CSV report.

.EXAMPLE
    .\Check-ADComputerLastLogon.ps1 -ComputerListPath "C:\lists\offices.txt" -ReportOutputPath "C:\reports\ad-computer-logons.csv"
#>

param (
    [Parameter(Mandatory)]
    [string]$ComputerListPath,

    [Parameter(Mandatory)]
    [string]$ReportOutputPath
)

Write-Host "📋 Reading computer list from: $ComputerListPath"

#Checking for file
if (-not (Test-Path $ComputerListPath)) {
    Write-Error "❌ Input list not found: $ComputerListPath"
    exit 1
}

$deviceNames = Get-Content -Path $ComputerListPath
$reportData = @()

foreach ($name in $deviceNames) {
    Write-Host -NoNewline "`r🔍 Checking: $name       " -ForegroundColor Cyan

    try {
        $adComputer = Get-ADComputer -Filter { Name -eq $name } -Property LastLogonDate -ErrorAction Stop

        if ($adComputer) {
            $reportData += [PSCustomObject]@{
                ComputerName  = $adComputer.Name
                LastLogonDate = $adComputer.LastLogonDate
            }
        }
    }
    catch {
        #Silent failure for missing objects
    }
}

# Export results to CSV
$reportData | Sort-Object ComputerName | Export-Csv -Path $ReportOutputPath -NoTypeInformation -Encoding UTF8
Write-Host "`n✅ Finished! Exported $($reportData.Count) entries to: $ReportOutputPath" -ForegroundColor Green
