$ErrorActionPreference = 'Stop'

$root = Split-Path -Parent $PSScriptRoot
$source = Join-Path $root 'sketchup-extension'
$outputDirectory = Join-Path $root 'dist'
$output = Join-Path $outputDirectory 'sketchup-mcp-0.1.0.rbz'
$temporaryZip = Join-Path $outputDirectory 'sketchup-mcp-0.1.0.zip'
$staging = Join-Path $env:TEMP ('sketchup-mcp-package-' + [Guid]::NewGuid().ToString())

New-Item -ItemType Directory -Path $staging -Force | Out-Null
New-Item -ItemType Directory -Path $outputDirectory -Force | Out-Null
try {
    Copy-Item (Join-Path $source 'sketchup_mcp.rb') $staging
    Copy-Item (Join-Path $source 'sketchup_mcp') (Join-Path $staging 'sketchup_mcp') -Recurse
    if (Test-Path $temporaryZip) {
        Remove-Item $temporaryZip -Force
    }
    if (Test-Path $output) {
        Remove-Item $output -Force
    }
    Compress-Archive -Path (Join-Path $staging '*') -DestinationPath $temporaryZip
    Move-Item $temporaryZip $output
    Write-Output $output
}
finally {
    if (Test-Path $staging) {
        Remove-Item $staging -Recurse -Force
    }
}
