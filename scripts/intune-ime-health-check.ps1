<#
.SYNOPSIS
    Verifies the Intune Management Extension (IME) installation and health status on a Windows device.

.DESCRIPTION
    This script performs a comprehensive health check of the Microsoft Intune Management Extension (IME)
    on the local Windows device. It validates the IME service state, confirms the agent executable exists
    on disk, reads the IME registry configuration, and optionally triggers an Intune scheduled task sync
    to accelerate policy delivery. Additionally, it writes a test registry key to confirm that script
    execution via the IME pipeline is functioning correctly.

    Use this script during Intune pilot deployments, troubleshooting sessions, or as part of a
    post-enrollment validation runbook to ensure every managed device has a healthy IME footprint.

.NOTES
    Author:      Souhaiel Morhag
    Company:     MSEndpoint.com
    Blog:        https://msendpoint.com
    Academy:     https://app.msendpoint.com/academy
    LinkedIn:    https://linkedin.com/in/souhaiel-morhag
    GitHub:      https://github.com/Msendpoint
    License:     MIT

.EXAMPLE
    # Run locally on a managed device to verify IME health
    .\Invoke-IMEHealthCheck.ps1

.EXAMPLE
    # Run with verbose output and trigger a device sync
    .\Invoke-IMEHealthCheck.ps1 -TriggerSync -Verbose
#>

[CmdletBinding()]
param (
    # When specified, the script will attempt to trigger all Intune-related scheduled tasks
    # to force an immediate policy sync rather than waiting for the default 8-hour cycle.
    [Parameter(Mandatory = $false)]
    [switch]$TriggerSync,

    # Registry path used for the IME test key write validation.
    [Parameter(Mandatory = $false)]
    [string]$TestRegistryPath = 'HKLM:\SOFTWARE\IMETest'
)

#region --- Helper Function ---
function Write-Result {
    param (
        [string]$Label,
        [string]$Value,
        [ValidateSet('Info', 'Success', 'Warning', 'Error')]
        [string]$Status = 'Info'
    )
    $colors = @{ Info = 'Cyan'; Success = 'Green'; Warning = 'Yellow'; Error = 'Red' }
    Write-Host "[$Status] $Label : $Value" -ForegroundColor $colors[$Status]
}
#endregion

#region --- 1. IME Service Check ---
Write-Verbose 'Checking Microsoft Intune Management Extension service...'
try {
    $imeService = Get-Service -Name 'IntuneManagementExtension' -ErrorAction Stop

    $serviceStatus = $imeService.Status
    $startType     = $imeService.StartType

    if ($serviceStatus -eq 'Running') {
        Write-Result -Label 'IME Service Status' -Value $serviceStatus -Status 'Success'
    } else {
        Write-Result -Label 'IME Service Status' -Value $serviceStatus -Status 'Warning'
        Write-Warning 'IME service is not running. Attempting to start it...'
        try {
            Start-Service -Name 'IntuneManagementExtension' -ErrorAction Stop
            Write-Result -Label 'IME Service Start' -Value 'Started successfully' -Status 'Success'
        } catch {
            Write-Result -Label 'IME Service Start' -Value $_.Exception.Message -Status 'Error'
        }
    }

    Write-Result -Label 'IME Service StartType' -Value $startType -Status 'Info'
} catch {
    Write-Result -Label 'IME Service' -Value 'Service not found — IME may not be installed yet.' -Status 'Error'
    Write-Verbose $_.Exception.Message
}
#endregion

#region --- 2. IME Executable Presence Check ---
Write-Verbose 'Verifying IME agent executable on disk...'
$imeExePath = 'C:\Program Files (x86)\Microsoft Intune Management Extension\Microsoft.Management.Services.IntuneWindowsAgent.exe'

if (Test-Path -Path $imeExePath) {
    Write-Result -Label 'IME Executable' -Value "Found at $imeExePath" -Status 'Success'
} else {
    Write-Result -Label 'IME Executable' -Value "NOT found at expected path: $imeExePath" -Status 'Error'
}
#endregion

#region --- 3. IME Registry Configuration Check ---
Write-Verbose 'Reading IME registry configuration...'
$imeRegPath = 'HKLM:\SOFTWARE\Microsoft\IntuneManagementExtension'

try {
    $imeRegProps = Get-ItemProperty -Path $imeRegPath -ErrorAction Stop
    Write-Result -Label 'IME Registry Key' -Value 'Present' -Status 'Success'
    Write-Verbose ($imeRegProps | Out-String)
} catch {
    Write-Result -Label 'IME Registry Key' -Value "Not found at $imeRegPath" -Status 'Warning'
    Write-Verbose $_.Exception.Message
}
#endregion

#region --- 4. Test Registry Write (Script Execution Validation) ---
Write-Verbose "Writing test registry key to $TestRegistryPath to validate script execution context..."
try {
    # Create the registry path if it does not already exist
    if (-not (Test-Path -Path $TestRegistryPath)) {
        New-Item -Path $TestRegistryPath -Force | Out-Null
        Write-Verbose "Created registry path: $TestRegistryPath"
    }

    # Write the validation property
    New-ItemProperty -Path $TestRegistryPath `
                     -Name 'IMEHealthCheck' `
                     -Value ([datetime]::UtcNow.ToString('o')) `
                     -PropertyType String `
                     -Force | Out-Null

    Write-Result -Label 'Test Registry Write' -Value "Key written to $TestRegistryPath\IMEHealthCheck" -Status 'Success'
} catch {
    Write-Result -Label 'Test Registry Write' -Value $_.Exception.Message -Status 'Error'
}
#endregion

#region --- 5. Optional: Trigger Intune Device Sync ---
if ($TriggerSync) {
    Write-Verbose 'TriggerSync specified — starting all Intune-related scheduled tasks...'
    try {
        $intuneTasks = Get-ScheduledTask | Where-Object { $_.TaskName -like '*Intune*' }

        if ($intuneTasks) {
            foreach ($task in $intuneTasks) {
                try {
                    Start-ScheduledTask -TaskName $task.TaskName -TaskPath $task.TaskPath -ErrorAction Stop
                    Write-Result -Label 'Scheduled Task Triggered' -Value $task.TaskName -Status 'Success'
                } catch {
                    Write-Result -Label 'Scheduled Task Error' -Value "$($task.TaskName): $($_.Exception.Message)" -Status 'Warning'
                }
            }
        } else {
            Write-Result -Label 'Scheduled Tasks' -Value 'No Intune-related scheduled tasks found.' -Status 'Warning'
        }
    } catch {
        Write-Result -Label 'Trigger Sync' -Value $_.Exception.Message -Status 'Error'
    }
} else {
    Write-Result -Label 'Device Sync' -Value 'Skipped (use -TriggerSync to force a policy sync).' -Status 'Info'
}
#endregion

#region --- 6. IME Log Directory Check ---
Write-Verbose 'Checking IME log directory...'
$imeLogPath = 'C:\ProgramData\Microsoft\IntuneManagementExtension\Logs'

if (Test-Path -Path $imeLogPath) {
    $logFiles = Get-ChildItem -Path $imeLogPath -Filter '*.log' | Sort-Object LastWriteTime -Descending
    Write-Result -Label 'IME Log Directory' -Value "Found — $($logFiles.Count) log file(s) present" -Status 'Success'
    Write-Verbose 'Most recent log files:'
    $logFiles | Select-Object -First 5 | ForEach-Object {
        Write-Verbose "  $($_.Name)  [Last modified: $($_.LastWriteTime)]"
    }
} else {
    Write-Result -Label 'IME Log Directory' -Value "Not found at $imeLogPath — IME may not have run yet." -Status 'Warning'
}
#endregion

Write-Host ''
Write-Host '--- IME Health Check Complete ---' -ForegroundColor Cyan
