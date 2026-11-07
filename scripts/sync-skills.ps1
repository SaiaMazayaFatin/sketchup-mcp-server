$ErrorActionPreference = 'Stop'

$root = Split-Path -Parent $PSScriptRoot
$source = Join-Path $root 'skills'
$targets = @(
    (Join-Path $root '.github\skills'),
    (Join-Path $root '.claude\skills'),
    (Join-Path $root '.agents\skills')
)

foreach ($target in $targets) {
    New-Item -ItemType Directory -Path $target -Force | Out-Null
    Get-ChildItem -LiteralPath $source -Directory | ForEach-Object {
        $destination = Join-Path $target $_.Name
        if (Test-Path $destination) {
            Remove-Item $destination -Recurse -Force
        }
        Copy-Item $_.FullName $destination -Recurse
    }
}

Write-Output 'Synchronized Skills to .github, .claude, and .agents'
