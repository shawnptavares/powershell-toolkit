#Load PowerShell modules (optional, adjust based on your environment)
Import-Module -Name Terminal-Icons -ErrorAction SilentlyContinue
Import-Module ActiveDirectory -ErrorAction SilentlyContinue
Import-Module Microsoft.Graph -ErrorAction SilentlyContinue
Import-Module "$PSScriptRoot\modules\admpwd.ps1" -ErrorAction SilentlyContinue

#Oh-My-Posh theme (adjust path or theme as needed)
oh-my-posh init pwsh --config "$env:POSH_THEMES_PATH\tonybaloney.omp.json" | Invoke-Expression

#Quick edit profile shortcut
function Pro {
    notepad $profile
}
function LAPS {
    param (
        [Parameter(Mandatory)]
        [string]$ComputerName
    )

    $password = Get-AdmPwdPassword -ComputerName $ComputerName | Select-Object -ExpandProperty Password
    $masked = '*' * $password.Length

    Write-Host "`nThe local administrator password for $ComputerName is:" -ForegroundColor Green
    Write-Host "`n$masked" -ForegroundColor Yellow
    Write-Host "$password" -ForegroundColor Yellow
    Write-Host "$masked" -ForegroundColor Yellow

    $password | Set-Clipboard
    Write-Host "`nPassword copied to clipboard." -ForegroundColor Cyan
}

#Retrieve BitLocker recovery keys
function Get-BitLockerKey {
    param (
        [Parameter(Mandatory)]
        [string]$ComputerName,

        [Parameter(Mandatory)]
        [ValidateSet("ad", "aad")]
        [string]$Mode
    )

    try {
        if ($Mode -eq "ad") {
            $computer = Get-ADComputer -Identity $ComputerName -ErrorAction Stop
            $keys = Get-ADObject -Filter {ObjectClass -eq 'msFVE-RecoveryInformation'} -SearchBase $computer.DistinguishedName -Properties 'msFVE-RecoveryPassword','whenCreated'

            if ($keys) {
                foreach ($key in $keys) {
                    Write-Host "Recovery Password: $($key.'msFVE-RecoveryPassword')" -ForegroundColor Green
                    Write-Host "Created On: $($key.whenCreated)" -ForegroundColor Green
                }
                if ($keys.Count -gt 1) {
                    Write-Warning "Multiple keys found. Use the most recent."
                }
            } else {
                Write-Warning "No keys found in AD."
            }
        }
        elseif ($Mode -eq "aad") {
            Connect-MgGraph -Scopes "DeviceManagementManagedDevices.Read.All BitLockerKey.Read.All"
            $keys = Get-MgInformationProtectionBitlockerRecoveryKey -Filter "DeviceName eq '$ComputerName'" -ErrorAction Stop

            if ($keys) {
                foreach ($key in $keys) {
                    Write-Host "Recovery Password: $($key.RecoveryPassword)" -ForegroundColor Green
                }
                if ($keys.Count -gt 1) {
                    Write-Warning "Multiple keys found. Use the most recent."
                }
            } else {
                Write-Warning "No keys found in AAD."
            }
        }
    } catch {
        Write-Warning "Error: $_"
    }
}

#Generate a strong or simple password using DinoPass
function DinoPass {
    param (
        [switch]$Strong,
        [switch]$Simple
    )

    $url = if ($Strong) {
        'https://www.dinopass.com/password/strong'
    } elseif ($Simple) {
        'https://www.dinopass.com/password/simple'
    } else {
        'https://www.dinopass.com/password/strong'
    }

    $password = Invoke-RestMethod -Uri $url
    $masked = '*' * $password.Length

    Write-Host "`nThe generated DinoPass password is:" -ForegroundColor Green
    Write-Host "$masked" -ForegroundColor Yellow
    Write-Host "$password" -ForegroundColor Yellow
    Write-Host "$masked" -ForegroundColor Yellow

    $password | Set-Clipboard
    Write-Host "Password copied to clipboard." -ForegroundColor Cyan
}

#Include the purge function unmodified, as it is parameter-based and secure
function purge {
function purge {

[CmdletBinding(DefaultParameterSetName='All')]
Param
(
    [Parameter(ParameterSetName='All',Mandatory=$true,ValueFromPipelineByPropertyName=$true,ValueFromPipeline=$true)]
    [Parameter(ParameterSetName='Individual',Mandatory=$true,ValueFromPipelineByPropertyName=$true,ValueFromPipeline=$true)]
    [string[]]$ComputerName,
    [Parameter(ParameterSetName='All')]
    [switch]$All = $True,
    [Parameter(ParameterSetName='Individual')]
    [switch]$AD,
    [Parameter(ParameterSetName='Individual')]
    [switch]$AAD,
    [Parameter(ParameterSetName='Individual')]
    [switch]$Intune,
    [Parameter(ParameterSetName='Individual')]
    [switch]$Autopilot,
    [Parameter(ParameterSetName='Individual')]
    [switch]$ConfigMgr
)

Begin
{
    Set-Location $env:SystemDrive

    #Load required modules
    #region Modules
    If ($PSBoundParameters.ContainsKey("AAD") -or $PSBoundParameters.ContainsKey("Intune") -or $PSBoundParameters.ContainsKey("Autopilot") -or $PSBoundParameters.ContainsKey("All"))
    {
        Write-Host "Importing modules"
        #Get NuGet
        $provider = Get-PackageProvider NuGet –ErrorAction Ignore
        if (-not $provider) 
        {
            Write-Host "Installing provider NuGet…" –NoNewline
            try 
            {
                Find-PackageProvider –Name NuGet –ForceBootstrap –IncludeDependencies –Force –ErrorAction Stop
                Write-Host "Success" –ForegroundColor Green
            }
            catch 
            {
                Write-Host "Failed" –ForegroundColor Red
                throw $_.Exception.Message
                return
            }
        }

        $module = Import-Module Microsoft.Graph.Identity.DirectoryManagement –PassThru –ErrorAction Ignore
        if (-not $module)
        {
            Write-Host "Installing module Microsoft.Graph.Identity.DirectoryManagement…" –NoNewline
            try 
            {
                Install-Module Microsoft.Graph.Identity.DirectoryManagement –Scope CurrentUser –Force –ErrorAction Ignore
                Write-Host "Success" –ForegroundColor Green
            }
            catch 
            {
                Write-Host "Failed" –ForegroundColor Red
                throw $_.Exception.Message
                return
            }     
        }

        $module = Import-Module Microsoft.Graph.DeviceManagement –PassThru –ErrorAction Ignore
        if (-not $module)
        {
            Write-Host "Installing module Microsoft.Graph.DeviceManagement…" –NoNewline
            try 
            {
                Install-Module Microsoft.Graph.DeviceManagement –Scope CurrentUser –Force –ErrorAction Ignore
                Write-Host "Success" –ForegroundColor Green
            }
            catch 
            {
                Write-Host "Failed" –ForegroundColor Red
                throw $_.Exception.Message
                return
            }         
        }

        $module = Import-Module Microsoft.Graph.DeviceManagement.Enrollment –PassThru –ErrorAction Ignore
        if (-not $module)
        {
            Write-Host "Installing module Microsoft.Graph.DeviceManagement.Enrollment…" –NoNewline
            try 
            {
                Install-Module Microsoft.Graph.DeviceManagement.Enrollment –Scope CurrentUser –Force -AllowClobber –ErrorAction Ignore
                Write-Host "Success" –ForegroundColor Green
            }
            catch 
            {
                Write-Host "Failed" –ForegroundColor Red
                throw $_.Exception.Message
                return
            } 
        }
    }
    If ($PSBoundParameters.ContainsKey("ConfigMgr") -or $PSBoundParameters.ContainsKey("All"))
    {
        $SMSEnvVar = [System.Environment]::GetEnvironmentVariable('SMS_ADMIN_UI_PATH') 
        If ($SMSEnvVar)
        {
            $ModulePath = $SMSEnvVar.Replace('i386','ConfigurationManager.psd1') 
            if ([System.IO.File]::Exists($ModulePath))
            {
                try 
                {
                    Import-Module $ModulePath –ErrorAction Stop
                }
                catch 
                {
                    throw "Failed to import ConfigMgr module: $($_.Exception.Message)"
                }
            }
            else 
            {
                throw "ConfigMgr module not found"
            }
        }
        else 
        {
            throw "SMS_ADMIN_UI_PATH environment variable not found"
        }
    }
    #endregion

    #region Auth
    If ($PSBoundParameters.ContainsKey("AAD") -or $PSBoundParameters.ContainsKey("Intune") -or $PSBoundParameters.ContainsKey("Autopilot") -or $PSBoundParameters.ContainsKey("All"))
    {
        Write-Host "Authenticating…" –NoNewline
        try 
        {
            $null = Connect-MgGraph –Scopes "Directory.AccessAsUser.All","DeviceManagementManagedDevices.ReadWrite.All","DeviceManagementServiceConfig.ReadWrite.All" –ErrorAction Stop
            #$null = Connect-MgGraph -Scopes "Directory.AccessAsUser.All","DeviceManagementServiceConfig.ReadWrite.All" -ErrorAction Stop
            Write-Host "Success" –ForegroundColor Green
        }
        catch 
        {
            Write-Host "Failed" –ForegroundColor Red
            throw $_.Exception.Message
        }
    }
    #endregion
}
Process
{
    foreach ($Computer in $ComputerName)
    {
        Write-Host "===============" 
        Write-host "$($Computer.ToUpper())" 
        Write-Host "===============" 

        #region AD
        If ($PSBoundParameters.ContainsKey("AD") -or $PSBoundParameters.ContainsKey("All"))
        {
            Try
            {
                Write-host "Locating device in " –NoNewline
                Write-host "Active Directory" –ForegroundColor Blue –NoNewline
                Write-Host "…" –NoNewline
                $Searcher = [ADSISearcher]::new()
                $Searcher.Filter = "(sAMAccountName=$Computer`$)"
                [void]$Searcher.PropertiesToLoad.Add("distinguishedName")
                $ComputerAccount = $Searcher.FindOne()
                If ($ComputerAccount)
                {
                    Write-host "Success" –ForegroundColor Green
                    Write-Host "Removing device from" –NoNewline
                    Write-Host "Active Directory" –NoNewline –ForegroundColor Blue
                    Write-Host "…" –NoNewline
                    $DirectoryEntry = $ComputerAccount.GetDirectoryEntry()
                    $Result = $DirectoryEntry.DeleteTree()
                    Write-Host "Success" –ForegroundColor Green
                }
                Else
                {
                    Write-host "Fail" –ForegroundColor Red
                    Write-Warning "Device not found in Active Directory"  
                }
            }
            Catch
            {
                Write-host "Fail" –ForegroundColor Red
                Write-Error "$($_.Exception.Message)"
            }
        }
        #endregion

        #region AzureAD
        If ($PSBoundParameters.ContainsKey("AAD") -or $PSBoundParameters.ContainsKey("All"))
        {
            Write-Host "Locating device in" –NoNewline
            Write-Host " Azure AD" –NoNewline –ForegroundColor Yellow
            Write-Host "…" –NoNewline
            try 
            {
                $AADDevice = Get-MgDevice –Search "displayName:$Computer" –CountVariable CountVar –ConsistencyLevel eventual –ErrorAction Stop
            }
            catch 
            {
                Write-Host "Fail" –ForegroundColor Red
                Write-Error "$($_.Exception.Message)"
                $LocateInAADFailure = $true
            }
            
            If ($LocateInAADFailure -ne $true)
            {
                If ($AADDevice.Count -eq 1)
                {
                    Write-Host "Success" –ForegroundColor Green
                    Write-Host "  DisplayName: $($AADDevice.DisplayName)"
                    Write-Host "  ObjectId: $($AADDevice.Id)"
                    Write-Host "  DeviceId: $($AADDevice.DeviceId)"

                    Write-Host "Removing device from" –NoNewline
                    Write-Host " Azure AD" –NoNewline –ForegroundColor Yellow
                    Write-Host "…" –NoNewline
                    try 
                    {
                        $Result = Remove-MgDevice –DeviceId $AADDevice.Id –PassThru –ErrorAction Stop
                        If ($Result -eq $true)
                        {
                            Write-Host "Success" –ForegroundColor Green
                        }
                        else 
                        {
                            Write-Host "Fail" –ForegroundColor Red
                        }
                    }
                    catch 
                    {
                        Write-Host "Fail" –ForegroundColor Red
                        Write-Error "$($_.Exception.Message)"
                    }
                    
                }
                ElseIf ($AADDevice.Count -gt 1)
                {
                    Write-Host "Fail" –ForegroundColor Red
                    Write-Warning "Multiple devices found in Azure AD. The device display name must be unique." 
                }
                else 
                {
                    Write-Host "Fail" –ForegroundColor Red
                    Write-Warning "Device not found in Azure AD"    
                }
            }
        }
        #endregion

        #region Intune
        If ($PSBoundParameters.ContainsKey("Intune") -or $PSBoundParameters.ContainsKey("Autopilot") -or $PSBoundParameters.ContainsKey("All"))
        {
            Write-Host "Locating device in" –NoNewline
            Write-Host " Intune" –NoNewline –ForegroundColor Cyan
            Write-Host "…" –NoNewline

            try 
            {
                $IntuneDevice = Get-MgDeviceManagementManagedDevice –Filter "deviceName eq '$Computer'" –ErrorAction Stop
            }
            catch 
            {
                Write-Host "Fail" –ForegroundColor Red
                Write-Error "$($_.Exception.Message)"
                $LocateInIntuneFailure = $true
            }
            
            If ($LocateInIntuneFailure -ne $true)
            {
                If ($IntuneDevice.Count -eq 1)
                {
                    Write-Host "Success" –ForegroundColor Green
                    Write-Host "  DeviceName: $($IntuneDevice.DeviceName)"
                    Write-Host "  ObjectId: $($IntuneDevice.Id)"
                    Write-Host "  AzureAdDeviceId: $($IntuneDevice.AzureAdDeviceId)"

                    Write-Host "Removing device from" –NoNewline
                    Write-Host " Intune" –NoNewline –ForegroundColor Cyan
                    Write-Host "…" –NoNewline
                    try 
                    {
                        $Result = Remove-MgDeviceManagementManagedDevice –ManagedDeviceId $IntuneDevice.Id –PassThru –ErrorAction Stop
                        If ($Result -eq $true)
                        {
                            Write-Host "Success" –ForegroundColor Green
                        }
                        else 
                        {
                            Write-Host "Fail" –ForegroundColor Red
                        }
                    }
                    catch 
                    {
                        Write-Host "Fail" –ForegroundColor Red
                        Write-Error "$($_.Exception.Message)"
                    }           
                }
                ElseIf ($IntuneDevice.Count -gt 1)
                {
                    Write-Host "Fail" –ForegroundColor Red
                    Write-Warning "Multiple devices found in Intune. The device display name must be unique." 
                }
                else 
                {
                    Write-Host "Fail" –ForegroundColor Red
                    Write-Warning "Device not found in Intune"    
                }
            }
        }
        #endregion

        #region Autopilot
        If (($PSBoundParameters.ContainsKey("Autopilot") -or $PSBoundParameters.ContainsKey("All")) -and $IntuneDevice.Count -eq 1)
        {
            Write-Host "Locating device in" –NoNewline
            Write-Host " Windows Autopilot" –NoNewline –ForegroundColor Cyan
            Write-Host "…" –NoNewline

            try
            {
                $AutopilotDevice = Get-MgDeviceManagementWindowsAutopilotDeviceIdentity –Filter "contains(serialNumber,'$($IntuneDevice.SerialNumber)')" –ErrorAction Stop
            }
            catch
            {
                Write-Host "Fail" –ForegroundColor Red
                Write-Error "$($_.Exception.Message)"
                $LocateInAutopilotFailure = $true
            }

            If ($LocateInAutopilotFailure -ne $true)
            {
                If ($AutopilotDevice.Count -eq 1)
                {
                    Write-Host "Success" –ForegroundColor Green
                    Write-Host "  SerialNumber: $($AutopilotDevice.SerialNumber)"
                    Write-Host "  Id: $($AutopilotDevice.Id)"
                    Write-Host "  ManagedDeviceId: $($AutopilotDevice.ManagedDeviceId)"
                    Write-Host "  Model: $($AutopilotDevice.Model)"
                    Write-Host "  GroupTag: $($AutopilotDevice.GroupTag)"

                    Write-Host "Removing device from" –NoNewline
                    Write-Host " Windows Autopilot" –NoNewline –ForegroundColor Cyan
                    Write-Host "…" –NoNewline
                    try 
                    {
                        $Result = Remove-MgDeviceManagementWindowsAutopilotDeviceIdentity –WindowsAutopilotDeviceIdentityId $AutopilotDevice.Id –PassThru –ErrorAction Stop
                        If ($Result -eq $true)
                        {
                            Write-Host "Success" –ForegroundColor Green
                        }
                        else 
                        {
                            Write-Host "Fail" –ForegroundColor Red
                        }
                    }
                    catch 
                    {
                        Write-Host "Fail" –ForegroundColor Red
                        Write-Error "$($_.Exception.Message)"
                    }           
                }
                ElseIf ($AutopilotDevice.Count -gt 1)
                {
                    Write-Host "Fail" –ForegroundColor Red
                    Write-Warning "Multiple devices found in Windows Autopilot. The serial number must be unique." 
                    Continue
                }
                else 
                {
                    Write-Host "Fail" –ForegroundColor Red
                    Write-Warning "Device not found in Windows Autopilot"    
                }
            }
        }
        #endregion

        #region ConfigMgr
        If ($PSBoundParameters.ContainsKey("ConfigMgr") -or $PSBoundParameters.ContainsKey("All"))
        {
            Write-host "Locating device in " –NoNewline
            Write-host "ConfigMgr " –ForegroundColor Magenta –NoNewline
            Write-host "…" –NoNewline
            Try
            {
                $SiteCode = (Get-PSDrive –PSProvider CMSITE –ErrorAction Stop).Name
                Set-Location ("$SiteCode" + ":") –ErrorAction Stop
                [array]$ConfigMgrDevices = Get-CMDevice –Name $Computer –Fast –ErrorAction Stop      
            }
            Catch
            {
                Write-Host "Fail" –ForegroundColor Red
                Write-Error "$($_.Exception.Message)"
                $LocateInConfigMgrFailure = $true
            }

            If ($LocateInConfigMgrFailure -ne $true)
            {
                If ($ConfigMgrDevices.count -eq 1)
                {
                    $ConfigMgrDevice = $ConfigMgrDevices[0]
                    Write-Host "Success" –ForegroundColor Green
                    Write-Host "  ResourceID: $($ConfigMgrDevice.ResourceID)"
                    Write-Host "  SMSID: $($ConfigMgrDevice.SMSID)"
                    Write-Host "  UserDomainName: $($ConfigMgrDevice.UserDomainName)"

                    Write-Host "Removing device from" –NoNewline
                    Write-Host " ConfigMgr" –NoNewline –ForegroundColor Magenta
                    Write-Host "…" –NoNewline
                    
                    try 
                    {
                        Remove-CMDevice –InputObject $ConfigMgrDevice –Force –ErrorAction Stop
                        Write-Host "Success" –ForegroundColor Green
                    }
                    catch 
                    {
                        Write-Host "Fail" –ForegroundColor Red
                        Write-Error "$($_.Exception.Message)"
                    }
                }
                ElseIf ($ConfigMgrDevices.Count -gt 1)
                {
                    Write-Host "Fail" –ForegroundColor Red
                    Write-Warning "Multiple devices found in ConfigMgr The device name must be unique." 
                    Continue
                }
                else 
                {
                    Write-Host "Fail" –ForegroundColor Red
                    Write-Warning "Device not found in ConfigMgr"    
                }
            }
        }
        #endregion
    }
}
End
{
    Set-Location $env:SystemDrive

    If ($PSBoundParameters.ContainsKey("AAD") -or $PSBoundParameters.ContainsKey("Intune") -or $PSBoundParameters.ContainsKey("Autopilot") -or $PSBoundParameters.ContainsKey("All"))
    {
      #  $null = Disconnect-MgGraph –ErrorAction SilentlyContinue
    }
}
}
}

#Clear the terminal and run a basic system fetch
Clear-Host
if (Get-Command winfetch -ErrorAction SilentlyContinue) {
    winfetch
} else {
    Write-Host "winfetch not found. Skipping system info display." -ForegroundColor Yellow
}
