# 📂 Scripts

This folder contains reusable PowerShell scripts designed to help automate administrative tasks in Microsoft environments. Each script is written for real-world use and includes clear parameters, clean logging, and professional output formatting.

Each script lives in its own subfolder with a dedicated README covering parameters, usage examples, and output details.

---

## 📑 Script Index

### 🖥️ [AD-ComputerAudit](./AD-ComputerAudit/)
A GUI-based Active Directory computer object lifecycle tool. Identifies inactive machines, moves them to a Disabled OU, and optionally purges objects that have exceeded a configurable retention period. Features a dark-themed WinForms interface, dry-run mode, preview auditing, and full logging.

**Key tech:** `ActiveDirectory` · `System.Windows.Forms` · WhatIf/dry-run · Runspace-safe logging

---

### 🔍 [Check-ADComputerLastLogon](./Check-ADComputerLastLogon/)
Reads a list of hostnames from a text file, queries Active Directory for each, and exports the `LastLogonDate` of found devices to a CSV report. Useful for quick stale-device audits and pre-cleanup validation.

**Key tech:** `ActiveDirectory` · `Get-ADComputer` · CSV export

---

### 📁 [Copy-FileToServers](./Copy-FileToServers/)
Distributes a file to the `C$` share of multiple remote servers concurrently using PowerShell background jobs. Logs per-server success and failure results to a timestamped log file. Ideal for pushing installers, tools, or configs across a fleet without GPO or SCCM.

**Key tech:** `Start-Job` · `C$` admin share · Timestamped logging

---

### 📋 [Get-IntuneDeviceObjectIDs](./Get-IntuneDeviceObjectIDs/)
Reads a list of Intune device names, queries Microsoft Graph for each device's Azure AD Object ID, and exports the results in the exact CSV format required for Intune bulk group import. Handles missing and duplicate device names gracefully.

**Key tech:** `Microsoft.Graph` · `Get-MgDevice` · Bulk import CSV format

---

### 🖧 [SCCM / Add-SCCMDevicesToCollection](./SCCM/)
Bulk-adds devices to a ConfigMgr device collection using direct membership rules. Reads hostnames from a text file, resolves each to a ResourceID in SCCM, and adds them to the specified collection — with live terminal feedback and a timestamped log.

**Key tech:** `ConfigurationManager` · `Get-CMDevice` · `Add-CMDeviceCollectionDirectMembershipRule`

---

### 📊 [Send-ServerAndWebsiteStatusReport](./Send-ServerAndWebsiteStatusReport/)
Performs a daily infrastructure health check by pinging servers in parallel, validating website reachability via HTTP, and delivering a styled dark-themed HTML email report. Downed hosts are cross-checked against their management port (iDRAC, iLO, IPMI) to distinguish OS-down from fully unreachable. Designed to run on a schedule via Task Scheduler.

**Key tech:** Runspace pool · `System.Net.NetworkInformation.Ping` · `Invoke-WebRequest` · HTML email · `Send-MailMessage`

---

## 🛠 Common Requirements

Most scripts in this folder share these dependencies:

- **PowerShell 5.1+** across all scripts
- **RSAT / ActiveDirectory module** for AD-related scripts
- **SCCM Admin Console** installed locally for the SCCM script
- **Microsoft.Graph module** for the Intune script
- **Network access** to target hosts and SMTP relay for the status report

Refer to each script's individual README for specific setup and usage instructions.
