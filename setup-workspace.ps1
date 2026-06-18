# =====================================================================
#  형님 공통 작업 환경 자동 세팅 스크립트
#  어느 PC에서든 이 스크립트 하나로 화성비봉과 동일한 환경 구축
#  실행:  irm https://raw.githubusercontent.com/ttong627/workspace-setup/main/setup-workspace.ps1 | iex
# =====================================================================

$ErrorActionPreference = "Continue"

Write-Host "================================================" -ForegroundColor Cyan
Write-Host "   형님 공통 작업 환경 자동 세팅 시작" -ForegroundColor Cyan
Write-Host "================================================" -ForegroundColor Cyan

# 1) winget 존재 확인
if (-not (Get-Command winget -ErrorAction SilentlyContinue)) {
    Write-Host "[오류] winget이 없습니다. Microsoft Store에서 '앱 설치 관리자(App Installer)'를 먼저 설치하세요." -ForegroundColor Red
    return
}

# 2) 설치 목록 (순차 설치 - 동시 설치 충돌 방지)
$apps = @(
    @{ id = "Git.Git";                    name = "Git (버전관리)" },
    @{ id = "OpenJS.NodeJS.LTS";          name = "Node.js LTS (코딩)" },
    @{ id = "Microsoft.VisualStudioCode"; name = "VS Code (코드편집기)"; scope = "user" },
    @{ id = "GitHub.cli";                 name = "GitHub CLI (동기화)" },
    @{ id = "Python.Python.3.12";         name = "Python 3.12 (코딩)";   scope = "user" },
    @{ id = "ByteDance.CapCut";           name = "CapCut (영상편집)" },
    @{ id = "Microsoft.Office";           name = "MS Office (문서)" }
)

foreach ($app in $apps) {
    Write-Host "`n>> $($app.name) 설치 중..." -ForegroundColor Yellow
    $wargs = @("install","-e","--id",$app.id,"--accept-package-agreements","--accept-source-agreements")
    if ($app.scope) { $wargs += @("--scope",$app.scope) }
    winget @wargs
}

# 3) 마무리 안내
Write-Host "`n================================================" -ForegroundColor Green
Write-Host "   기본 설치 완료! 남은 수동 작업 3가지" -ForegroundColor Green
Write-Host "================================================" -ForegroundColor Green
Write-Host "1. GitHub 로그인 :  gh auth login --web   (ttong627 / ttong0627)" -ForegroundColor White
Write-Host "2. DaVinci Resolve :  공식 사이트에서 직접 다운로드 (자동설치 불가)" -ForegroundColor White
Write-Host "3. MS Office :  워드 실행 후 Microsoft 계정 로그인" -ForegroundColor White
Write-Host "`nDaVinci 다운로드 페이지를 엽니다..." -ForegroundColor Cyan

Start-Process "https://www.blackmagicdesign.com/products/davinciresolve"

Write-Host "`n세팅 끝! 새 터미널을 열면 모든 명령어가 인식됩니다." -ForegroundColor Green
