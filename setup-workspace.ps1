# =====================================================================
#  형님 공통 작업 환경 자동 세팅 스크립트 (강화판)
#  도구 설치 + 두 계정 전 프로젝트 코드 클론 + 1시간마다 자동 pull
#  실행:  irm https://raw.githubusercontent.com/ttong627/workspace-setup/main/setup-workspace.ps1 | iex
#  - 새 PC: 1번 돌려 도구 설치 -> gh 로그인 안내 -> 다시 1줄 -> 코드 클론+동기화
#  - 재실행 안전(이미 있으면 pull, 없으면 clone). 콘솔 번쩍임 없음(S4U 백그라운드).
# =====================================================================

$ErrorActionPreference = "Continue"

$Accounts = @("ttong627", "ttong0627")          # GitHub 두 계정 (코드 클론 대상)
$TaskName = "TTong-Workspace-Sync"               # 자동 동기화 작업 이름
$ToolsDir = Join-Path $env:LOCALAPPDATA "TTongWorkspace"
$SyncRawUrl = "https://raw.githubusercontent.com/ttong627/workspace-setup/main/sync-pull.ps1"

function Write-Step($msg, $color = "Yellow") { Write-Host "`n>> $msg" -ForegroundColor $color }
function Write-Head($msg) {
    Write-Host "`n================================================" -ForegroundColor Cyan
    Write-Host "   $msg" -ForegroundColor Cyan
    Write-Host "================================================" -ForegroundColor Cyan
}

# PATH 즉시 새로고침 (방금 winget으로 깐 git/gh를 같은 창에서 인식하게)
function Refresh-Path {
    $machine = [System.Environment]::GetEnvironmentVariable("Path", "Machine")
    $user = [System.Environment]::GetEnvironmentVariable("Path", "User")
    $env:Path = "$machine;$user"
}

# 클론 루트 결정: E:\TTong_newproject 있으면 최우선, 다음 T 드라이브(허브), 없으면 사용자 폴더
function Resolve-Root {
    if (Test-Path "E:\TTong_newproject") { return "E:\TTong_newproject" }
    if (Test-Path "T:\TTong_total") { return "T:\TTong_total\new_project" }
    return (Join-Path $env:USERPROFILE "TTong_total\new_project")
}

Write-Head "형님 공통 작업 환경 자동 세팅 (강화판)"

# ---------------------------------------------------------------------
# 1단계) winget 확인 + 도구 설치
# ---------------------------------------------------------------------
if (-not (Get-Command winget -ErrorAction SilentlyContinue)) {
    Write-Host "[오류] winget이 없습니다. Microsoft Store에서 '앱 설치 관리자(App Installer)'를 먼저 설치하세요." -ForegroundColor Red
    return
}

$apps = @(
    @{ id = "Git.Git";                    name = "Git (버전관리)" },
    @{ id = "OpenJS.NodeJS.LTS";          name = "Node.js LTS (코딩)" },
    @{ id = "Microsoft.VisualStudioCode"; name = "VS Code (코드편집기)"; scope = "user" },
    @{ id = "GitHub.cli";                 name = "GitHub CLI (동기화)" },
    @{ id = "Python.Python.3.12";         name = "Python 3.12 (코딩)";   scope = "user" },
    @{ id = "ByteDance.CapCut";           name = "CapCut (영상편집)" },
    @{ id = "Microsoft.Office";           name = "MS Office (문서)" }
)

Write-Head "1단계 / 3 : 도구 설치"
foreach ($app in $apps) {
    Write-Step "$($app.name) 설치 중..."
    $wargs = @("install", "-e", "--id", $app.id, "--accept-package-agreements", "--accept-source-agreements")
    if ($app.scope) { $wargs += @("--scope", $app.scope) }
    winget @wargs
}
Refresh-Path

# ---------------------------------------------------------------------
# 2단계) 코드 클론 (gh 로그인 필요)
# ---------------------------------------------------------------------
Write-Head "2단계 / 3 : 프로젝트 코드 클론"

if (-not (Get-Command gh -ErrorAction SilentlyContinue)) {
    Write-Host "[안내] 새 터미널을 열고 이 명령을 다시 실행하세요. (방금 깐 gh가 인식되어야 합니다)" -ForegroundColor Yellow
    return
}

# gh 로그인 여부 확인 (안 돼 있으면 안내 후 종료 -> 로그인 뒤 다시 1줄 실행)
gh auth status 2>$null | Out-Null
if ($LASTEXITCODE -ne 0) {
    Write-Host "`n[!] GitHub 로그인이 필요합니다. 아래를 먼저 실행하세요:" -ForegroundColor Red
    Write-Host "    gh auth login --web      (ttong627 로그인)" -ForegroundColor White
    Write-Host "    gh auth login --web      (ttong0627 로그인)" -ForegroundColor White
    Write-Host "  로그인 후 위 한 줄 명령(irm ... | iex)을 다시 실행하면 코드 클론이 진행됩니다." -ForegroundColor Yellow
    return
}

$Root = Resolve-Root
New-Item -ItemType Directory -Force -Path $Root | Out-Null
Write-Host "클론 위치: $Root" -ForegroundColor Cyan

# Windows 긴 경로 대비 (이 저장소들 필수 설정)
git config --global core.longpaths true 2>$null

$cloned = 0; $pulled = 0; $failed = @()
foreach ($acct in $Accounts) {
    Write-Step "[$acct] 저장소 목록 가져오는 중..."
    gh auth switch --user $acct 2>$null | Out-Null
    $repos = gh repo list $acct --limit 300 --json nameWithOwner -q ".[].nameWithOwner" 2>$null
    if (-not $repos) {
        Write-Host "  (건너뜀) $acct 계정에 접근 불가 — 로그인 여부를 확인하세요." -ForegroundColor DarkYellow
        continue
    }
    foreach ($full in $repos) {
        $name = ($full -split "/")[-1]
        $dest = Join-Path $Root $name
        if (Test-Path (Join-Path $dest ".git")) {
            git -C $dest pull --ff-only 2>$null | Out-Null
            if ($LASTEXITCODE -eq 0) { $pulled++ } else { $failed += $name }
            Write-Host "  ~ $name (업데이트)" -ForegroundColor DarkGray
        }
        else {
            gh repo clone $full $dest 2>$null | Out-Null
            if ($LASTEXITCODE -eq 0) { $cloned++; Write-Host "  + $name (신규)" -ForegroundColor Green }
            else { $failed += $name; Write-Host "  x $name (실패)" -ForegroundColor Red }
        }
    }
}
Write-Host "`n클론 $cloned개 / 업데이트 $pulled개 완료." -ForegroundColor Green
if ($failed.Count -gt 0) { Write-Host "실패/스킵: $($failed -join ', ')" -ForegroundColor DarkYellow }

# ---------------------------------------------------------------------
# 3단계) 자동 동기화 작업 등록 (1시간마다 + 로그인 시, 창 없이)
# ---------------------------------------------------------------------
Write-Head "3단계 / 3 : 자동 동기화 등록 (1시간마다 pull)"

New-Item -ItemType Directory -Force -Path $ToolsDir | Out-Null
$syncScript = Join-Path $ToolsDir "sync-pull.ps1"
$launcher = Join-Path $ToolsDir "sync-launcher.vbs"
try {
    Invoke-RestMethod -Uri $SyncRawUrl -OutFile $syncScript -ErrorAction Stop
    Write-Host "동기화 스크립트 저장: $syncScript" -ForegroundColor Cyan

    # 콘솔 창 안 뜨게 하는 VBS 런처 (Run 의 두 번째 인자 0 = 완전 숨김, 깜빡임 없음)
    $vbs = "Set sh = CreateObject(""WScript.Shell"")`r`n" +
           "sh.Run ""powershell.exe -NoProfile -ExecutionPolicy Bypass -File """"$syncScript"""" -Root """"$Root"""""", 0, False"
    Set-Content -Path $launcher -Value $vbs -Encoding Unicode

    # schtasks.exe 로 등록 (관리자 권한 불필요, 현재 사용자 작업)
    $tr = "wscript.exe `"$launcher`""
    schtasks /Create /TN $TaskName /TR $tr /SC HOURLY /F /RL LIMITED 2>&1 | Out-Null
    $rcHourly = $LASTEXITCODE
    schtasks /Create /TN "$TaskName-Logon" /TR $tr /SC ONLOGON /F /RL LIMITED 2>&1 | Out-Null
    $rcLogon = $LASTEXITCODE

    if ($rcHourly -eq 0) { Write-Host "자동 동기화 '$TaskName' 등록 완료 (1시간마다, 콘솔 안 뜸)." -ForegroundColor Green }
    else { Write-Host "[경고] 시간별 작업 등록 실패 (code $rcHourly)" -ForegroundColor DarkYellow }
    if ($rcLogon -eq 0) { Write-Host "로그인 시 동기화 '$TaskName-Logon' 등록 완료." -ForegroundColor Green }
}
catch {
    Write-Host "[경고] 자동 동기화 등록 실패: $($_.Exception.Message)" -ForegroundColor DarkYellow
    Write-Host "  나중에 이 한 줄을 다시 실행하면 재시도됩니다." -ForegroundColor DarkYellow
}

# ---------------------------------------------------------------------
# 마무리 안내
# ---------------------------------------------------------------------
Write-Head "세팅 완료! 남은 수동 작업"
Write-Host "1. DaVinci Resolve : 공식 사이트에서 직접 다운로드 (자동설치 불가)" -ForegroundColor White
Write-Host "2. MS Office       : 워드 실행 후 Microsoft 계정 로그인" -ForegroundColor White
Write-Host "3. .env(비밀키)    : GitHub엔 없음 -> 기흥 PC에서 해당 프로젝트의 .env만 따로 복사" -ForegroundColor White
Write-Host "`n[참고] 코드 위치: $Root  /  자동 pull: 1시간마다 백그라운드" -ForegroundColor Cyan
Write-Host "[참고] 작업 후엔 평소대로 git push -> 기흥 허브 PC가 1시간 내 자동 수집" -ForegroundColor Cyan
Start-Process "https://www.blackmagicdesign.com/products/davinciresolve"
Write-Host "`n끝! 새 터미널을 열면 모든 명령어가 인식됩니다." -ForegroundColor Green
