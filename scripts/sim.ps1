[CmdletBinding()]
param(
    [string]$Problem = "01_async_fifo",
    [string]$Top = "tb"
)

$ErrorActionPreference = "Stop"
$repoRoot = Split-Path -Parent $PSScriptRoot
$problemRoot = Join-Path $repoRoot ("problems\" + $Problem)
if (-not (Test-Path -LiteralPath $problemRoot)) {
    throw "Problem directory not found: $problemRoot"
}

$rtl = @(Get-ChildItem -LiteralPath (Join-Path $problemRoot "rtl") -Filter *.sv -File -ErrorAction SilentlyContinue)
$tb = @(Get-ChildItem -LiteralPath (Join-Path $problemRoot "tb") -Filter *.sv -File -ErrorAction SilentlyContinue)
if ($rtl.Count -eq 0 -or $tb.Count -eq 0) {
    Write-Host "SKIP sim: $Problem needs at least one user RTL .sv and one user TB .sv"
    exit 0
}

$iverilog = Get-Command iverilog -ErrorAction SilentlyContinue
$vvp = Get-Command vvp -ErrorAction SilentlyContinue
if (-not $iverilog -and (Test-Path -LiteralPath "D:\iverilog\bin\iverilog.exe")) {
    $iverilog = Get-Item -LiteralPath "D:\iverilog\bin\iverilog.exe"
}
if (-not $vvp -and (Test-Path -LiteralPath "D:\iverilog\bin\vvp.exe")) {
    $vvp = Get-Item -LiteralPath "D:\iverilog\bin\vvp.exe"
}
if (-not $iverilog -or -not $vvp) {
    Write-Error "BLOCKED sim: Icarus/VVP not found."
    exit 3
}

    $iverilogPath = if ($iverilog.Path) { $iverilog.Path } else { $iverilog.FullName }
    $vvpPath = if ($vvp.Path) { $vvp.Path } else { $vvp.FullName }
    $probe = & $iverilogPath -g2012 -V 2>&1
if ($LASTEXITCODE -ne 0) {
    Write-Error "BLOCKED sim: installed Icarus does not support -g2012. See docs/toolchain.md; do not treat this as a test failure or PASS."
    exit 3
}

$buildDir = Join-Path $repoRoot ("work\sim\" + $Problem)
New-Item -ItemType Directory -Force -Path $buildDir | Out-Null
$out = Join-Path $buildDir "sim.vvp"
$files = @($rtl.FullName + $tb.FullName)
    & $iverilogPath -g2012 -Wall -s $Top -o $out $files
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
    & $vvpPath $out
exit $LASTEXITCODE
