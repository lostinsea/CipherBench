[CmdletBinding()]
param(
    [string]$CompilerPath
)

$ErrorActionPreference = 'Stop'
$repo = Split-Path -Parent $PSScriptRoot
$bundle = Join-Path $repo 'build\windows\x64\runner\Release'
$output = Join-Path $repo 'build\windows-installer\CipherBench-2.0.0-Windows-x64-Setup.exe'

foreach ($required in @('cipherbench.exe', 'flutter_windows.dll', 'data\app.so', 'data\flutter_assets\NOTICES.Z')) {
    if (-not (Test-Path -LiteralPath (Join-Path $bundle $required) -PathType Leaf)) {
        throw "Missing $required. Build the Windows Release first with flutter build windows --release."
    }
}

if ([string]::IsNullOrWhiteSpace($CompilerPath)) {
    $command = Get-Command ISCC.exe -ErrorAction SilentlyContinue
    if ($command) {
        $CompilerPath = $command.Source
    } else {
        foreach ($candidate in @(
            (Join-Path ${env:ProgramFiles(x86)} 'Inno Setup 6\ISCC.exe'),
            (Join-Path $env:ProgramFiles 'Inno Setup 6\ISCC.exe'),
            (Join-Path $env:LOCALAPPDATA 'Programs\Inno Setup 6\ISCC.exe')
        )) {
            if (Test-Path -LiteralPath $candidate -PathType Leaf) {
                $CompilerPath = $candidate
                break
            }
        }
    }
}
if ([string]::IsNullOrWhiteSpace($CompilerPath) -or -not (Test-Path -LiteralPath $CompilerPath -PathType Leaf)) {
    throw 'Install Inno Setup 6 from jrsoftware.org, then rerun this script.'
}

& (Join-Path $PSScriptRoot 'stage-runtime.ps1') -BundlePath $bundle

& $CompilerPath (Join-Path $PSScriptRoot 'CipherBench.iss')
if ($LASTEXITCODE -ne 0) {
    throw "Inno Setup compilation failed with exit code $LASTEXITCODE."
}
if (-not (Test-Path -LiteralPath $output -PathType Leaf)) {
    throw "Installer output missing: $output"
}
Write-Output "Installer ready: $output"
