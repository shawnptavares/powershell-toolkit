#Requires -Version 5.1
<#
.SYNOPSIS
    Daily server and website health check with styled HTML email report.
.DESCRIPTION
    Pings all servers from a CSV in parallel, checks management ports for downed hosts,
    validates website reachability, and sends a polished HTML status email.
.NOTES
    CSV format: Hostname,ManagementPort
    Should be scheduled to run via Task Scheduler if able.
    Server running job requires authorization to send emails.
#>

[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

$Config = @{
    ServerListPath = "C:\SERVERLIST.csv"
    WebsiteUrls    = @(
        "https://URL1.domain.com",
        "https://URL2.domain.com"
    )
    SmtpServer     = "SMTPSERVER"
    From           = "ServerReports@domain.com"
    To             = @("end.user@domain.com")
    Subject        = "Server Report | {DATE}"
    PingCount      = 2
    PingTimeoutMs  = 1000
    MaxParallel    = 20
}

$Config.Subject = $Config.Subject -replace '{DATE}', (Get-Date -Format "ddd MMM d, yyyy")

$Servers = Import-Csv $Config.ServerListPath

$Pool    = [RunspaceFactory]::CreateRunspacePool(1, $Config.MaxParallel)
$Pool.Open()
$Jobs    = [System.Collections.Generic.List[hashtable]]::new()

$PingScript = {
    param($Hostname, $ManagementPort, $Count, $TimeoutMs)
    $up = $false
    for ($i = 0; $i -lt $Count; $i++) {
        try {
            $ping   = New-Object System.Net.NetworkInformation.Ping
            $result = $ping.Send($Hostname, $TimeoutMs)
            if ($result.Status -eq 'Success') { $up = $true; break }
        } catch { }
    }

    $mgmtUp = $null
    if (-not $up -and $ManagementPort) {
        $mgmtUp = $false
        for ($i = 0; $i -lt $Count; $i++) {
            try {
                $ping   = New-Object System.Net.NetworkInformation.Ping
                $result = $ping.Send($ManagementPort, $TimeoutMs)
                if ($result.Status -eq 'Success') { $mgmtUp = $true; break }
            } catch { }
        }
    }

    [PSCustomObject]@{
        Hostname       = $Hostname
        ManagementPort = $ManagementPort
        HostUp         = $up
        MgmtUp         = $mgmtUp
    }
}

foreach ($Server in $Servers) {
    $ps = [PowerShell]::Create()
    $ps.RunspacePool = $Pool
    $null = $ps.AddScript($PingScript).AddParameters(@{
        Hostname       = $Server.Hostname
        ManagementPort = $Server.ManagementPort
        Count          = $Config.PingCount
        TimeoutMs      = $Config.PingTimeoutMs
    })
    $Jobs.Add(@{ PS = $ps; Handle = $ps.BeginInvoke() })
}

$Results = foreach ($Job in $Jobs) {
    $Job.PS.EndInvoke($Job.Handle)
    $Job.PS.Dispose()
}
$Pool.Close(); $Pool.Dispose()

$UpCount   = @($Results | Where-Object { $_.HostUp }).Count
$DownCount = @($Results | Where-Object { -not $_.HostUp }).Count

$MgmtPortsUp   = $Results | Where-Object { -not $_.HostUp -and $_.MgmtUp -eq $true  }
$MgmtPortsDown = $Results | Where-Object { -not $_.HostUp -and $_.MgmtUp -eq $false }

$WebsiteResults = foreach ($Url in $Config.WebsiteUrls) {
    $status = "Unknown"; $code = $null; $ok = $false
    try {
        $r    = Invoke-WebRequest -Uri $Url -Method Head -UseBasicParsing -TimeoutSec 10
        $code = $r.StatusCode
        $ok   = ($code -ge 200 -and $code -lt 400)
        $status = if ($ok) { "Reachable" } else { "HTTP $code" }
    } catch {
        $status = "Unreachable"
        if ($_.Exception.Response) { $code = [int]$_.Exception.Response.StatusCode }
    }
    [PSCustomObject]@{ Url = $Url; Status = $status; Ok = $ok; Code = $code }
}

function New-StatusTable {
    param([string]$Title, [string]$TitleColor, [array]$Rows, [string]$EmptyMsg = "Nothing to report.")
    $rowsHtml = if ($Rows.Count -eq 0) {
        "<tr><td style='padding:10px 14px;color:#6b7280;font-style:italic;'>$EmptyMsg</td></tr>"
    } else {
        $Rows | ForEach-Object {
            $label = if ($_.ManagementPort) { "$($_.Hostname) <span style='color:#9ca3af;font-size:12px;'>($($_.ManagementPort))</span>" } else { $_.Hostname }
            "<tr><td style='padding:10px 14px;border-top:1px solid #1f2937;'>$label</td></tr>"
        }
    }
    @"
<table width="100%" cellpadding="0" cellspacing="0" style="border-collapse:collapse;background:#111827;border-radius:8px;overflow:hidden;margin-bottom:16px;">
  <tr><th style="padding:10px 14px;text-align:left;background:$TitleColor;color:#fff;font-family:'Courier New',monospace;font-size:13px;letter-spacing:.5px;">$Title</th></tr>
  $rowsHtml
</table>
"@
}

function New-WebsiteRow {
    param($Site)
    $dot   = if ($Site.Ok) { "#22c55e" } else { "#ef4444" }
    $label = if ($Site.Ok) { "Reachable" } else { $Site.Status }
    @"
<tr>
  <td style="padding:10px 14px;border-top:1px solid #1f2937;">
    <span style="display:inline-block;width:8px;height:8px;border-radius:50%;background:$dot;margin-right:8px;vertical-align:middle;"></span>
    <a href="$($Site.Url)" style="color:#60a5fa;text-decoration:none;font-family:'Courier New',monospace;font-size:13px;">$($Site.Url)</a>
    <span style="color:#9ca3af;font-size:12px;margin-left:8px;">- $label</span>
  </td>
</tr>
"@
}

$allOk        = ($DownCount -eq 0) -and ($WebsiteResults | Where-Object { -not $_.Ok }).Count -eq 0
$headerColor  = if ($allOk) { "#065f46" } else { "#7f1d1d" }
$headerLabel  = if ($allOk) { "ALL SYSTEMS OPERATIONAL" } else { "ISSUES DETECTED" }
$headerIcon   = if ($allOk) { "&#10003;" } else { "&#9888;" }
$timestamp    = Get-Date -Format "dddd, MMMM d yyyy 'at' h:mm tt"

$tableUp   = New-StatusTable -Title "&#9888; HOST DOWN &mdash; Management Port UP"   -TitleColor "#92400e" -Rows $MgmtPortsUp
$tableDown = New-StatusTable -Title "&#10007; HOST DOWN &mdash; Management Port ALSO DOWN" -TitleColor "#7f1d1d" -Rows $MgmtPortsDown

$websiteRowsHtml = ($WebsiteResults | ForEach-Object { New-WebsiteRow $_ }) -join "`n"

$upPct  = if (($UpCount + $DownCount) -gt 0) { [math]::Round(($UpCount / ($UpCount + $DownCount)) * 100) } else { 100 }
$barColor = if ($upPct -eq 100) { "#22c55e" } elseif ($upPct -ge 80) { "#f59e0b" } else { "#ef4444" }

$Body = @"
<!DOCTYPE html>
<html lang="en">
<head><meta charset="UTF-8"><meta name="viewport" content="width=device-width,initial-scale=1"></head>
<body style="margin:0;padding:0;background:#030712;font-family:'Segoe UI',Arial,sans-serif;">

<table width="100%" cellpadding="0" cellspacing="0" style="background:#030712;padding:32px 0;">
<tr><td align="center">
<table width="600" cellpadding="0" cellspacing="0" style="max-width:600px;width:100%;">

  <tr><td style="background:$headerColor;border-radius:10px 10px 0 0;padding:24px 28px;">
    <p style="margin:0;color:#d1fae5;font-size:11px;letter-spacing:2px;text-transform:uppercase;font-family:'Courier New',monospace;">Infrastructure Health Report</p>
    <h1 style="margin:6px 0 0;color:#fff;font-size:22px;font-weight:700;">$headerIcon &nbsp;$headerLabel</h1>
    <p style="margin:4px 0 0;color:#a7f3d0;font-size:12px;opacity:.8;">$timestamp</p>
  </td></tr>

  <tr><td style="background:#0f172a;padding:24px 28px;border-radius:0 0 10px 10px;">

    <table width="100%" cellpadding="0" cellspacing="0" style="margin-bottom:24px;">
    <tr>
      <td width="33%" style="padding-right:8px;">
        <div style="background:#111827;border-radius:8px;padding:14px;text-align:center;min-width:80px;">
          <div style="font-size:28px;font-weight:700;color:#f9fafb;">$($UpCount + $DownCount)</div>
          <div style="font-size:11px;color:#6b7280;letter-spacing:1px;text-transform:uppercase;margin-top:2px;">Servers</div>
        </div>
      </td>
      <td width="33%" style="padding-right:8px;">
        <div style="background:#111827;border-radius:8px;padding:14px;text-align:center;min-width:80px;">
          <div style="font-size:28px;font-weight:700;color:#22c55e;">$($UpCount)</div>
          <div style="font-size:11px;color:#6b7280;letter-spacing:1px;text-transform:uppercase;margin-top:2px;">Online</div>
        </div>
      </td>
      <td width="33%">
        <div style="background:#111827;border-radius:8px;padding:14px;text-align:center;min-width:80px;">
          <div style="font-size:28px;font-weight:700;color:#ef4444;">$($DownCount)</div>
          <div style="font-size:11px;color:#6b7280;letter-spacing:1px;text-transform:uppercase;margin-top:2px;">Offline</div>
        </div>
      </td>
    </tr>
    </table>

    <div style="margin-bottom:24px;">
      <div style="display:flex;justify-content:space-between;margin-bottom:6px;">
        <span style="font-size:12px;color:#6b7280;text-transform:uppercase;letter-spacing:1px;">Uptime</span>
        <span style="font-size:12px;color:#f9fafb;font-weight:600;">$upPct%</span>
      </div>
      <div style="background:#1f2937;border-radius:4px;height:6px;overflow:hidden;">
        <div style="background:$barColor;width:$upPct%;height:100%;border-radius:4px;"></div>
      </div>
    </div>
    
    <p style="margin:0 0 12px;font-size:12px;color:#6b7280;text-transform:uppercase;letter-spacing:1.5px;">Host Status</p>
    $tableUp
    $tableDown
    
    <p style="margin:16px 0 12px;font-size:12px;color:#6b7280;text-transform:uppercase;letter-spacing:1.5px;">Website Reachability</p>
    <table width="100%" cellpadding="0" cellspacing="0" style="border-collapse:collapse;background:#111827;border-radius:8px;overflow:hidden;">
      $websiteRowsHtml
    </table>
 
    <p style="margin:28px 0 0;font-size:11px;color:#374151;text-align:center;border-top:1px solid #1f2937;padding-top:16px;">
      Generated automatically &bull; Server Reports
    </p>

  </td></tr>
</table>
</td></tr>
</table>

</body>
</html>
"@

$MailParams = @{
    SmtpServer = $Config.SmtpServer
    From       = $Config.From
    To         = $Config.To
    Subject    = $Config.Subject
    Body       = $Body
    BodyAsHtml = $true
}
Send-MailMessage @MailParams
Write-Host "Report sent. Up: $UpCount  Down: $DownCount  Websites: $($WebsiteResults.Count)" -ForegroundColor Cyan
