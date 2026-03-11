# 📊 Send-ServerAndWebsiteStatusReport.ps1

![PowerShell](https://img.shields.io/badge/PowerShell-0078D7?logo=powershell&logoColor=white)
![Platform](https://img.shields.io/badge/Platform-Windows-blue)
![License](https://img.shields.io/badge/License-MIT-green)

A PowerShell script that performs a daily infrastructure health check by pinging servers in parallel, validating website reachability, and delivering a polished dark-themed HTML email report with an uptime bar, per-host status, and management port fallback detection. Designed to run on a schedule via Task Scheduler.

---

## Table of Contents

- [Overview](#overview)
- [Requirements](#requirements)
- [Configuration](#configuration)
- [CSV Format](#csv-format)
- [Usage](#usage)
- [Email Report](#email-report)
- [Scheduling](#scheduling)
- [Notes](#notes)
- [License](#license)

---

## Overview

This script gives you a zero-touch daily visibility layer across your server fleet and web properties. Each run pings every server concurrently using a runspace pool, checks website endpoints via HTTP HEAD requests, and sends a single HTML email summarising the results. Downed hosts are cross-checked against their management port (e.g. iDRAC, iLO, IPMI) so you know immediately whether a host is fully unreachable or just OS-down with hardware still accessible.

The email report adapts its header colour and status label based on whether any issues were detected — green for all-clear, red for anything requiring attention.

---

## Requirements

| Requirement | Details |
|---|---|
| PowerShell | 5.1 or later |
| SMTP | Relay or server that permits unauthenticated send, or update `$MailParams` for authenticated send |
| Network | Must be able to reach all hosts, URLs, and the SMTP server |
| Permissions | The running account must be authorised to send email via the configured SMTP server |
| OS | Windows |

---

## Configuration

All settings are defined in the `$Config` block at the top of the script. Update these before first run:

| Setting | Description |
|---|---|
| `ServerListPath` | Full path to the server CSV file |
| `WebsiteUrls` | Array of URLs to test for reachability |
| `SmtpServer` | Hostname or IP of your SMTP relay |
| `From` | Sender email address |
| `To` | Array of recipient email addresses |
| `Subject` | Email subject — `{DATE}` is automatically replaced with the current date |
| `PingCount` | Number of ping attempts per host (default: `2`) |
| `PingTimeoutMs` | Timeout per ping in milliseconds (default: `1000`) |
| `MaxParallel` | Maximum concurrent runspaces for pinging (default: `20`) |

**Example configuration:**
```powershell
$Config = @{
    ServerListPath = "C:\SERVERLIST.csv"
    WebsiteUrls    = @(
        "https://intranet.domain.com",
        "https://portal.domain.com"
    )
    SmtpServer     = "smtp.domain.com"
    From           = "ServerReports@domain.com"
    To             = @("itteam@domain.com", "manager@domain.com")
    Subject        = "Server Report | {DATE}"
    PingCount      = 2
    PingTimeoutMs  = 1000
    MaxParallel    = 20
}
```

---

## CSV Format

The server list CSV must contain the following columns — one server per row:

```
Hostname,ManagementPort
SERVER-01,IDRAC-SERVER-01
SERVER-02,ILO-SERVER-02
SERVER-03,
FILESERVER-04,IPMI-FS-04
```

- `Hostname` — the primary hostname or IP to ping
- `ManagementPort` — the management interface hostname/IP (iDRAC, iLO, IPMI, etc.). Leave blank if not applicable.

If a host is down, the script will attempt to ping its `ManagementPort` to determine whether the hardware is still reachable.

---

## Usage

Run directly from PowerShell:
```powershell
.\Send-ServerAndWebsiteStatusReport.ps1
```

No parameters are required — all configuration is handled via the `$Config` block inside the script.

On completion, a summary line is printed to the console:
```
Report sent. Up: 18  Down: 2  Websites: 4
```

---

## Email Report

The HTML email includes:

- **Status header** — green (`ALL SYSTEMS OPERATIONAL`) or red (`ISSUES DETECTED`) based on results
- **Summary tiles** — total server count, online count, and offline count
- **Uptime bar** — visual percentage bar coloured green, amber, or red based on the up/down ratio
- **Host status tables** — downed hosts split into two groups:
  - Hosts down where the management port is **still responding**
  - Hosts down where the management port is **also unreachable**
- **Website reachability** — each URL listed with a green or red status dot and HTTP result

---

## Scheduling

To run automatically via Task Scheduler:

1. Open **Task Scheduler** and create a new task
2. Set the trigger to your preferred schedule (e.g. daily at 7:00 AM)
3. Set the action to:
   - **Program:** `powershell.exe`
   - **Arguments:** `-NonInteractive -ExecutionPolicy Bypass -File "C:\Scripts\Send-ServerAndWebsiteStatusReport.ps1"`
4. Run the task as a service account with SMTP send permissions
5. Check **Run whether user is logged on or not**

---

## Notes

- Pinging is handled via .NET `System.Net.NetworkInformation.Ping` inside a runspace pool — not `Test-Connection` — for true parallelism without the overhead of PowerShell jobs
- Website checks use `Invoke-WebRequest` with `-Method Head` to avoid downloading page content; HTTP 200–399 responses are treated as reachable
- TLS 1.2 is enforced at the top of the script (`[Net.ServicePointManager]::SecurityProtocol`) to ensure compatibility with modern HTTPS endpoints
- For authenticated SMTP (Office 365, etc.), add `-Credential` and `-UseSsl` to the `$MailParams` block at the bottom of the script
- `MaxParallel` can be increased for larger server lists, but be mindful of network and CPU impact on the host running the script

---

## License

This project uses the MIT License — see [LICENSE](../../LICENSE) for details.
