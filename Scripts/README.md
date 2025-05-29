v# 📂 Scripts

This folder contains reusable PowerShell scripts designed to help automate administrative tasks in Microsoft environments.

---

## 🔎 `Get-IntuneDeviceObjectIDs.ps1`

This script reads a list of device names (from a `.txt` file), queries Microsoft Graph for their Azure AD Object IDs, and outputs a CSV formatted for **bulk group import** in Entra (formerly Azure AD).

### ✅ Features:
- Fully parameterized for easy use
- Outputs a ready-to-import CSV (`version:v1.0` format)
- Generates a detailed log file (with `INFO`, `WARN`, `ERROR` levels)
- Terminal shows a single-line, live-updating "Processing" message
- Gracefully handles errors and ambiguous results

### 🧪 Example Usage:
```powershell
.\Get-IntuneDeviceObjectIDs.ps1 `
    -InputFilePath "C:\Devices\device-list.txt" `
    -OutputCSVPath "C:\Devices\output.csv"
