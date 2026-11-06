[CmdletBinding()]
param(
    [Parameter(Mandatory)]
    [string]$BundlePath
)

$ErrorActionPreference = 'Stop'
if (-not (Test-Path -LiteralPath $BundlePath -PathType Container)) {
    throw "Windows release folder missing: $BundlePath"
}

$dlls = @('msvcp140.dll', 'vcruntime140.dll', 'vcruntime140_1.dll')
$vswhere = Join-Path ${env:ProgramFiles(x86)} 'Microsoft Visual Studio\Installer\vswhere.exe'
if (-not (Test-Path -LiteralPath $vswhere -PathType Leaf)) {
    throw 'Visual Studio C++ redist files not found (vswhere.exe is missing).'
}
$vs = & $vswhere -latest -products '*' -requires Microsoft.VisualStudio.Component.VC.Tools.x86.x64 -property installationPath
if ($LASTEXITCODE -ne 0 -or [string]::IsNullOrWhiteSpace($vs)) {
    throw 'Visual Studio with the Desktop development with C++ workload is required.'
}
$redistRoot = Join-Path $vs 'VC\Redist\MSVC'
$crt = $null
foreach ($version in @(Get-ChildItem -LiteralPath $redistRoot -Directory | Sort-Object Name -Descending)) {
    foreach ($candidate in @(Get-ChildItem -LiteralPath (Join-Path $version.FullName 'x64') -Directory -ErrorAction SilentlyContinue | Where-Object Name -Like 'Microsoft.VC*.CRT')) {
        if (@($dlls | Where-Object { -not (Test-Path -LiteralPath (Join-Path $candidate.FullName $_) -PathType Leaf) }).Count -eq 0) {
            $crt = $candidate.FullName
            break
        }
    }
    if ($crt) { break }
}
if (-not $crt) {
    throw 'Could not find x64 Microsoft Visual C++ app-local runtime DLLs in Visual Studio.'
}

foreach ($dll in $dlls) {
    Copy-Item -LiteralPath (Join-Path $crt $dll) -Destination (Join-Path $BundlePath $dll) -Force
}
