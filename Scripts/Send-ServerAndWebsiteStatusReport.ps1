<#
.SYNOPSIS
    Pings servers and checks websites, then emails a status report.

.DESCRIPTION
    This script reads a list of servers from a file and checks whether they are online via ICMP ping.
    It also tests accessibility of internal websites using HTTP HEAD requests. A report is generated
    and emailed to a specified recipient.

.PARAMETER ServerListPath
    Path to the file containing server hostnames or IPs (one per line).

.PARAMETER WebsiteUrls
    Array of website URLs to check.

.PARAMETER SmtpServer
    SMTP server used for sending the report.

.PARAMETER From
    The sender email address.

.PARAMETER To
    The recipient email address.

.PARAMETER Subject
    The subject line of the email.

.EXAMPLE
    .\Send-ServerAndWebsiteStatusReport.ps1 `
        -ServerListPath "C:\Lists\CSASERVER.txt" `
        -WebsiteUrls @("website1", "website2") `
        -SmtpServer "smtp-server" `
        -From "noreply@domain.local" `
        -To "it.team@domain.local" `
        -Subject "Daily Status Report"
#>

param (
    [Parameter(Mandatory)]
    [string]$ServerListPath,

    [Parameter(Mandatory)]
    [string[]]$WebsiteUrls,

    [Parameter(Mandatory)]
    [string]$SmtpServer,

    [Parameter(Mandatory)]
    [string]$From,

    [Parameter(Mandatory)]
    [string]$To,

    [string]$Subject = "Server and Website Daily Status Report"
)

[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

#Initialize counters and report
$UpCount = 0
$DownCount = 0
$Report = @()

#Load server list
if (-not (Test-Path $ServerListPath)) {
    Write-Error "Server list file not found: $ServerListPath"
    exit 1
}
$Servers = Get-Content $ServerListPath

#Check server availability
$Report += "**Server Status:**"
foreach ($Server in $Servers) {
    if (Test-Connection -ComputerName $Server -Count 1 -Quiet) {
        $UpCount++
    } else {
        $DownCount++
        $Report += "$Server is down"
    }
}

#Check website accessibility
$Report += ""
$Report += "**Website Reachability:**"
foreach ($WebsiteUrl in $WebsiteUrls) {
    try {
        $Response = Invoke-WebRequest -Uri $WebsiteUrl -Method Head -UseBasicParsing -TimeoutSec 10
        if ($Response.StatusCode -eq 200) {
            $Report += "$WebsiteUrl is reachable"
        } else {
            $Report += "$WebsiteUrl responded with status code: $($Response.StatusCode)"
        }
    }
    catch {
        $Report += "$WebsiteUrl is not reachable (Error: $($_.Exception.Message))"
    }
}

#Compose full report body
$Report = @(
    "Good morning,",
    "",
    "Here are the results from the latest server and website status check:",
    ""
) + $Report

$Report += ""
$Report += "**Summary:**"
$Report += "Total servers checked: $($UpCount + $DownCount)"
$Report += "Up: $UpCount"
$Report += "Down: $DownCount"

#Send the email
$Body = $Report -join "`n"

try {
    Send-MailMessage -SmtpServer $SmtpServer -From $From -To $To -Subject $Subject -Body $Body
    Write-Host "Report successfully sent to $To"
}
catch {
    Write-Error "Failed to send email: $($_.Exception.Message)"
}
