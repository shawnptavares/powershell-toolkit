# 🔧 PowerShell Toolkit

![PowerShell](https://img.shields.io/badge/PowerShell-5.1%2B-0078D4?logo=powershell&logoColor=white)
![Platform](https://img.shields.io/badge/Platform-Windows-blue)
![License](https://img.shields.io/badge/License-MIT-green)
![Status](https://img.shields.io/badge/Status-Active-brightgreen)

A collection of **production-tested** PowerShell utilities built from real enterprise IT work — covering device management, reporting, automation, and escalation tasks across Active Directory, Azure AD, Intune, and ConfigMgr.

---

## 📁 Structure

```
powershell-toolkit/
├── Scripts/
│   ├── Get-IntuneDeviceObjectIDs.ps1
│   ├── Check-ADComputerPresence.ps1
│   ├── Add-SCCMDevicesToCollection.ps1
│   ├── Copy-FileToServers.ps1
│   └── Send-ServerAndWebsiteStatusReport.ps1
├── Profiles/
│   └── Microsoft.PowerShell_profile.ps1
├── .github/workflows/
└── README.md
```

---

## 📜 Scripts

### `Get-IntuneDeviceObjectIDs.ps1`

**What it does:** Reads a list of device names from a `.txt` file, queries Intune via Microsoft Graph, and exports a CSV formatted for bulk import operations.

**Real-world use:** During an Intune migration project, this script was used to process 200+ devices for bulk group assignment and policy targeting — saving hours of manual lookup in the Intune portal. Any time you need to bridge a flat list of hostnames to Intune Object IDs (required for bulk operations), this is your tool.

**Key features:**
- Interactive progress display during processing
- Output logging with success/failure tracking
- CSV output ready for direct Intune import

---

### `Check-ADComputerPresence.ps1`

**What it does:** Scans a list of hostnames and confirms their presence in Active Directory, logging the `LastLogonDate` of each object.

**Real-world use:** Used during AD cleanup initiatives to quickly identify stale computer objects across large OUs. Feed it a list of hostnames from a hardware refresh spreadsheet and it'll tell you exactly which machines are still active in AD and when they last checked in — no manual AD searches required.

**Key features:**
- Bulk hostname processing from a text file
- `LastLogonDate` capture for staleness analysis
- Output log of present/missing objects

---

### `Add-SCCMDevicesToCollection.ps1`

**What it does:** Takes a list of device hostnames and adds them to a specified ConfigMgr device collection in bulk.

**Real-world use:** Useful when you need to quickly target a specific group of machines for a software deployment or patch run — for example, adding 50 devices to a pilot collection before a ConfigMgr application deployment. Eliminates the tedious one-by-one process in the SCCM console.

**Key features:**
- Bulk collection membership via ConfigMgr module
- Progress feedback during processing
- Logs skipped or missing devices for review

---

### `Copy-FileToServers.ps1`

**What it does:** Distributes a file to a list of remote servers in parallel using PowerShell background jobs.

**Real-world use:** Built for situations where you need to push a tool, config file, or patch to a large number of servers fast — without waiting for sequential copy operations. Used to distribute monitoring agents and configuration scripts across 30+ servers simultaneously, cutting distribution time from 20+ minutes to under 2.

**Key features:**
- Parallel execution via background jobs
- Configurable target list from a text file
- Designed for enterprise-scale distribution

---

### `Send-ServerAndWebsiteStatusReport.ps1`

**What it does:** Pings a defined list of internal servers and tests HTTP reachability of internal web apps, then emails a formatted status report via SMTP.

**Real-world use:** Set this up as a scheduled task to run every morning and email your team a quick infrastructure health summary before the day starts — without needing a full monitoring platform. Useful for smaller environments or as a lightweight supplement to SolarWinds/PRTG.

**Key features:**
- Server ping checks with up/down status
- Web app HTTP reachability testing
- SMTP email delivery with summary counts and flagged URLs

---

## 👤 PowerShell Profile

The `Profiles/` folder contains my personal `$PROFILE` — a daily-driver setup for IT automation, escalation support, and cloud systems engineering.

### Included Functions

| Function | Description |
|---|---|
| `Get-LAPS` | Fetches LAPS passwords for AD-joined machines securely |
| `Get-BitLockerKey` | Retrieves BitLocker recovery keys from AD or Azure AD |
| `Get-DinoPass` | Generates strong or simple passwords via DinoPass API |
| `purge` | **One-command device removal** — wipes a device from AD, Azure AD, Intune, Autopilot, and ConfigMgr simultaneously |

> 💡 **`purge` in particular** was built for end-of-life device workflows where you'd otherwise need to manually hit 4–5 different admin portals. It handles the full decommission chain in a single call.

### Terminal Setup

- **Oh-My-Posh** for prompt theming and git branch visibility
- **Terminal-Icons** for file type icons in directory listings
- **winfetch** (optional) for system info display on launch
- Modular imports for Microsoft Graph, AD, SCCM, and LAPS — loaded only when needed

---

## 🛠 Prerequisites & Modules

Most scripts include inline module checks and will prompt you to install if missing. For full functionality, the following modules are used:

```powershell
Install-Module Microsoft.Graph.Identity.DirectoryManagement
Install-Module Microsoft.Graph.DeviceManagement
Install-Module ActiveDirectory          # Requires RSAT
Install-Module ConfigurationManager     # Requires SCCM console
Install-Module Terminal-Icons
Install-Module oh-my-posh
# admpwd.ps — install via LAPS client package from Microsoft
```

---

## 🚀 Roadmap

- [ ] PSScriptAnalyzer via GitHub Actions (CI linting on push)
- [ ] `/docs` folder with per-script usage guides and screenshots
- [ ] Standalone module build for `purge` and profile functions
- [ ] Azure runbook versions of key scripts

---

## 📝 License

MIT — see [LICENSE](LICENSE) for details. Use freely, attribution appreciated.

---

> Built from real enterprise IT experience. If something's useful, feel free to fork it and make it your own.
