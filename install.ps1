<#
.SYNOPSIS
    Install the personal skillpack (.agent + CLAUDE.md + ERRORS.md) into a project.

.DESCRIPTION
    Run this from the ROOT of the target project, or pass -Project.
      .agent     : junction to the central pack (no 42MB duplication; update once, shared everywhere)
      CLAUDE.md  : copied into the project (not overwritten unless -Force)
      ERRORS.md  : created empty from template if the project has none
      .gitignore : adds '.agent/' and 'ERRORS.md' if missing

.PARAMETER Project
    Target project path. Defaults to the current directory.

.PARAMETER Force
    Overwrite CLAUDE.md if the project already has one.

.EXAMPLE
    cd D:\code\my-new-project
    & C:\Users\meth\agent-skillpack\install.ps1

.EXAMPLE
    & C:\Users\meth\agent-skillpack\install.ps1 -Project D:\code\my-new-project -Force
#>
param(
    [string]$Project = (Get-Location).Path,
    [switch]$Force
)

$ErrorActionPreference = "Stop"

# Resolve the pack directory reliably (do not depend solely on $PSScriptRoot;
# some hosts invoke the script without populating it).
$Pack = $PSScriptRoot
if (-not $Pack) { $Pack = Split-Path -Parent $MyInvocation.MyCommand.Path }
if (-not $Pack) { throw "Cannot determine skillpack directory (PSScriptRoot empty)." }
$Pack = $Pack.TrimEnd('\')

$Project = (Resolve-Path $Project).Path.TrimEnd('\')

Write-Host "==> Pack    : $Pack"
Write-Host "==> Project : $Project"
Write-Host ""

# 1) .agent via junction
$agentLink = "$Project\.agent"
$agentSrc  = "$Pack\.agent"
if (Test-Path -LiteralPath $agentLink) {
    Write-Host "[.agent]     exists, skip."
} else {
    New-Item -ItemType Junction -Path $agentLink -Target $agentSrc | Out-Null
    Write-Host "[.agent]     junction -> $agentSrc"
}

# 2) CLAUDE.md (copy, per-project customizable)
$claudeDst = "$Project\CLAUDE.md"
$claudeSrc = "$Pack\CLAUDE.md"
if ((Test-Path -LiteralPath $claudeDst) -and (-not $Force)) {
    Write-Host "[CLAUDE.md]  exists, kept (use -Force to overwrite)."
} else {
    Copy-Item -LiteralPath $claudeSrc -Destination $claudeDst -Force
    Write-Host "[CLAUDE.md]  copied."
}

# 3) ERRORS.md (fresh empty log from template)
$errDst = "$Project\ERRORS.md"
$errSrc = "$Pack\ERRORS.template.md"
if (Test-Path -LiteralPath $errDst) {
    Write-Host "[ERRORS.md]  exists, kept."
} else {
    Copy-Item -LiteralPath $errSrc -Destination $errDst -Force
    Write-Host "[ERRORS.md]  created from template."
}

# 4) .gitignore
$giPath  = "$Project\.gitignore"
$needed  = @(".agent/", "ERRORS.md")
$current = if (Test-Path -LiteralPath $giPath) { Get-Content -LiteralPath $giPath } else { @() }
$toAdd   = $needed | Where-Object { $current -notcontains $_ }
if ($toAdd.Count -gt 0) {
    Add-Content -LiteralPath $giPath -Value "" -Encoding utf8
    Add-Content -LiteralPath $giPath -Value "# Skillpack (local tooling, not committed)" -Encoding utf8
    $toAdd | ForEach-Object { Add-Content -LiteralPath $giPath -Value $_ -Encoding utf8 }
    Write-Host "[.gitignore] added: $($toAdd -join ', ')"
} else {
    Write-Host "[.gitignore] already set, skip."
}

Write-Host ""
Write-Host "DONE. Skillpack installed into the project." -ForegroundColor Green
