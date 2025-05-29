# 📂 Scripts

This folder contains reusable PowerShell scripts designed to help automate administrative tasks in Microsoft environments. Each script is written for real-world use and includes clear parameters, clean logging, and professional output formatting.

---

## 🔎 `Get-IntuneDeviceObjectIDs.ps1`

Reads a list of device names from a `.txt` file, queries Microsoft Graph for their Azure AD Object IDs, and outputs a `.csv` formatted for **bulk group import** in Entra (formerly Azure AD).

### ✅ Features:
- Fully parameterized for reusability
- Outputs to official bulk import CSV format
- Silent logging to a timestamped `.log` file
- Clean single-line terminal feedback (no console spam)
- Gracefully handles missing or duplicate results

### 🧪 Example Usage:

```powershell
.\Get-IntuneDeviceObjectIDs.ps1 `
    -InputFilePath "C:\Devices\device-list.txt" `
    -OutputCSVPath "C:\Devices\output.csv"
```
## 🖥️ `Check-ADComputerLastLogon.ps1`

Reads a list of hostnames from a file and queries on-premises Active Directory for each. If the device exists, it collects the LastLogonDate and exports results to a .csv report for audit or review.

### ✅ Features:
- Uses Get-ADComputer with LastLogonDate
- Skips missing records silently
- Sorted, clean CSV output
- Single-line updating progress in terminal

### 🧪 Example Usage:

```powershell
.\Check-ADComputerLastLogon.ps1 `
    -ComputerListPath "C:\Lists\OfficeDevices.txt" `
    -ReportOutputPath "C:\Reports\OfficeResults.csv"
```
Requires: RSAT / ActiveDirectory PowerShell module
Scope: On-prem AD or hybrid environments

## 📦 `Add-SCCMDevicesToCollection.ps1`

Bulk-adds devices to an SCCM device collection using hostnames. Finds ResourceIDs from SCCM and adds each to the specified collection as direct membership rules.

### ✅ Features:
- Accepts a list of device names via parameter
- Resolves ResourceIDs using Get-CMDevice
- Adds devices to collection using Add-CMDeviceCollectionDirectMembershipRule
- Clean terminal feedback and log file output
- Automatically returns to the filesystem path after SCCM tasks

### 🧪 Example Usage:

  ```powershell
  .\Add-SCCMDevicesToCollection.ps1 `
    -DeviceListPath "C:\Devices\OfficeList.txt" `
    -SiteServer "SCCM-Server01" `
    -SiteCode "001" `
    -CollectionName "MSO365 Force Update"
  ```
  Requires: SCCM Console + PowerShell module
Must be run on a system with SCCM admin tools installed

## 📁 `Copy-FileToServers.ps1`

Copies a file to the `C$` share of a list of remote servers using background jobs. Ideal for quickly distributing installers, agents, or tools to a group of machines without using GPO, SCCM, or Intune.

### ✅ Features:
- Concurrent execution via PowerShell background jobs
- Logs each success/failure to a timestamped `.log` file
- Clean, single-line console feedback
- Robust error handling and reporting

### 🧪 Example Usage:

```powershell
.\Copy-FileToServers.ps1 `
    -ServerListPath "C:\Lists\MyServers.txt" `
    -SourceFile "C:\Tools\agent-installer.exe"
```
## ✉️ `Send-ServerAndWebsiteStatusReport.ps1`

This script checks a list of servers for availability using ICMP ping, verifies internal website access using HTTP requests, and sends a daily summary report via email. Ideal for early-morning infrastructure monitoring.

### ✅ Features:
- Pings servers listed in a text file
- Verifies internal web services with HTTP HEAD requests
- Reports server up/down count and any unreachable websites
- Sends plain-text email via SMTP

### 🧪 Example Usage:

```powershell
.\Send-ServerAndWebsiteStatusReport.ps1 `
    -ServerListPath "C:\Lists\serverList.txt" `
    -WebsiteUrls @("website1", "website2") `
    -SmtpServer "smtp-server" `
    -From "noreply@domain.local" `
    -To "it.team@domain.local" `
    -Subject "Daily Status Check"
```
