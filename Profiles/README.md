# PowerShell Profile Toolkit

This is my custom PowerShell profile designed to streamline my daily workflows as a systems engineer and automation enthusiast. It includes quality-of-life aliases, custom utilities, and deep integration with Active Directory, Azure AD, BitLocker, and DinoPass.

## ✨ Features

### Modules Loaded
- `Terminal-Icons`
- `ActiveDirectory`
- `Microsoft.Graph`
- `admpwd.ps1` *(if available)*
- `Oh-My-Posh` prompt theming

### Custom Functions

#### `Get-LAPS`
- Retrieves the local admin password for a device using LAPS
- Copies to clipboard automatically

#### `Get-BitLockerKey`
- Retrieves BitLocker recovery keys from either:
  - Active Directory
  - Azure AD (via Microsoft Graph)

#### `Get-DinoPass`
- Generates and copies a password using DinoPass API
- Supports `-Strong` or `-Simple` switches

#### `purge`
- Custom device cleanup tool
- Supports full deprovisioning from AD, AAD, Intune, Autopilot, and ConfigMgr
- Requires auth and handles all module loading and validation

#### `Pro`
- Opens your current PowerShell profile in Notepad

---

## 🚀 Getting Started

1. Clone this repo or copy the `Microsoft.PowerShell_profile.ps1` into your profile path:
   ```powershell
   notepad $PROFILE
   ```
Make sure you have the required modules:

Terminal-Icons

Microsoft.Graph

ActiveDirectory

Oh-My-Posh

Optional:

Install winfetch for system info display

Place admpwd.ps1 in a modules/ folder if needed

## 🔐 Notes
Microsoft Graph scopes required for full BitLocker and purge functionality:

DeviceManagementManagedDevices.Read.All

BitLockerKey.Read.All

Directory.AccessAsUser.All
