# =====================================================================
#  자동 동기화 워커 (작업 스케줄러가 1시간마다 백그라운드로 실행)
#  GitHub -> 로컬: 모든 저장소를 git pull --ff-only (안전, 로컬 변경 보존)
#  setup-workspace.ps1 이 이 파일을 받아 작업으로 등록합니다.
# =====================================================================
param(
    [string]$Root
)

$ErrorActionPreference = "Continue"

# Root 미지정 시 자동 탐지 (setup과 동일 규칙)
if (-not $Root -or -not (Test-Path $Root)) {
    if (Test-Path "T:\TTong_total\new_project") { $Root = "T:\TTong_total\new_project" }
    else { $Root = Join-Path $env:USERPROFILE "TTong_total\new_project" }
}

$logDir = Join-Path $env:LOCALAPPDATA "TTongWorkspace"
New-Item -ItemType Directory -Force -Path $logDir | Out-Null
$log = Join-Path $logDir "sync-pull.log"

function Log($msg) {
    $ts = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    Add-Content -Path $log -Value "[$ts] $msg" -Encoding UTF8
}

if (-not (Test-Path $Root)) { Log "Root 없음: $Root — 종료"; return }
if (-not (Get-Command git -ErrorAction SilentlyContinue)) { Log "git 없음 — 종료"; return }

Log "동기화 시작 ($Root)"
$ok = 0; $skip = 0
Get-ChildItem -Path $Root -Directory | ForEach-Object {
    $repo = $_.FullName
    if (Test-Path (Join-Path $repo ".git")) {
        $out = git -C $repo pull --ff-only 2>&1
        if ($LASTEXITCODE -eq 0) { $ok++ }
        else { $skip++; Log "스킵 $($_.Name): $out" }
    }
}
Log "동기화 끝 — 성공 $ok / 스킵 $skip"

# ---------------------------------------------------------------------
# 추가) Claude Code 작업환경(~/.claude = claude-config) 동기화
#   - 이미 git repo로 연결된 경우에만 안전하게 pull (--ff-only)
#   - 로그인 토큰/세션은 .gitignore로 보호되어 건드리지 않음
#   - 아직 연결 안 된 PC는 1회 수동 부트스트랩 필요
#     (백그라운드 자동 clone은 로그인 꼬임 방지를 위해 일부러 안 함)
# ---------------------------------------------------------------------
$claudeDir = Join-Path $env:USERPROFILE ".claude"
if (Test-Path (Join-Path $claudeDir ".git")) {
    $cout = git -C $claudeDir pull --ff-only 2>&1
    if ($LASTEXITCODE -eq 0) { Log "claude-config(~/.claude) 동기화 OK" }
    else { Log "claude-config 스킵: $cout" }
}
else {
    Log "claude-config 미연결(~/.claude에 .git 없음) — 1회 수동 부트스트랩 필요"
}

# ---------------------------------------------------------------------
# 추가) 산하 공통룰/SSOT 배포 (claude-config의 shared-rules -> 실제 경로)
#   ~/.claude/shared-rules/ 의 파일을 Claude가 자동 로드하는 위치로 복사.
#   비공개 claude-config에 보관하므로 계정/호스트 정보가 공개 노출되지 않음.
#   내용이 같으면 건너뛰어 불필요한 갱신/타임스탬프 변경을 막음.
# ---------------------------------------------------------------------
$shared = Join-Path $env:USERPROFILE ".claude\shared-rules"
if (Test-Path $shared) {
    $ttRoot = Split-Path $Root -Parent     # new_project 의 부모 = TTong_total 루트
    $map = @{
        (Join-Path $shared "PROJECTS_INDEX.md")     = (Join-Path $ttRoot "PROJECTS_INDEX.md")
        (Join-Path $shared "new_project_CLAUDE.md") = (Join-Path $Root "CLAUDE.md")
    }
    foreach ($src in $map.Keys) {
        $dst = $map[$src]
        if (Test-Path $src) {
            $needCopy = $true
            if (Test-Path $dst) {
                $needCopy = (Get-FileHash $src).Hash -ne (Get-FileHash $dst).Hash
            }
            if ($needCopy) {
                New-Item -ItemType Directory -Force -Path (Split-Path $dst -Parent) | Out-Null
                Copy-Item $src $dst -Force
                Log "공통룰 배포: $(Split-Path $src -Leaf) -> $dst"
            }
        }
    }
}

# 로그 비대화 방지: 2000줄 초과 시 최근 1000줄만 유지
try {
    $lines = Get-Content $log -ErrorAction Stop
    if ($lines.Count -gt 2000) { $lines | Select-Object -Last 1000 | Set-Content $log -Encoding UTF8 }
}
catch {}
