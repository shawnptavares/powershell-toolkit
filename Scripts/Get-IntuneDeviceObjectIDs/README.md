# 📋 Get-IntuneDeviceObjectIDs.ps1

![PowerShell](https://img.shields.io/badge/PowerShell-0078D7?logo=powershell&logoColor=white)
![Microsoft Graph](https://img.shields.io/badge/Microsoft%20Graph-0078D4?logo=microsoft&logoColor=white)
![Intune](https://img.shields.io/badge/Intune-0078D4?logo=microsoft&logoColor=white)
![Platform](https://img.shields.io/badge/Platform-Windows-blue)
![License](https://img.shields.io/badge/License-MIT-green)

A PowerShell script that takes a list of Intune device names, queries Microsoft Graph for each device's Azure AD Object ID, and exports the results in a CSV format ready for Intune bulk group import. All processing details are captured in a timestamped log file.

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

When bulk-adding devices to Azure AD / Intune groups, Microsoft's import format requires Object IDs — not display names. This script bridges that gap by reading a plain list of device names, resolving each to its Object ID via Microsoft Graph, and writing the result directly in the format Intune expects for bulk import. Devices with no match or multiple matches are logged and skipped rather than silently exported incorrectly.

---

## Requirements

| Requirement | Details |
|---|---|
| PowerShell | 5.1 or later |
| Module | `Microsoft.Graph` |
| Graph Permission | `Directory.Read.All` |
| OS | Windows |

Install the Microsoft Graph module if needed:
```powershell
Install-Module Microsoft.Graph -Scope CurrentUser
```

> The script will prompt for interactive Graph authentication on first run. Ensure the account used has at least `Directory.Read.All` permissions in your tenant.

---

## Parameters

| Parameter | Required | Default | Description |
|---|---|---|---|
| `InputFilePath` | Yes | — | Path to a `.txt` file with one device name per line |
| `OutputCSVPath` | Yes | — | Path for the output `.csv` file formatted for Intune bulk import |
| `LogPath` | No | `<CSV folder>\DeviceExportLog_YYYYMMDD_HHmmss.log` | Path for the log file |

---

## Usage

**Basic usage:**
```powershell
.\Get-IntuneDeviceObjectIDs.ps1 `
    -InputFilePath "C:\devices.txt" `
    -OutputCSVPath "C:\export.csv"
```

**With a custom log path:**
```powershell
.\Get-IntuneDeviceObjectIDs.ps1 `
    -InputFilePath "C:\devices.txt" `
    -OutputCSVPath "C:\export.csv" `
    -LogPath "C:\Logs\DeviceExport.log"
```

**Example input file (`devices.txt`):**
```
DESKTOP-HR-001
LAPTOP-SALES-04
SURFACE-EXEC-12
WORKSTATION-DEV-07
```

---

## Output

**Intune bulk import CSV (`export.csv`):**
```
version:v1.0
Member object ID or user principal name [memberObjectIdOrUpn] Required
xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx
yyyyyyyy-yyyy-yyyy-yyyy-yyyyyyyyyyyy
zzzzzzzz-zzzz-zzzz-zzzz-zzzzzzzzzzzz
```

This format can be uploaded directly to an Azure AD group via **Members → Import members** in the Entra admin center.

**Log file format:**
```
2026-03-06 10:15:00 [INFO] Script started. Reading device names from 'C:\devices.txt'
2026-03-06 10:15:02 [INFO] Connected to Microsoft Graph.
2026-03-06 10:15:03 [INFO] SUCCESS - Found ObjectID for DESKTOP-HR-001: xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx
2026-03-06 10:15:04 [WARN] WARNING - Device not found: LAPTOP-SALES-04
2026-03-06 10:15:05 [WARN] WARNING - Multiple devices found for SURFACE-EXEC-12, skipping to avoid ambiguity.
2026-03-06 10:15:06 [INFO] SUCCESS - Found ObjectID for WORKSTATION-DEV-07: zzzzzzzz-zzzz-zzzz-zzzz-zzzzzzzzzzzz
2026-03-06 10:15:06 [INFO] Script complete. CSV saved to 'C:\export.csv'. Log saved to 'C:\Logs\DeviceExport.log'.
```

---

## Notes

- Devices with **no match** in Azure AD are logged as `WARN` and skipped
- Devices with **multiple matches** (duplicate display names) are also logged as `WARN` and skipped to prevent incorrect Object IDs from being exported
- The output CSV header is written in the exact format required by the Intune bulk import tool — do not modify it before uploading
- Graph authentication is interactive by default — for automated/scheduled use, consider switching to a service principal with a client secret or certificate

---

## License

This project uses the MIT License — see [LICENSE](../../LICENSE) for details.
