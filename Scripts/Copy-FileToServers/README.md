# 📁 Copy-FileToServers.ps1

![PowerShell](https://img.shields.io/badge/PowerShell-0078D7?logo=powershell&logoColor=white)
![Platform](https://img.shields.io/badge/Platform-Windows-blue)
![License](https://img.shields.io/badge/License-MIT-green)

A PowerShell script that distributes a file to multiple remote servers in parallel using background jobs. Reads a list of hostnames from a text file, copies the specified file to each server's `C:\` drive via the `C$` admin share, and produces a timestamped log with per-server success and failure results.

---

## Table of Contents

- [Overview](#overview)
- [Requirements](#requirements)
- [Parameters](#parameters)
- [Usage](#usage)
- [Output](#output)
- [Notes](#notes)
- [License](#license)

---

## Overview

When you need to push a file — an installer, a patch, a config — across a fleet of servers quickly, this script handles it without waiting on each server one at a time. Each copy operation runs as a background job, so all servers are targeted concurrently. Results are collected after all jobs complete and written to a timestamped log file.

---

## Requirements

| Requirement | Details |
|---|---|
| PowerShell | 5.1 or later |
| Permissions | Admin access to `C$` share on each target server |
| Network | Target servers must be reachable and have file sharing enabled |
| OS | Windows |

> The account running the script must have administrative rights on the remote servers. If you're running this in a domain environment, a domain admin or delegated service account is recommended.

---

## Parameters

| Parameter | Required | Default | Description |
|---|---|---|---|
| `ServerListPath` | Yes | — | Path to a `.txt` file with one server hostname per line |
| `SourceFile` | Yes | — | Full path to the local file to copy |
| `LogPath` | No | `.\CopyFileLog_YYYYMMDD_HHmmss.log` | Full path for the log file output |

---

## Usage

**Basic usage (log auto-generated in current directory):**
```powershell
.\Copy-FileToServers.ps1 `
    -ServerListPath "C:\Servers\ServerList.txt" `
    -SourceFile "C:\Installers\app.exe"
```

**With a custom log path:**
```powershell
.\Copy-FileToServers.ps1 `
    -ServerListPath "C:\Servers\ServerList.txt" `
    -SourceFile "C:\Installers\app.exe" `
    -LogPath "C:\Logs\FileDeploy.log"
```

**Example input file (`ServerList.txt`):**
```
SERVER-01
SERVER-02
SERVER-03
SERVER-04
```

---

## Output

**Console summary on completion:**
```
File copy completed: 3 succeeded, 1 failed.
Log saved to: .\CopyFileLog_20260306_102755.log
```

**Log file format:**
```
2026-03-06 10:27:55 [INFO] Script started. Reading server list from C:\Servers\ServerList.txt and copying file: C:\Installers\app.exe
2026-03-06 10:27:58 [INFO] Success - File copied to SERVER-01
2026-03-06 10:27:58 [INFO] Success - File copied to SERVER-02
2026-03-06 10:27:58 [ERROR] ERROR - Failed to copy to SERVER-03: Access is denied
2026-03-06 10:27:58 [INFO] Success - File copied to SERVER-04
2026-03-06 10:27:58 [INFO] Script complete. 3 success, 1 failure(s).
```

The file is copied to `C:\<filename>` on each target server (e.g. `\\SERVER-01\C$\app.exe`).

---

## Notes

- All copy operations run as **parallel background jobs** — the script does not wait for one server before starting the next
- Failures are logged per-server with the exception message, so you can identify exactly which servers need attention
- The log is written silently during job execution and printed to console only as a summary — keeping output clean during large runs
- If either the server list or source file path is invalid, the script exits immediately with an error before starting any jobs
- For very large server lists, be mindful of the number of concurrent background jobs spawned — PowerShell does not throttle these automatically in this implementation

---

## License

This project uses the MIT License — see [LICENSE](../../LICENSE) for details.
