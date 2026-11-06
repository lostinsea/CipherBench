[CmdletBinding()]
param(
    [string]$ExecutablePath,
    [ValidateRange(1, 120)]
    [int]$StartupTimeoutSeconds = 30,
    [ValidateRange(0, 30)]
    [int]$WarmupSeconds = 5,
    [ValidateRange(1, 120)]
    [int]$ShutdownTimeoutSeconds = 20
)

$ErrorActionPreference = 'Stop'

if ([string]::IsNullOrWhiteSpace($ExecutablePath)) {
    $ExecutablePath = Join-Path $PSScriptRoot '..\build\windows\x64\runner\Release\cipherbench.exe'
}

Add-Type @'
using System;
using System.Runtime.InteropServices;

public static class WindowVisibility {
    [DllImport("user32.dll")]
    [return: MarshalAs(UnmanagedType.Bool)]
    public static extern bool IsWindowVisible(IntPtr hWnd);
}
'@

function Test-TargetPidPresent {
    param(
        [int]$ProcessId,
        [string]$ProcessName
    )

    $nameMatches = @(
        Get-Process -Name $ProcessName -ErrorAction SilentlyContinue |
            Where-Object { $_.Id -eq $ProcessId }
    )
    $cimMatch = Get-CimInstance -ClassName Win32_Process -Filter "ProcessId = $ProcessId" -ErrorAction SilentlyContinue

    [pscustomobject]@{
        InProcessNameEnumeration = $nameMatches.Count -gt 0
        InCimEnumeration         = $null -ne $cimMatch
    }
}

try {
    $resolvedExecutablePath = (Resolve-Path -LiteralPath $ExecutablePath).Path
    if (-not (Test-Path -LiteralPath $resolvedExecutablePath -PathType Leaf)) {
        throw "Executable path is not a file: $resolvedExecutablePath"
    }

    $processName = [IO.Path]::GetFileNameWithoutExtension($resolvedExecutablePath)
    if (Get-Process -Name $processName -ErrorAction SilentlyContinue) {
        throw "Close all existing $processName instances before running this test."
    }

    Write-Host "Starting executable: $resolvedExecutablePath"
    $process = Start-Process -FilePath $resolvedExecutablePath -PassThru
    $processId = $process.Id
    Write-Host "Started PID $processId (process name: $processName)."

    $startupDeadline = (Get-Date).AddSeconds($StartupTimeoutSeconds)
    do {
        Start-Sleep -Milliseconds 200
        $process.Refresh()
        if (
            $process.MainWindowHandle -ne [IntPtr]::Zero -and
            [WindowVisibility]::IsWindowVisible($process.MainWindowHandle)
        ) {
            break
        }
    } while ((Get-Date) -lt $startupDeadline)

    if (
        $process.MainWindowHandle -eq [IntPtr]::Zero -or
        -not [WindowVisibility]::IsWindowVisible($process.MainWindowHandle)
    ) {
        Write-Error "PID $processId did not expose a visible top-level window within $StartupTimeoutSeconds seconds. No process was terminated."
        exit 1
    }

    Start-Sleep -Seconds $WarmupSeconds
    $process.Refresh()
    if (
        $process.HasExited -or
        $process.MainWindowHandle -eq [IntPtr]::Zero -or
        -not [WindowVisibility]::IsWindowVisible($process.MainWindowHandle)
    ) {
        throw "PID $processId lost its window during the $WarmupSeconds-second audio warm-up."
    }

    Write-Host "Starting second executable instance to verify single-instance shutdown: $resolvedExecutablePath"
    $secondProcess = Start-Process -FilePath $resolvedExecutablePath -PassThru
    $secondProcessId = $secondProcess.Id
    Write-Host "Started second PID $secondProcessId (process name: $processName)."

    $secondInstanceDeadline = (Get-Date).AddSeconds($ShutdownTimeoutSeconds)
    do {
        Start-Sleep -Milliseconds 200
        $secondPresence = Test-TargetPidPresent -ProcessId $secondProcessId -ProcessName $processName
        $process.Refresh()
        if (
            $process.HasExited -or
            $process.MainWindowHandle -eq [IntPtr]::Zero -or
            -not [WindowVisibility]::IsWindowVisible($process.MainWindowHandle)
        ) {
            throw "First PID $processId exited or lost its visible window while waiting for second PID $secondProcessId to exit."
        }

        if (-not $secondPresence.InProcessNameEnumeration -and -not $secondPresence.InCimEnumeration) {
            Write-Host "PASS: Second PID $secondProcessId vanished from Get-Process -Name and Win32_Process while first PID $processId remained visible."
            break
        }
    } while ((Get-Date) -lt $secondInstanceDeadline)

    if ($secondPresence.InProcessNameEnumeration -or $secondPresence.InCimEnumeration) {
        Write-Error (
            "FAIL: Second PID $secondProcessId for '$resolvedExecutablePath' remains after single-instance launch. " +
            "Get-Process -Name match: $($secondPresence.InProcessNameEnumeration); " +
            "Win32_Process match: $($secondPresence.InCimEnumeration). First PID $processId was not terminated."
        )
        exit 1
    }

    Write-Host "Window stayed visible through $WarmupSeconds-second audio warm-up. Sending normal CloseMainWindow request to PID $processId."
    $closeRequested = $process.CloseMainWindow()
    if (-not $closeRequested) {
        Write-Error "CloseMainWindow returned false for PID $processId. No process was terminated."
        exit 1
    }

    $shutdownDeadline = (Get-Date).AddSeconds($ShutdownTimeoutSeconds)
    do {
        Start-Sleep -Milliseconds 200
        $presence = Test-TargetPidPresent -ProcessId $processId -ProcessName $processName
        if (-not $presence.InProcessNameEnumeration -and -not $presence.InCimEnumeration) {
            Write-Host "PASS: PID $processId vanished from Get-Process -Name and Win32_Process after normal close."
            exit 0
        }
    } while ((Get-Date) -lt $shutdownDeadline)

    Write-Error (
        "FAIL: PID $processId for '$resolvedExecutablePath' remains after normal close. " +
        "Get-Process -Name match: $($presence.InProcessNameEnumeration); " +
        "Win32_Process match: $($presence.InCimEnumeration). No process was terminated."
    )
    exit 1
}
catch {
    foreach ($startedProcess in @($secondProcess, $process)) {
        if ($null -ne $startedProcess) {
            $startedProcess.Refresh()
            if (-not $startedProcess.HasExited -and $startedProcess.MainWindowHandle -ne [IntPtr]::Zero) {
                [void]$startedProcess.CloseMainWindow()
            }
        }
    }
    Write-Error "Windows shutdown regression test failed: $($_.Exception.Message)"
    exit 1
}
