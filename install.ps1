<#
.SYNOPSIS
    Install the agent skillpack (.agent + CLAUDE.md) into a project.
    Works from a local clone OR straight from the internet (irm | iex).

.DESCRIPTION
    Remote one-liner (run from the ROOT of the target project):
      irm https://raw.githubusercontent.com/methanoldev/agent-skillpack/main/install.ps1 | iex

    With parameters when piped:
      iex "& { $(irm https://raw.githubusercontent.com/methanoldev/agent-skillpack/main/install.ps1) } -Force"
      iex "& { $(irm https://raw.githubusercontent.com/methanoldev/agent-skillpack/main/install.ps1) } -Project D:\code\app"
      iex "& { $(irm https://raw.githubusercontent.com/methanoldev/agent-skillpack/main/install.ps1) } -Update"

    What it does:
      1. Ensures the pack exists in a central dir ($env:USERPROFILE\.agent-skillpack):
         clone on first run, `git pull --ff-only` afterwards.
      2. .agent    : junction from the project to the central pack (no 42MB duplication;
                     update once, every project sees it).
      3. CLAUDE.md : copied into the project (kept unless -Force).
      4. .gitignore: adds '.agent/' and 'ERRORS.md' if missing.

    If this script is executed from a local clone that contains .agent, that clone is
    used as the pack directly (no network).

.PARAMETER Project
    Target project path. Defaults to the current directory.
    Env override: SKILLPACK_PROJECT.

.PARAMETER Force
    Overwrite CLAUDE.md, and re-create the .agent junction if it already exists.
    Env override: SKILLPACK_FORCE=1.

.PARAMETER Update
    Only update the central pack (git pull) and exit. No project changes.

.PARAMETER Repo
    Git URL of the skillpack. Env override: SKILLPACK_REPO.

.PARAMETER PackDir
    Central directory where the pack is cloned. Env override: SKILLPACK_DIR.
#>
param(
    [string]$Project = $(if ($env:SKILLPACK_PROJECT) { $env:SKILLPACK_PROJECT } else { (Get-Location).Path }),
    [switch]$Force   = $($env:SKILLPACK_FORCE -eq "1"),
    [switch]$Update,
    [string]$Repo    = $(if ($env:SKILLPACK_REPO) { $env:SKILLPACK_REPO } else { "https://github.com/methanoldev/agent-skillpack.git" }),
    [string]$PackDir = $(if ($env:SKILLPACK_DIR)  { $env:SKILLPACK_DIR }  else { Join-Path $env:USERPROFILE ".agent-skillpack" })
)

$ErrorActionPreference = "Stop"

function Write-Step([string]$Tag, [string]$Msg) {
    Write-Host ("[{0,-11}] {1}" -f $Tag, $Msg)
}

# ---------------------------------------------------------------------------
# 0) Resolve the pack directory
#    Local mode : script lives inside a clone that has .agent  -> use it.
#    Remote mode: script came via irm|iex (no path)            -> use $PackDir.
# ---------------------------------------------------------------------------
$scriptDir = $PSScriptRoot
if (-not $scriptDir -and $MyInvocation.MyCommand.Path) {
    $scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
}

$Pack = $null
if ($scriptDir -and (Test-Path -LiteralPath (Join-Path $scriptDir ".agent"))) {
    $Pack = $scriptDir.TrimEnd('\')
    $mode = "local"
} else {
    $Pack = $PackDir.TrimEnd('\')
    $mode = "remote"
}

Write-Host "==> Mode    : $mode"
Write-Host "==> Pack    : $Pack"

# ---------------------------------------------------------------------------
# 1) Make sure the pack exists and is fresh (remote mode / -Update)
# ---------------------------------------------------------------------------
if ($mode -eq "remote" -or $Update) {
    if (-not (Get-Command git -ErrorAction SilentlyContinue)) {
        throw "git is required but was not found in PATH. Install Git for Windows first."
    }

    if (Test-Path -LiteralPath (Join-Path $Pack ".git")) {
        Write-Step "pack" "updating ($Repo) ..."
        $out = & git -C $Pack pull --ff-only 2>&1
        if ($LASTEXITCODE -ne 0) {
            Write-Step "pack" "WARN: git pull failed, using the existing copy."
            $out | ForEach-Object { Write-Host "    $_" }
        } else {
            Write-Step "pack" ($out | Select-Object -Last 1)
        }
    } elseif (Test-Path -LiteralPath $Pack) {
        throw "$Pack exists but is not a git clone. Remove it or set -PackDir elsewhere."
    } else {
        Write-Step "pack" "cloning $Repo ..."
        & git clone --depth 1 --quiet $Repo $Pack
        if ($LASTEXITCODE -ne 0) { throw "git clone failed." }
        Write-Step "pack" "cloned."
    }
}

if ($Update) {
    Write-Host ""
    Write-Host "DONE. Pack updated. Projects linked via junction already see the changes." -ForegroundColor Green
    return
}

if (-not (Test-Path -LiteralPath (Join-Path $Pack ".agent"))) {
    throw "Pack at $Pack has no .agent directory. Corrupted clone?"
}

# ---------------------------------------------------------------------------
# 2) Resolve the target project
# ---------------------------------------------------------------------------
$Project = (Resolve-Path -LiteralPath $Project).Path.TrimEnd('\')
Write-Host "==> Project : $Project"
Write-Host ""

# ---------------------------------------------------------------------------
# 3) .agent via junction
# ---------------------------------------------------------------------------
$agentLink = Join-Path $Project ".agent"
$agentSrc  = Join-Path $Pack    ".agent"

if (Test-Path -LiteralPath $agentLink) {
    $item = Get-Item -LiteralPath $agentLink -Force
    $isLink = ($item.Attributes -band [IO.FileAttributes]::ReparsePoint) -ne 0
    if ($Force -and $isLink) {
        # Deleting a junction removes only the link, never the target contents.
        [IO.Directory]::Delete($agentLink)
        New-Item -ItemType Junction -Path $agentLink -Target $agentSrc | Out-Null
        Write-Step ".agent" "junction re-created -> $agentSrc"
    } elseif ($isLink) {
        Write-Step ".agent" "junction exists -> $($item.Target). Use -Force to re-point."
    } else {
        Write-Step ".agent" "real directory exists, left untouched."
    }
} else {
    New-Item -ItemType Junction -Path $agentLink -Target $agentSrc | Out-Null
    Write-Step ".agent" "junction -> $agentSrc"
}

# ---------------------------------------------------------------------------
# 4) CLAUDE.md (copy, per-project customizable)
# ---------------------------------------------------------------------------
$claudeDst = Join-Path $Project "CLAUDE.md"
$claudeSrc = Join-Path $Pack    "CLAUDE.md"
if ((Test-Path -LiteralPath $claudeDst) -and (-not $Force)) {
    Write-Step "CLAUDE.md" "exists, kept (use -Force to overwrite)."
} else {
    Copy-Item -LiteralPath $claudeSrc -Destination $claudeDst -Force
    Write-Step "CLAUDE.md" "copied."
}

# ---------------------------------------------------------------------------
# 5) .gitignore
# ---------------------------------------------------------------------------
$giPath  = Join-Path $Project ".gitignore"
$needed  = @(".agent/", "ERRORS.md")
$current = if (Test-Path -LiteralPath $giPath) { Get-Content -LiteralPath $giPath } else { @() }
$toAdd   = @($needed | Where-Object { $current -notcontains $_ })
if ($toAdd.Count -gt 0) {
    Add-Content -LiteralPath $giPath -Value "" -Encoding utf8
    Add-Content -LiteralPath $giPath -Value "# Skillpack (local tooling, not committed)" -Encoding utf8
    $toAdd | ForEach-Object { Add-Content -LiteralPath $giPath -Value $_ -Encoding utf8 }
    Write-Step ".gitignore" "added: $($toAdd -join ', ')"
} else {
    Write-Step ".gitignore" "already set, skip."
}

Write-Host ""
Write-Host "DONE. Skillpack installed into the project." -ForegroundColor Green
