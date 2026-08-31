[CmdletBinding()]
param()

$ErrorActionPreference = "Continue"
$repoRoot = Split-Path -Parent $PSScriptRoot
$problemDirs = Get-ChildItem -LiteralPath (Join-Path $repoRoot "problems") -Directory | Sort-Object Name
$failed = 0
$ran = 0

foreach ($dir in $problemDirs) {
    $rtl = @(Get-ChildItem -LiteralPath (Join-Path $dir.FullName "rtl") -Filter *.sv -File -ErrorAction SilentlyContinue)
    $tb = @(Get-ChildItem -LiteralPath (Join-Path $dir.FullName "tb") -Filter *.sv -File -ErrorAction SilentlyContinue)
    if ($rtl.Count -eq 0 -or $tb.Count -eq 0) {
        Write-Host "SKIP $($dir.Name): no complete user RTL+TB pair"
        continue
    }

    $ran++
    & (Join-Path $PSScriptRoot "lint.ps1") -Problem $dir.Name
    if ($LASTEXITCODE -ne 0) { $failed++; continue }
    & (Join-Path $PSScriptRoot "sim.ps1") -Problem $dir.Name
    if ($LASTEXITCODE -ne 0) { $failed++ }
}

Write-Host "Regression summary: ran=$ran failed=$failed total=$($problemDirs.Count)"
if ($failed -ne 0) { exit 1 }
exit 0
