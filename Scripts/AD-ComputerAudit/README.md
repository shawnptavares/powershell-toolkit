# 🖥️ AD-ComputerAudit.ps1

![PowerShell](https://img.shields.io/badge/PowerShell-0078D7?logo=powershell&logoColor=white)
![Active Directory](https://img.shields.io/badge/ActiveDirectory-0078D4?logo=microsoft&logoColor=white)
![Platform](https://img.shields.io/badge/Platform-Windows-blue)
![License](https://img.shields.io/badge/License-MIT-green)

A GUI-based PowerShell tool for auditing and lifecycle-managing stale Active Directory computer objects. Identifies inactive machines, moves them to a Disabled OU, and optionally purges objects that have been sitting in that OU past a configurable retention period — all with full logging and a dry-run mode for safe testing before committing any changes.

---

## 📋 Table of Contents

- [Overview](#-overview)
- [Features](#-features)
- [Screenshots](#-screenshots)
- [Requirements](#-requirements)
- [Usage](#-usage)
- [Configuration](#-configuration)
- [Audit Logic](#-audit-logic)
- [Logging](#-logging)
- [Dry-Run Mode](#-dry-run-mode)
- [License](#-license)

---

## 🔍 Overview

Over time, AD environments accumulate stale computer objects — decommissioned machines, retired laptops, renamed devices — that were never cleaned up. This tool automates that lifecycle in two phases:

1. **Phase 1 — Disable & Move:** Computers inactive for 1+ year are disabled and relocated to a designated Disabled Logins OU.
2. **Phase 2 — Delete:** Computers that have been in the Disabled OU for 6+ months (meaning their last logon is ~18 months old) are eligible for permanent deletion.

Both phases are fully configurable, logged, and protected behind a dry-run mode that must be explicitly disabled before any real changes are made.

---

## ✨ Features

- **WinForms GUI** — clean dark-themed interface, no command-line required
- **Dry-Run / WhatIf Mode** — on by default; simulates all operations and logs what *would* happen without touching AD
- **Two-phase audit** — Move phase and Delete phase are independent operations
- **Preview mode** — generates a full candidate list across both phases before taking any action
- **Confirmation dialogs** — live Move and live Delete both require explicit confirmation before proceeding
- **Per-operation logging** — timestamped, level-tagged log files written daily to a configurable directory
- **Configurable thresholds** — inactive days and delete days are adjustable directly in the GUI
- **OU path validation** — both OU fields are editable in-tool; synced to config before each run
- **Description stamping** — moved objects get their AD description updated with the audit date for traceability

---

## 📸 Screenshots

<img width="887" height="730" alt="image" src="https://github.com/user-attachments/assets/b02d6ee7-8ef0-49e5-8208-09a6a0e01ed5" />


---

## ✅ Requirements

| Requirement | Details |
|---|---|
| PowerShell | 5.1 or later |
| Module | `ActiveDirectory` (RSAT) |
| Permissions | Read, Move, Disable, and Delete on target OUs |
| OS | Windows (WinForms dependency) |

Install RSAT if needed:
```powershell
Add-WindowsCapability -Online -Name Rsat.ActiveDirectory.DS-LDS.Tools~~~~0.0.1.0
```

---

## 🚀 Usage

1. **Download** `AD-ComputerAudit.ps1`
2. **Run** from an elevated PowerShell session:

```powershell
.\AD-ComputerAudit.ps1
```

> If you hit an execution policy error, run first:
> ```powershell
> Set-ExecutionPolicy -Scope CurrentUser -ExecutionPolicy RemoteSigned
> ```

3. **Update the OU paths** in the Configuration panel before running anything
4. **Use Preview** to verify candidates before committing
5. **Uncheck Dry-Run** only when you're ready to commit real changes

---

## ⚙️ Configuration

All settings are editable in the GUI's Configuration panel at runtime and can also be adjusted in the `$script:Config` block at the top of the script:

| Setting | Default | Description |
|---|---|---|
| `SearchBaseOU` | `DC=yourdomain,DC=com` | The root OU to scan for inactive computers |
| `DisabledOU` | `OU=Disabled Logins,DC=yourdomain,DC=com` | Destination OU for disabled machines |
| `InactiveDays` | `365` | Days since last logon before a computer is considered inactive |
| `DeleteDays` | `548` | Days since last logon before a disabled computer is eligible for deletion (~18 months) |
| `LogDirectory` | `%USERPROFILE%\Desktop\AD_Audit_Logs` | Directory where daily log files are written |
| `WhatIf` | `$true` | Dry-run mode — no AD changes are made when enabled |

> **Note:** Update `SearchBaseOU` and `DisabledOU` to match your environment before first use. The script will fail gracefully with an error if the OU paths are unreachable.

---

## 🔁 Audit Logic

### Phase 1 — Move Inactive Computers

```
LastLogonDate < Today - InactiveDays (default: 365)
AND Enabled = True
AND NOT already in DisabledOU
```

On a live run, the script will:
- Disable the AD computer account
- Move it to the configured Disabled Logins OU
- Stamp the object's Description field with the audit date

### Phase 2 — Delete Stale Disabled Computers

```
LastLogonDate < Today - DeleteDays (default: 548)
AND object is in DisabledOU
```

On a live run, the script will permanently remove the object from AD. This action requires a second confirmation dialog and cannot be undone.

> The 548-day delete threshold is intentional: it represents the ~1 year inactive period plus 6 months of retention in the Disabled OU before permanent removal.

---

## 📝 Logging

Logs are written daily to the configured `LogDirectory`. Each log file is named `AD_Audit_YYYYMMDD.log`.

Each entry follows this format:
```
2026-03-06 10:27:56 [ACTION] [LIVE] MOVED: BRPS-SB24-18 → Disabled OU
2026-03-06 10:27:56 [DRYRUN] [DRY-RUN] WOULD DELETE: BRPS-WS-04 (LastLogon: 2024-06-01)
```

Log levels used:

| Level | Meaning |
|---|---|
| `INFO` | General status messages |
| `WARN` | Non-critical alerts (e.g. deletion candidates found) |
| `ACTION` | A real change was committed to AD |
| `DRYRUN` | An action was simulated in dry-run mode |
| `ERROR` | An operation failed |
| `SUCCESS` | A batch operation completed |

The **📂 Open Log Folder** button in the GUI opens the log directory in Explorer.

---

## 🧪 Dry-Run Mode

Dry-Run is enabled by default. In this mode:

- No objects are moved, disabled, or deleted
- All operations are logged with the `[DRY-RUN]` prefix
- The GUI mode banner displays in **gold** with a clear label
- Button labels reflect the current mode (`Dry-Run` vs `LIVE`)

To commit real changes, uncheck **Dry-Run Mode (WhatIf)** in the top-right of the GUI. A live Move or Delete will then prompt a confirmation dialog before proceeding.

> **Recommended workflow:** Always run Preview → Dry-Run Move → Dry-Run Delete → review logs → then switch to LIVE.

---

## 📝 License

This project uses the MIT License — see [LICENSE](../../LICENSE) for details.
