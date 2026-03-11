# 🔍 Check-ADComputerLastLogon.ps1

![PowerShell](https://img.shields.io/badge/PowerShell-0078D7?logo=powershell&logoColor=white)
![Active Directory](https://img.shields.io/badge/ActiveDirectory-0078D4?logo=microsoft&logoColor=white)
![Platform](https://img.shields.io/badge/Platform-Windows-blue)
![License](https://img.shields.io/badge/License-MIT-green)

A lightweight PowerShell script that reads a list of hostnames from a text file, checks each one against Active Directory, and exports the results — including last logon timestamps — to a CSV report. Useful for quick audits, stale device identification, or pre-cleanup validation.

---

## Table of Contents

- [Overview](#-overview)
- [Requirements](#-requirements)
- [Parameters](#-parameters)
- [Usage](#-usage)
- [Output](#-output)
- [Notes](#-notes)
- [License](#-license)

---

## Overview

Given a plain text file of device names (one per line), this script queries AD for each hostname and collects its LastLogonDate. Any device found in AD is written to a CSV report, sorted alphabetically by computer name. Devices not found in AD are silently skipped.

---

## Requirements

| Requirement | Details |
|---|---|
| PowerShell | 5.1 or later |
| Module | ActiveDirectory (RSAT) |
| Permissions | Read access to AD computer objects |
| OS | Windows |

Install RSAT if needed:

    Add-WindowsCapability -Online -Name Rsat.ActiveDirectory.DS-LDS.Tools~~~~0.0.1.0

---

## Parameters

| Parameter | Required | Description |
|---|---|---|
| ComputerListPath | Yes | Full path to a .txt file containing one hostname per line |
| ReportOutputPath | Yes | Full path for the output .csv report file |

---

## Usage

    .\Check-ADComputerLastLogon.ps1 `
        -ComputerListPath "C:\lists\devices.txt" `
        -ReportOutputPath "C:\reports\ad-computer-logons.csv"

Example input file (devices.txt):

    DESKTOP-001
    LAPTOP-HR-04
    TEST-01-18
    WORKSTATION-22

---

## Output

The script exports a CSV to the path specified by -ReportOutputPath. Only devices found in AD are included.

Example output (ad-computer-logons.csv):

    ComputerName,LastLogonDate
    TEST-01,2024-08-15 09:32:11
    DESKTOP-001,2025-01-03 14:05:44
    LAPTOP-HR-04,2023-11-20 08:17:59

Progress is displayed inline during execution:

    Checking: LAPTOP-HR-04
    Finished! Exported 3 entries to: C:\reports\ad-computer-logons.csv

---

## Notes

- Devices not found in AD are silently skipped by design
- Results are sorted alphabetically by ComputerName in the export
- LastLogonDate may be blank for machines that have never logged on or where the attribute has not replicated across DCs
- For deeper lifecycle management, pair this with AD-ComputerAudit.ps1

---

## License

This project uses the MIT License - see LICENSE for details.
