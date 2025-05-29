# 🔧 PowerShell Toolkit ![PowerShell](https://img.shields.io/badge/PowerShell-0078D7?logo=powershell&logoColor=white)


A collection of production-tested PowerShell utilities designed to make device management, reporting, automation, and escalation tasks easier across Active Directory, Azure AD, Intune, and ConfigMgr.

---

## 📜 Table of Contents

- [🔧 Scripts](#-scripts)
  - [Get-IntuneDeviceObjectIDs.ps1](#get-intunedeviceobjectidsps1)
  - [Check-ADComputerPresence.ps1](#check-adcomputerpresenceps1)
  - [Add-SCCMDevicesToCollection.ps1](#add-sccmdevicestocollectionps1)
  - [Copy-FileToServers.ps1](#copy-filetoserversps1)
  - [Send-ServerAndWebsiteStatusReport.ps1](#send-serverandwebsitestatusreportps1)
- [👤 PowerShell Profile](#-powershell-profile)
- [🛠 Modules Used](#-modules-used)
- [📝 License](#-license)

---

## 🔧 Scripts

### Get-IntuneDeviceObjectIDs.ps1
Retrieves the Object IDs of Intune devices listed in a `.txt` file and generates a CSV file formatted for Intune bulk import operations. Includes interactive processing status and output logging.

### Check-ADComputerPresence.ps1
Scans a list of hostnames to confirm their presence in Active Directory and logs the `LastLogonDate` of each. Useful for identifying stale records and cleanup operations.

### Add-SCCMDevicesToCollection.ps1
Adds a list of hostnames to a specified ConfigMgr device collection. Uses the ConfigMgr module and supports progress feedback and logging of skipped or missing devices.

### Copy-FileToServers.ps1
Uses PowerShell background jobs to copy a file to a list of remote servers in parallel. Designed for fast distribution of tools, patches, or utilities across an enterprise environment.

### Send-ServerAndWebsiteStatusReport.ps1
Pings a list of internal servers and tests reachability of internal web apps. Generates a simple report (up/down counts, unreachable URLs) and sends it via SMTP email.

---

## 👤 PowerShell Profile

This custom `$PROFILE` script is a daily-driver setup tailored for IT automation, escalation support, and cloud systems engineering. It includes:

- `Get-LAPS`: Securely fetches LAPS passwords for AD-joined machines
- `Get-BitLockerKey`: Retrieves BitLocker recovery keys from AD or Azure AD
- `Get-DinoPass`: Generates strong or simple passwords via [DinoPass](https://www.dinopass.com)
- `purge`: Removes a device from AD, AAD, Intune, Autopilot, and ConfigMgr in one go

The profile also includes:
- Terminal aesthetics via `Oh-My-Posh`
- Optional `winfetch` system info on launch
- Modular imports for Microsoft Graph, AD, SCCM, and LAPS management

---

## 🛠 Modules Used

This toolkit assumes access to (install if needed):

- `Microsoft.Graph.*` (e.g. `Microsoft.Graph.Identity.DirectoryManagement`)
- `ActiveDirectory`
- `ConfigurationManager`
- `Terminal-Icons`
- `admpwd.ps` (LAPS module)

Run `Install-Module <ModuleName>` as needed. Most scripts include inline module checks and prompts to install if missing.

---

## 📝 License

This project uses the MIT License — see [LICENSE](LICENSE) for details.

---

## 🚀 Coming Soon

- GitHub Actions for `PSScriptAnalyzer`
- Separate documentation folder (`/docs`)
- Standalone module builds for repeatable deployment
