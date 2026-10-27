<#
.SYNOPSIS
    Cài bộ skill cá nhân (.agent + CLAUDE.md + ERRORS.md) vào một project.

.DESCRIPTION
    Chạy script này từ THƯ MỤC GỐC của project cần cài, hoặc truyền -Project.
    - .agent  : tạo junction trỏ về kho trung tâm (không nhân bản 42MB, update 1 chỗ xài chung).
    - CLAUDE.md : copy vào project (không ghi đè nếu đã có, trừ khi dùng -Force).
    - ERRORS.md : tạo mới rỗng từ template nếu project chưa có.
    - .gitignore : tự thêm '.agent/' và 'ERRORS.md' nếu còn thiếu.

.PARAMETER Project
    Đường dẫn project đích. Mặc định là thư mục hiện tại.

.PARAMETER Force
    Ghi đè CLAUDE.md nếu project đã có sẵn.

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
$Pack = $PSScriptRoot
$Project = (Resolve-Path $Project).Path

Write-Host "==> Kho skillpack : $Pack"
Write-Host "==> Project đích  : $Project"
Write-Host ""

# 1) .agent qua junction
$agentLink = Join-Path $Project ".agent"
$agentSrc  = Join-Path $Pack ".agent"
if (Test-Path $agentLink) {
    Write-Host "[.agent]     đã tồn tại, bỏ qua."
} else {
    New-Item -ItemType Junction -Path $agentLink -Target $agentSrc | Out-Null
    Write-Host "[.agent]     tạo junction -> $agentSrc"
}

# 2) CLAUDE.md (copy, customizable per-project)
$claudeDst = Join-Path $Project "CLAUDE.md"
$claudeSrc = Join-Path $Pack "CLAUDE.md"
if ((Test-Path $claudeDst) -and -not $Force) {
    Write-Host "[CLAUDE.md]  đã tồn tại, giữ nguyên (dùng -Force để ghi đè)."
} else {
    Copy-Item $claudeSrc $claudeDst -Force
    Write-Host "[CLAUDE.md]  copy xong."
}

# 3) ERRORS.md (tạo rỗng từ template)
$errDst = Join-Path $Project "ERRORS.md"
$errSrc = Join-Path $Pack "ERRORS.template.md"
if (Test-Path $errDst) {
    Write-Host "[ERRORS.md]  đã tồn tại, giữ nguyên."
} else {
    Copy-Item $errSrc $errDst -Force
    Write-Host "[ERRORS.md]  tạo mới từ template."
}

# 4) .gitignore
$giPath = Join-Path $Project ".gitignore"
$needed = @(".agent/", "ERRORS.md")
$current = if (Test-Path $giPath) { Get-Content $giPath } else { @() }
$toAdd = $needed | Where-Object { $current -notcontains $_ }
if ($toAdd.Count -gt 0) {
    Add-Content -Path $giPath -Value "`n# Skillpack (local tooling, không commit)" -Encoding utf8
    $toAdd | ForEach-Object { Add-Content -Path $giPath -Value $_ -Encoding utf8 }
    Write-Host "[.gitignore] thêm: $($toAdd -join ', ')"
} else {
    Write-Host "[.gitignore] đã đủ, bỏ qua."
}

Write-Host ""
Write-Host "XONG. Project đã gắn skillpack." -ForegroundColor Green
