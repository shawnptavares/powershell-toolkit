# 🖧 Add-SCCMDevicesToCollection.ps1

![PowerShell](https://img.shields.io/badge/PowerShell-0078D7?logo=powershell&logoColor=white)
![SCCM](https://img.shields.io/badge/ConfigMgr-0078D4?logo=microsoft&logoColor=white)
![Platform](https://img.shields.io/badge/Platform-Windows-blue)
![License](https://img.shields.io/badge/License-MIT-green)

A PowerShell script that bulk-adds devices to a ConfigMgr (SCCM) device collection using direct membership rules. Reads a list of hostnames from a text file, resolves each to a ResourceID in SCCM, and adds them to the specified collection — with live terminal feedback and a timestamped log.

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

Manually adding devices to an SCCM collection one at a time through the console is tedious at scale. This script takes a flat list of hostnames, resolves them to SCCM ResourceIDs, and adds each as a direct membership rule to a target collection in one pass. Devices not found in SCCM are captured separately and logged as warnings rather than silently dropped.

---

## Requirements

| Requirement | Details |
|---|---|
| PowerShell | 5.1 or later |
| Module | `ConfigurationManager` (installed with SCCM Admin Console) |
| Environment Variable | `SMS_ADMIN_UI_PATH` must be set (auto-set by SCCM console install) |
| Permissions | SCCM role with rights to read devices and modify collection membership |
| OS | Windows |

> This script must be run from a machine with the SCCM Admin Console installed, as it relies on the `ConfigurationManager` PowerShell module bundled with it.

---

## Parameters

| Parameter | Required | Default | Description |
|---|---|---|---|
| `DeviceListPath` | Yes | — | Path to a `.txt` file with one hostname per line |
| `SiteServer` | Yes | — | SCCM Site Server hostname |
| `SiteCode` | Yes | — | SCCM Site Code (e.g. `ABC`) |
| `CollectionName` | Yes | — | Exact name of the target device collection |
| `LogPath` | No | `.\SCCM_AddDevicesLog_YYYYMMDD_HHmmss.log` | Full path for the log file output |

---

## Usage

**Basic usage:**
```powershell
.\Add-SCCMDevicesToCollection.ps1 `
    -DeviceListPath "C:\Devices\OfficeList.txt" `
    -SiteServer "SCCM-Server01" `
    -SiteCode "001" `
    -CollectionName "MSO365 Force Update"
```

**With a custom log path:**
```powershell
.\Add-SCCMDevicesToCollection.ps1 `
    -DeviceListPath "C:\Devices\OfficeList.txt" `
    -SiteServer "SCCM-Server01" `
    -SiteCode "001" `
    -CollectionName "MSO365 Force Update" `
    -LogPath "C:\Logs\SCCM_Bulk_Add.log"
```

**Example input file (`OfficeList.txt`):**
```
DESKTOP-HR-001
LAPTOP-SALES-04
WORKSTATION-DEV-07
SERVER-BRANCH-02
```

---

## Output

**Console summary on completion:**
```
Added 3 devices to collection 'MSO365 Force Update'
Devices not found in SCCM:
SERVER-BRANCH-02

Log saved to: .\SCCM_AddDevicesLog_20260306_102755.log
```

**Log file format:**
```
2026-03-06 10:27:50 [INFO] Script started. Reading device list from: C:\Devices\OfficeList.txt
2026-03-06 10:27:51 [INFO] SCCM module imported and site code set to 001
2026-03-06 10:27:52 [INFO] Found: DESKTOP-HR-001 (ResourceID: 16777220)
2026-03-06 10:27:52 [INFO] Found: LAPTOP-SALES-04 (ResourceID: 16777231)
2026-03-06 10:27:53 [INFO] Found: WORKSTATION-DEV-07 (ResourceID: 16777245)
2026-03-06 10:27:53 [WARN] Not Found: SERVER-BRANCH-02
2026-03-06 10:27:54 [INFO] Added 3 devices to collection 'MSO365 Force Update'
2026-03-06 10:27:54 [WARN] 1 devices were not found.
```

---

## Notes

- The script uses **direct membership rules** — devices are added explicitly rather than through a query-based rule
- Devices not found in SCCM are collected and reported as a group at the end, so you can reconcile them separately
- The script temporarily sets the PowerShell working location to the SCCM site drive (`SiteCode:`) and resets it back to `C:\` on completion
- `CollectionName` must match the SCCM collection name **exactly** — including capitalisation and spacing
- If the SCCM module fails to import, the script exits immediately before making any changes
- Collection membership changes may take time to reflect depending on your site's membership update schedule

---

## License

This project uses the MIT License — see [LICENSE](../../LICENSE) for details.
