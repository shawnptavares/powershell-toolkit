# 🔧 PowerShell Toolkit

![PowerShell](https://img.shields.io/badge/PowerShell-5.1%2B-0078D4?logo=powershell&logoColor=white)
![Platform](https://img.shields.io/badge/Platform-Windows-blue)
![License](https://img.shields.io/badge/License-MIT-green)
![Status](https://img.shields.io/badge/Status-Active-brightgreen)

A collection of **production-tested** PowerShell utilities built from real enterprise IT work — covering device lifecycle management, infrastructure reporting, automation, and escalation tasks across Active Directory, Azure AD, Intune, and ConfigMgr.

Every script in this toolkit was written to solve a real problem in a real environment. No fluff, no demos — just tools that get used.

---

## 📁 Structure

```
powershell-toolkit/
├── Scripts/
│   ├── AD-ComputerAudit/
│   │   ├── AD-ComputerAudit.ps1
│   │   └── README.md
│   ├── Check-ADComputerLastLogon/
│   │   ├── Check-ADComputerLastLogon.ps1
│   │   └── README.md
│   ├── Copy-FileToServers/
│   │   ├── Copy-FileToServers.ps1
│   │   └── README.md
│   ├── Get-IntuneDeviceObjectIDs/
│   │   ├── Get-IntuneDeviceObjectIDs.ps1
│   │   └── README.md
│   ├── SCCM/
│   │   ├── Add-SCCMDevicesToCollection.ps1
│   │   └── README.md
│   ├── Send-ServerAndWebsiteStatusReport/
│   │   ├── Send-ServerAndWebsiteStatusReport.ps1
│   │   └── README.md
│   └── README.md
├── Profiles/
│   └── Microsoft.PowerShell_profile.ps1
├── .github/workflows/
└── README.md
```

---

## 📜 Scripts

Each script lives in its own folder with a full README covering parameters, usage examples, and output details. Below is a quick overview — click any script name to go straight to its documentation.

---

### 🖥️ [AD-ComputerAudit](./Scripts/AD-ComputerAudit/)
A GUI-based Active Directory computer object lifecycle tool built with WinForms. Identifies machines inactive for 1+ year, moves them to a Disabled OU, and optionally purges objects that have been sitting there for 6+ months. Features a dark-themed interface, dry-run/WhatIf mode, preview auditing, and full timestamped logging — built so you can test safely before committing a single change to AD.

**Real-world use:** Environments that have accumulated years of stale computer objects with no automated cleanup process. Run the preview first, review the candidate list, then commit — all from the same GUI.

---

### 🔍 [Check-ADComputerLastLogon](./Scripts/Check-ADComputerLastLogon/)
Reads a list of hostnames from a text file, queries Active Directory for each, and exports `LastLogonDate` for every matched device to a CSV report. Devices not found in AD are silently skipped.

**Real-world use:** Feed it a list from a hardware refresh spreadsheet and instantly know which machines are still active in AD and when they last checked in — no manual AD searches required.

---

### 📁 [Copy-FileToServers](./Scripts/Copy-FileToServers/)
Distributes a file to the `C$` share of multiple remote servers concurrently using PowerShell background jobs. Logs per-server success and failure to a timestamped log file.

**Real-world use:** Push a monitoring agent, config file, or installer to 30+ servers simultaneously. Cuts what would be a 20+ minute sequential operation down to under 2 minutes.

---

### 📋 [Get-IntuneDeviceObjectIDs](./Scripts/Get-IntuneDeviceObjectIDs/)
Reads a list of Intune device names, queries Microsoft Graph for each device's Azure AD Object ID, and exports the results in the exact CSV format required for Intune bulk group import. Handles missing and duplicate device names gracefully with per-entry logging.

**Real-world use:** During an Intune migration, used to process 200+ devices for bulk group assignment — saving hours of manual lookup in the Intune portal.

---

### 🖧 [Add-SCCMDevicesToCollection](./Scripts/SCCM/)
Bulk-adds devices to a ConfigMgr device collection using direct membership rules. Reads hostnames from a text file, resolves each to a ResourceID, and adds them to the specified collection with live terminal feedback and a timestamped log.

**Real-world use:** Quickly populate a pilot collection before a ConfigMgr software deployment or patch run — without touching the SCCM console for each device individually.

---

### 📊 [Send-ServerAndWebsiteStatusReport](./Scripts/Send-ServerAndWebsiteStatusReport/)
Performs a daily infrastructure health check by pinging servers in parallel via a runspace pool, validating website reachability via HTTP HEAD requests, and delivering a polished dark-themed HTML email report. Downed hosts are cross-checked against their management port (iDRAC, iLO, IPMI) to distinguish OS-down from fully unreachable.

**Real-world use:** Schedule this as a Task Scheduler job to land in your team's inbox every morning before the day starts — a lightweight infrastructure pulse without needing a full monitoring platform.

---

## 👤 PowerShell Profile

The `Profiles/` folder contains my personal `$PROFILE` — a daily-driver setup for IT automation, escalation support, and cloud systems engineering.

### Included Functions

| Function | Description |
|---|---|
| `Get-LAPS` | Fetches LAPS passwords for AD-joined machines securely |
| `Get-BitLockerKey` | Retrieves BitLocker recovery keys from AD or Azure AD |
| `Get-DinoPass` | Generates strong or simple passwords via the DinoPass API |
| `purge` | **One-command device removal** — wipes a device from AD, Azure AD, Intune, Autopilot, and ConfigMgr simultaneously |

> 💡 **`purge` in particular** was built for end-of-life device workflows where you'd otherwise need to manually hit 4–5 different admin portals. It handles the full decommission chain in a single call.

### Terminal Setup

- **Oh-My-Posh** for prompt theming and git branch visibility
- **Terminal-Icons** for file type icons in directory listings
- **winfetch** (optional) for system info display on launch
- Modular imports for Microsoft Graph, AD, SCCM, and LAPS — loaded only when needed

---

## 🛠 Prerequisites & Modules

Most scripts include inline module checks and will prompt you to install if missing. For full functionality across the toolkit:

```powershell
Install-Module Microsoft.Graph.Identity.DirectoryManagement
Install-Module Microsoft.Graph.DeviceManagement
Install-Module ActiveDirectory          # Requires RSAT
Install-Module ConfigurationManager     # Requires SCCM Admin Console
Install-Module Terminal-Icons
Install-Module oh-my-posh
# admpwd.ps — install via LAPS client package from Microsoft
```

---

## 🚀 Roadmap

- [x] Per-script READMEs with usage examples and parameter docs
- [x] Organised folder structure — one folder per script
- [ ] PSScriptAnalyzer via GitHub Actions (CI linting on push)
- [ ] Standalone module build for `purge` and profile functions
- [ ] Azure runbook versions of key scripts

---

## 📝 License

MIT — see [LICENSE](LICENSE) for details. Use freely, attribution appreciated.

---

> Built from real enterprise IT experience. If something's useful, feel free to fork it and make it your own.
