#Requires -Modules ActiveDirectory

<#
.SYNOPSIS
    Active Directory Computer Object Audit Tool
.DESCRIPTION
    GUI tool to audit inactive computer objects, move them to a Disabled OU,
    and optionally delete objects that have been disabled for 6+ months.
    Supports a WhatIf/dry-run mode for safe testing before committing changes.
.NOTES
    Requires the ActiveDirectory PowerShell module and appropriate AD permissions.
    Runs on Powershell 7.
#>

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

$script:Config = @{
    InactiveDays        = 365
    DeleteDays          = 548
    DisabledOU          = "OU=Disabled Logins,DC=yourdomain,DC=com"
    SearchBaseOU        = "DC=yourdomain,DC=com"
    LogDirectory        = "$env:USERPROFILE\Desktop\AD_Audit_Logs"
    WhatIf              = $true
}

function Write-AuditLog {
    param(
        [string]$Message,
        [ValidateSet("INFO","WARN","ACTION","DRYRUN","ERROR","SUCCESS")]
        [string]$Level = "INFO"
    )

    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $prefix    = if ($script:Config.WhatIf) { "[DRY-RUN]" } else { "[LIVE]" }
    $line      = "$timestamp [$Level] $prefix $Message"

    if (-not (Test-Path $script:Config.LogDirectory)) {
        New-Item -ItemType Directory -Path $script:Config.LogDirectory -Force | Out-Null
    }
    $logFile = Join-Path $script:Config.LogDirectory ("AD_Audit_" + (Get-Date -Format "yyyyMMdd") + ".log")
    Add-Content -Path $logFile -Value $line

    return $line
}

function Get-InactiveComputers {
    $cutoff = (Get-Date).AddDays(-$script:Config.InactiveDays)
    try {
        $computers = Get-ADComputer -Filter {
            LastLogonDate -lt $cutoff -and Enabled -eq $true
        } -SearchBase $script:Config.SearchBaseOU `
          -Properties LastLogonDate, DistinguishedName, OperatingSystem, Description `
          -ErrorAction Stop

        return $computers | Where-Object {
            $_.DistinguishedName -notlike "*$($script:Config.DisabledOU)*"
        }
    } catch {
        return $null
    }
}

function Get-DisabledComputers {
    $cutoff = (Get-Date).AddDays(-$script:Config.DeleteDays)
    try {
        $computers = Get-ADComputer -Filter {
            LastLogonDate -lt $cutoff
        } -SearchBase $script:Config.DisabledOU `
          -Properties LastLogonDate, DistinguishedName, OperatingSystem, Description, WhenChanged `
          -ErrorAction Stop

        return $computers
    } catch {
        return $null
    }
}

function Invoke-MoveInactiveComputers {
    param([System.Windows.Forms.RichTextBox]$OutputBox)

    $computers = Get-InactiveComputers
    if ($null -eq $computers) {
        $msg = Write-AuditLog "Failed to query AD. Check permissions and SearchBase OU." "ERROR"
        AppendOutput $OutputBox $msg "Red"
        return
    }
    if ($computers.Count -eq 0) {
        $msg = Write-AuditLog "No inactive computers found (threshold: $($script:Config.InactiveDays) days)." "INFO"
        AppendOutput $OutputBox $msg "Gray"
        return
    }

    $msg = Write-AuditLog "Found $($computers.Count) inactive computer(s) to process." "INFO"
    AppendOutput $OutputBox $msg "White"

    foreach ($comp in $computers) {
        $lastLogin = if ($comp.LastLogonDate) { $comp.LastLogonDate.ToString("yyyy-MM-dd") } else { "Never" }
        $detail    = "  Computer: $($comp.Name) | LastLogon: $lastLogin | OS: $($comp.OperatingSystem)"

        if ($script:Config.WhatIf) {
            $msg = Write-AuditLog "WOULD MOVE: $($comp.Name) → $($script:Config.DisabledOU)" "DRYRUN"
            AppendOutput $OutputBox $msg "Yellow"
            AppendOutput $OutputBox $detail "DarkGray"
        } else {
            try {
                Disable-ADAccount -Identity $comp.DistinguishedName -ErrorAction Stop
                Move-ADObject -Identity $comp.DistinguishedName `
                              -TargetPath $script:Config.DisabledOU `
                              -ErrorAction Stop
                Set-ADComputer -Identity $comp.Name `
                               -Description "Disabled by AD Audit on $(Get-Date -Format 'yyyy-MM-dd'). Was: $($comp.Description)" `
                               -ErrorAction SilentlyContinue

                $msg = Write-AuditLog "MOVED: $($comp.Name) → Disabled OU" "ACTION"
                AppendOutput $OutputBox $msg "LightGreen"
                AppendOutput $OutputBox $detail "DarkGray"
            } catch {
                $msg = Write-AuditLog "FAILED to move $($comp.Name): $_" "ERROR"
                AppendOutput $OutputBox $msg "Red"
            }
        }
    }

    $summary = Write-AuditLog "Move operation complete. Processed $($computers.Count) object(s)." "SUCCESS"
    AppendOutput $OutputBox $summary "Cyan"
}

function Invoke-DeleteDisabledComputers {
    param([System.Windows.Forms.RichTextBox]$OutputBox)

    $computers = Get-DisabledComputers
    if ($null -eq $computers) {
        $msg = Write-AuditLog "Failed to query Disabled OU. Check permissions and OU path." "ERROR"
        AppendOutput $OutputBox $msg "Red"
        return
    }
    if ($computers.Count -eq 0) {
        $msg = Write-AuditLog "No computers in Disabled OU exceed the delete threshold ($($script:Config.DeleteDays) days)." "INFO"
        AppendOutput $OutputBox $msg "Gray"
        return
    }

    $msg = Write-AuditLog "Found $($computers.Count) computer(s) eligible for deletion." "WARN"
    AppendOutput $OutputBox $msg "Orange"

    foreach ($comp in $computers) {
        $lastLogin = if ($comp.LastLogonDate) { $comp.LastLogonDate.ToString("yyyy-MM-dd") } else { "Never" }
        $detail    = "  Computer: $($comp.Name) | LastLogon: $lastLogin | DN: $($comp.DistinguishedName)"

        if ($script:Config.WhatIf) {
            $msg = Write-AuditLog "WOULD DELETE: $($comp.Name) (LastLogon: $lastLogin)" "DRYRUN"
            AppendOutput $OutputBox $msg "Yellow"
            AppendOutput $OutputBox $detail "DarkGray"
        } else {
            try {
                Remove-ADComputer -Identity $comp.DistinguishedName -Confirm:$false -ErrorAction Stop
                $msg = Write-AuditLog "DELETED: $($comp.Name)" "ACTION"
                AppendOutput $OutputBox $msg "LightGreen"
                AppendOutput $OutputBox $detail "DarkGray"
            } catch {
                $msg = Write-AuditLog "FAILED to delete $($comp.Name): $_" "ERROR"
                AppendOutput $OutputBox $msg "Red"
            }
        }
    }

    $summary = Write-AuditLog "Delete operation complete. Processed $($computers.Count) object(s)." "SUCCESS"
    AppendOutput $OutputBox $summary "Cyan"
}

function Invoke-PreviewAudit {
    param([System.Windows.Forms.RichTextBox]$OutputBox)

    AppendOutput $OutputBox "`n═══ AUDIT PREVIEW ═══════════════════════════════" "Cyan"

    $inactive = Get-InactiveComputers
    if ($null -eq $inactive) {
        AppendOutput $OutputBox "  [ERROR] Could not retrieve inactive computers." "Red"
    } else {
        AppendOutput $OutputBox "  Inactive computers (would be MOVED): $($inactive.Count)" "White"
        foreach ($c in $inactive) {
            $ll = if ($c.LastLogonDate) { $c.LastLogonDate.ToString("yyyy-MM-dd") } else { "Never" }
            AppendOutput $OutputBox "    • $($c.Name)  [Last Login: $ll]" "Gray"
        }
    }

    AppendOutput $OutputBox "" "White"

    $disabled = Get-DisabledComputers
    if ($null -eq $disabled) {
        AppendOutput $OutputBox "  [ERROR] Could not retrieve disabled computers." "Red"
    } else {
        AppendOutput $OutputBox "  Disabled computers eligible for DELETION: $($disabled.Count)" "White"
        foreach ($c in $disabled) {
            $ll = if ($c.LastLogonDate) { $c.LastLogonDate.ToString("yyyy-MM-dd") } else { "Never" }
            AppendOutput $OutputBox "    • $($c.Name)  [Last Login: $ll]" "Gray"
        }
    }

    AppendOutput $OutputBox "═════════════════════════════════════════════════`n" "Cyan"
    Write-AuditLog "Audit preview generated." "INFO" | Out-Null
}

function AppendOutput {
    param(
        [System.Windows.Forms.RichTextBox]$Box,
        [string]$Text,
        [string]$Color = "White"
    )
    $Box.SelectionStart  = $Box.TextLength
    $Box.SelectionLength = 0
    $Box.SelectionColor  = [System.Drawing.Color]::FromName($Color)
    $Box.AppendText("$Text`n")
    $Box.ScrollToCaret()
}

function UpdateWhatIfUI {
    param($Label, $MoveBtn, $DeleteBtn)
    if ($script:Config.WhatIf) {
        $Label.Text      = "  MODE: DRY-RUN (No changes will be made)"
        $Label.ForeColor = [System.Drawing.Color]::Gold
        $MoveBtn.Text    = "▶ Run Move (Dry-Run)"
        $DeleteBtn.Text  = "▶ Run Delete (Dry-Run)"
    } else {
        $Label.Text      = "  MODE: LIVE (Changes WILL be committed to AD)"
        $Label.ForeColor = [System.Drawing.Color]::Tomato
        $MoveBtn.Text    = "▶ Run Move (LIVE)"
        $DeleteBtn.Text  = "▶ Run Delete (LIVE)"
    }
}

function Show-AuditGUI {

    $form                  = New-Object System.Windows.Forms.Form
    $form.Text             = "AD Computer Object Audit Tool"
    $form.Size             = New-Object System.Drawing.Size(900, 740)
    $form.StartPosition    = "CenterScreen"
    $form.BackColor        = [System.Drawing.Color]::FromArgb(30, 30, 30)
    $form.ForeColor        = [System.Drawing.Color]::WhiteSmoke
    $form.Font             = New-Object System.Drawing.Font("Segoe UI", 9)
    $form.FormBorderStyle  = "FixedSingle"
    $form.MaximizeBox      = $false

    $lblTitle           = New-Object System.Windows.Forms.Label
    $lblTitle.Text      = "Active Directory Computer Audit"
    $lblTitle.Font      = New-Object System.Drawing.Font("Segoe UI", 14, [System.Drawing.FontStyle]::Bold)
    $lblTitle.ForeColor = [System.Drawing.Color]::DodgerBlue
    $lblTitle.Location  = New-Object System.Drawing.Point(15, 12)
    $lblTitle.Size      = New-Object System.Drawing.Size(500, 30)
    $form.Controls.Add($lblTitle)

    $chkWhatIf           = New-Object System.Windows.Forms.CheckBox
    $chkWhatIf.Text      = "Dry-Run Mode (WhatIf)"
    $chkWhatIf.Checked   = $script:Config.WhatIf
    $chkWhatIf.Location  = New-Object System.Drawing.Point(620, 14)
    $chkWhatIf.Size      = New-Object System.Drawing.Size(200, 22)
    $chkWhatIf.ForeColor = [System.Drawing.Color]::WhiteSmoke
    $form.Controls.Add($chkWhatIf)

    $lblMode           = New-Object System.Windows.Forms.Label
    $lblMode.Location  = New-Object System.Drawing.Point(15, 45)
    $lblMode.Size      = New-Object System.Drawing.Size(860, 20)
    $lblMode.Font      = New-Object System.Drawing.Font("Segoe UI", 8, [System.Drawing.FontStyle]::Italic)
    $form.Controls.Add($lblMode)

    $grpSettings           = New-Object System.Windows.Forms.GroupBox
    $grpSettings.Text      = "Configuration"
    $grpSettings.Location  = New-Object System.Drawing.Point(15, 70)
    $grpSettings.Size      = New-Object System.Drawing.Size(860, 130)
    $grpSettings.ForeColor = [System.Drawing.Color]::LightSteelBlue
    $form.Controls.Add($grpSettings)

    $lblSearch           = New-Object System.Windows.Forms.Label
    $lblSearch.Text      = "Search Base OU:"
    $lblSearch.Location  = New-Object System.Drawing.Point(10, 22)
    $lblSearch.Size      = New-Object System.Drawing.Size(120, 20)
    $grpSettings.Controls.Add($lblSearch)

    $txtSearchBase           = New-Object System.Windows.Forms.TextBox
    $txtSearchBase.Text      = $script:Config.SearchBaseOU
    $txtSearchBase.Location  = New-Object System.Drawing.Point(135, 20)
    $txtSearchBase.Size      = New-Object System.Drawing.Size(700, 22)
    $txtSearchBase.BackColor = [System.Drawing.Color]::FromArgb(50, 50, 50)
    $txtSearchBase.ForeColor = [System.Drawing.Color]::WhiteSmoke
    $grpSettings.Controls.Add($txtSearchBase)

    $lblDisOU           = New-Object System.Windows.Forms.Label
    $lblDisOU.Text      = "Disabled Logins OU:"
    $lblDisOU.Location  = New-Object System.Drawing.Point(10, 52)
    $lblDisOU.Size      = New-Object System.Drawing.Size(120, 20)
    $grpSettings.Controls.Add($lblDisOU)

    $txtDisabledOU           = New-Object System.Windows.Forms.TextBox
    $txtDisabledOU.Text      = $script:Config.DisabledOU
    $txtDisabledOU.Location  = New-Object System.Drawing.Point(135, 50)
    $txtDisabledOU.Size      = New-Object System.Drawing.Size(700, 22)
    $txtDisabledOU.BackColor = [System.Drawing.Color]::FromArgb(50, 50, 50)
    $txtDisabledOU.ForeColor = [System.Drawing.Color]::WhiteSmoke
    $grpSettings.Controls.Add($txtDisabledOU)

    $lblInactive           = New-Object System.Windows.Forms.Label
    $lblInactive.Text      = "Inactive threshold (days):"
    $lblInactive.Location  = New-Object System.Drawing.Point(10, 84)
    $lblInactive.Size      = New-Object System.Drawing.Size(165, 20)
    $grpSettings.Controls.Add($lblInactive)

    $nudInactive                = New-Object System.Windows.Forms.NumericUpDown
    $nudInactive.Minimum        = 30
    $nudInactive.Maximum        = 3650
    $nudInactive.Value          = $script:Config.InactiveDays
    $nudInactive.Location       = New-Object System.Drawing.Point(180, 82)
    $nudInactive.Size           = New-Object System.Drawing.Size(70, 22)
    $nudInactive.BackColor      = [System.Drawing.Color]::FromArgb(50, 50, 50)
    $nudInactive.ForeColor      = [System.Drawing.Color]::WhiteSmoke
    $grpSettings.Controls.Add($nudInactive)

    $lblDelete           = New-Object System.Windows.Forms.Label
    $lblDelete.Text      = "Delete threshold (days):"
    $lblDelete.Location  = New-Object System.Drawing.Point(270, 84)
    $lblDelete.Size      = New-Object System.Drawing.Size(155, 20)
    $grpSettings.Controls.Add($lblDelete)

    $nudDelete                = New-Object System.Windows.Forms.NumericUpDown
    $nudDelete.Minimum        = 30
    $nudDelete.Maximum        = 3650
    $nudDelete.Value          = $script:Config.DeleteDays
    $nudDelete.Location       = New-Object System.Drawing.Point(430, 82)
    $nudDelete.Size           = New-Object System.Drawing.Size(70, 22)
    $nudDelete.BackColor      = [System.Drawing.Color]::FromArgb(50, 50, 50)
    $nudDelete.ForeColor      = [System.Drawing.Color]::WhiteSmoke
    $grpSettings.Controls.Add($nudDelete)

    $lblThresholdNote           = New-Object System.Windows.Forms.Label
    $lblThresholdNote.Text      = "  ← inactive threshold   |   delete threshold (inactive + 6 months recommended) →"
    $lblThresholdNote.Location  = New-Object System.Drawing.Point(505, 84)
    $lblThresholdNote.Size      = New-Object System.Drawing.Size(340, 20)
    $lblThresholdNote.ForeColor = [System.Drawing.Color]::DarkGray
    $grpSettings.Controls.Add($lblThresholdNote)

    $btnPreview           = New-Object System.Windows.Forms.Button
    $btnPreview.Text      = "🔍 Preview Audit"
    $btnPreview.Location  = New-Object System.Drawing.Point(15, 212)
    $btnPreview.Size      = New-Object System.Drawing.Size(160, 36)
    $btnPreview.BackColor = [System.Drawing.Color]::FromArgb(30, 80, 150)
    $btnPreview.ForeColor = [System.Drawing.Color]::White
    $btnPreview.FlatStyle = "Flat"
    $form.Controls.Add($btnPreview)

    $btnMove           = New-Object System.Windows.Forms.Button
    $btnMove.Location  = New-Object System.Drawing.Point(190, 212)
    $btnMove.Size      = New-Object System.Drawing.Size(200, 36)
    $btnMove.BackColor = [System.Drawing.Color]::FromArgb(30, 110, 60)
    $btnMove.ForeColor = [System.Drawing.Color]::White
    $btnMove.FlatStyle = "Flat"
    $form.Controls.Add($btnMove)

    $btnDelete           = New-Object System.Windows.Forms.Button
    $btnDelete.Location  = New-Object System.Drawing.Point(405, 212)
    $btnDelete.Size      = New-Object System.Drawing.Size(210, 36)
    $btnDelete.BackColor = [System.Drawing.Color]::FromArgb(130, 40, 40)
    $btnDelete.ForeColor = [System.Drawing.Color]::White
    $btnDelete.FlatStyle = "Flat"
    $form.Controls.Add($btnDelete)

    $btnClearLog           = New-Object System.Windows.Forms.Button
    $btnClearLog.Text      = "Clear Output"
    $btnClearLog.Location  = New-Object System.Drawing.Point(700, 212)
    $btnClearLog.Size      = New-Object System.Drawing.Size(100, 36)
    $btnClearLog.BackColor = [System.Drawing.Color]::FromArgb(60, 60, 60)
    $btnClearLog.ForeColor = [System.Drawing.Color]::White
    $btnClearLog.FlatStyle = "Flat"
    $form.Controls.Add($btnClearLog)

    $btnOpenLog           = New-Object System.Windows.Forms.Button
    $btnOpenLog.Text      = "📂 Open Log Folder"
    $btnOpenLog.Location  = New-Object System.Drawing.Point(805, 212)
    $btnOpenLog.Size      = New-Object System.Drawing.Size(70, 36)
    $btnOpenLog.BackColor = [System.Drawing.Color]::FromArgb(60, 60, 60)
    $btnOpenLog.ForeColor = [System.Drawing.Color]::White
    $btnOpenLog.FlatStyle = "Flat"
    $form.Controls.Add($btnOpenLog)

    $rtbOutput                    = New-Object System.Windows.Forms.RichTextBox
    $rtbOutput.Location           = New-Object System.Drawing.Point(15, 260)
    $rtbOutput.Size               = New-Object System.Drawing.Size(860, 420)
    $rtbOutput.BackColor          = [System.Drawing.Color]::FromArgb(15, 15, 15)
    $rtbOutput.ForeColor          = [System.Drawing.Color]::LightGray
    $rtbOutput.Font               = New-Object System.Drawing.Font("Consolas", 9)
    $rtbOutput.ReadOnly           = $true
    $rtbOutput.ScrollBars         = "Vertical"
    $rtbOutput.WordWrap           = $false
    $form.Controls.Add($rtbOutput)

    $statusBar              = New-Object System.Windows.Forms.StatusStrip
    $statusLabel            = New-Object System.Windows.Forms.ToolStripStatusLabel
    $statusLabel.Text       = "Ready"
    $statusBar.Items.Add($statusLabel) | Out-Null
    $form.Controls.Add($statusBar)

    UpdateWhatIfUI $lblMode $btnMove $btnDelete

    AppendOutput $rtbOutput "AD Computer Audit Tool loaded." "DodgerBlue"
    AppendOutput $rtbOutput "• Configure your OU paths and thresholds above before running." "Gray"
    AppendOutput $rtbOutput "• Dry-Run Mode is ON by default — uncheck to commit real changes." "Gold"
    AppendOutput $rtbOutput "• Use 'Preview Audit' to see what would be affected without taking any action.`n" "Gray"


    $chkWhatIf.Add_CheckedChanged({
        $script:Config.WhatIf = $chkWhatIf.Checked
        UpdateWhatIfUI $lblMode $btnMove $btnDelete
        $modeStr = if ($script:Config.WhatIf) { "DRY-RUN" } else { "LIVE" }
        AppendOutput $rtbOutput "Mode switched to: $modeStr" "Cyan"
    })

    $btnPreview.Add_Click({
        $script:Config.SearchBaseOU = $txtSearchBase.Text.Trim()
        $script:Config.DisabledOU   = $txtDisabledOU.Text.Trim()
        $script:Config.InactiveDays = [int]$nudInactive.Value
        $script:Config.DeleteDays   = [int]$nudDelete.Value

        $statusLabel.Text = "Running preview..."
        $form.Refresh()
        Invoke-PreviewAudit -OutputBox $rtbOutput
        $statusLabel.Text = "Preview complete."
    })

    $btnMove.Add_Click({
        $script:Config.SearchBaseOU = $txtSearchBase.Text.Trim()
        $script:Config.DisabledOU   = $txtDisabledOU.Text.Trim()
        $script:Config.InactiveDays = [int]$nudInactive.Value
        $script:Config.DeleteDays   = [int]$nudDelete.Value

        if (-not $script:Config.WhatIf) {
            $confirm = [System.Windows.Forms.MessageBox]::Show(
                "You are about to MOVE computer objects in Active Directory.`nThis is a LIVE operation.`n`nContinue?",
                "Confirm Live Move",
                [System.Windows.Forms.MessageBoxButtons]::YesNo,
                [System.Windows.Forms.MessageBoxIcon]::Warning
            )
            if ($confirm -ne "Yes") {
                AppendOutput $rtbOutput "Move cancelled by user." "Gray"
                return
            }
        }

        $statusLabel.Text = "Moving inactive computers..."
        $form.Refresh()
        AppendOutput $rtbOutput "`n─── Move Inactive Computers ─────────────────────" "DodgerBlue"
        Invoke-MoveInactiveComputers -OutputBox $rtbOutput
        $statusLabel.Text = "Move complete."
    })

    $btnDelete.Add_Click({
        $script:Config.SearchBaseOU = $txtSearchBase.Text.Trim()
        $script:Config.DisabledOU   = $txtDisabledOU.Text.Trim()
        $script:Config.InactiveDays = [int]$nudInactive.Value
        $script:Config.DeleteDays   = [int]$nudDelete.Value

        if (-not $script:Config.WhatIf) {
            $confirm = [System.Windows.Forms.MessageBox]::Show(
                "You are about to PERMANENTLY DELETE computer objects from Active Directory.`nThis action CANNOT be undone.`n`nAre you absolutely sure?",
                "Confirm Permanent Deletion",
                [System.Windows.Forms.MessageBoxButtons]::YesNo,
                [System.Windows.Forms.MessageBoxIcon]::Error
            )
            if ($confirm -ne "Yes") {
                AppendOutput $rtbOutput "Deletion cancelled by user." "Gray"
                return
            }
        }

        $statusLabel.Text = "Deleting stale disabled computers..."
        $form.Refresh()
        AppendOutput $rtbOutput "`n─── Delete Stale Disabled Computers ─────────────" "Tomato"
        Invoke-DeleteDisabledComputers -OutputBox $rtbOutput
        $statusLabel.Text = "Delete operation complete."
    })

    $btnClearLog.Add_Click({
        $rtbOutput.Clear()
        AppendOutput $rtbOutput "Output cleared." "Gray"
    })

    $btnOpenLog.Add_Click({
        if (Test-Path $script:Config.LogDirectory) {
            Start-Process "explorer.exe" $script:Config.LogDirectory
        } else {
            AppendOutput $rtbOutput "Log directory does not exist yet. Run an operation first." "Gray"
        }
    })


    [void]$form.ShowDialog()
}

Show-AuditGUI
