[CmdletBinding()]
param(
    [string]$Problem = "01_async_fifo"
)

$ErrorActionPreference = "Stop"
$repoRoot = Split-Path -Parent $PSScriptRoot
$problemRoot = Join-Path $repoRoot ("problems\" + $Problem)
if (-not (Test-Path -LiteralPath $problemRoot)) {
    throw "Problem directory not found: $problemRoot"
}

$sources = @(
    Get-ChildItem -LiteralPath (Join-Path $problemRoot "rtl") -Filter *.sv -File -ErrorAction SilentlyContinue
    Get-ChildItem -LiteralPath (Join-Path $problemRoot "tb") -Filter *.sv -File -ErrorAction SilentlyContinue
)
if ($sources.Count -eq 0) {
    Write-Host "SKIP lint: no user-authored .sv files in $Problem"
    exit 0
}

$verible = Get-Command verible-verilog-lint -ErrorAction SilentlyContinue
if (-not $verible) {
    Write-Error "BLOCKED lint: verible-verilog-lint was not found. No installation is performed by this script."
    exit 3
}

& $verible.Source --rules_config_search $sources.FullName
exit $LASTEXITCODE
