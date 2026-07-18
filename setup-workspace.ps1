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
    @{ id = "Ollama.Ollama";              name = "Ollama (로컬 LLM 엔진)" },
    @{ id = "Obsidian.Obsidian";          name = "Obsidian (지식베이스)" },
    @{ id = "Google.CloudSDK";            name = "Google Cloud SDK (버킷 동기화)" },
    @{ id = "ByteDance.CapCut";           name = "CapCut (영상편집)" },
    @{ id = "Microsoft.Office";           name = "MS Office (문서)" }
)

Write-Head "1단계 / 5 : 도구 설치"
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
Write-Head "2단계 / 5 : 프로젝트 코드 클론"

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
        # Gemma4는 5단계에서 D:\Gemma4로 전용 클론(MCP 서버 경로 고정) -> 여기선 건너뜀
        if ($name -eq "Gemma4") { continue }
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
Write-Head "3단계 / 5 : 자동 동기화 등록 (1시간마다 pull)"

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
# 4단계) Ollama 로컬 LLM + gemma4 모델 (집 PC와 동일 재현)
# ---------------------------------------------------------------------
Write-Head "4단계 / 5 : Ollama + gemma4 모델 (9.6GB)"

Refresh-Path
if (Get-Command ollama -ErrorAction SilentlyContinue) {
    # gemma4 는 registry.ollama.ai/library 공식 모델 -> pull 로 집 PC와 100% 동일 재현
    $have = (ollama list 2>$null | Select-String -Pattern "^gemma4")
    if ($have) {
        Write-Host "  gemma4 모델 이미 있음 (건너뜀)." -ForegroundColor DarkGray
    }
    else {
        Write-Step "gemma4 모델 내려받는 중... (9.6GB, 회선에 따라 수 분~수십 분)"
        ollama pull gemma4
        if ($LASTEXITCODE -eq 0) { Write-Host "  gemma4 모델 준비 완료." -ForegroundColor Green }
        else { Write-Host "  [경고] gemma4 pull 실패 — 나중에 'ollama pull gemma4' 수동 실행." -ForegroundColor DarkYellow }
    }
}
else {
    Write-Host "[안내] ollama 명령을 아직 못 찾음(방금 설치됨). 새 터미널에서 이 한 줄을 다시 실행하면 모델까지 받습니다." -ForegroundColor Yellow
}

# ---------------------------------------------------------------------
# 5단계) Gemma4 두뇌 + MCP/프록시 서버 (D:\Gemma4 고정)
#   - private repo(ttong0627/Gemma4) = 서버코드 + 지식베이스(나무위키/학습) 두뇌
#   - .venv 생성 + 의존성 설치 + 로그인 시 프록시 자동기동 등록
# ---------------------------------------------------------------------
Write-Head "5단계 / 5 : Gemma4 두뇌 + 서버"

# MCP 서버가 D:\Gemma4 를 하드코딩 -> D 드라이브 있으면 D:\Gemma4, 없으면 사용자 폴더
$GemmaDir = if (Test-Path "D:\") { "D:\Gemma4" } else { Join-Path $env:USERPROFILE "Gemma4" }
if ($GemmaDir -ne "D:\Gemma4") {
    Write-Host "[주의] 이 PC엔 D: 드라이브가 없어 $GemmaDir 에 설치합니다." -ForegroundColor DarkYellow
    Write-Host "       MCP 서버 경로(D:\Gemma4)와 다르면 config 조정이 필요할 수 있습니다." -ForegroundColor DarkYellow
}

try {
    gh auth switch --user ttong0627 2>$null | Out-Null
    if (Test-Path (Join-Path $GemmaDir ".git")) {
        Write-Step "Gemma4 두뇌 업데이트(pull)..."
        git -C $GemmaDir pull --ff-only 2>$null | Out-Null
    }
    else {
        Write-Step "Gemma4 두뇌 클론(신규)..."
        gh repo clone ttong0627/Gemma4 $GemmaDir 2>$null | Out-Null
    }

    if (Test-Path (Join-Path $GemmaDir "requirements_server.txt")) {
        # 파이썬 가상환경 + 서버 의존성
        $venvPy = Join-Path $GemmaDir ".venv\Scripts\python.exe"
        if (-not (Test-Path $venvPy)) {
            Write-Step "파이썬 가상환경(.venv) 생성..."
            python -m venv (Join-Path $GemmaDir ".venv") 2>$null
        }
        if (Test-Path $venvPy) {
            Write-Step "서버 의존성 설치(fastapi/uvicorn/mcp 등)..."
            & $venvPy -m pip install --upgrade pip 2>$null | Out-Null
            & $venvPy -m pip install -r (Join-Path $GemmaDir "requirements_server.txt") 2>$null | Out-Null
            Write-Host "  의존성 설치 완료." -ForegroundColor Green
        }

        # 로그인 시 Ollama 프록시(:8765) 자동기동 등록 (경로 $GemmaDir 반영)
        $pyw = Join-Path $GemmaDir ".venv\Scripts\pythonw.exe"
        $srv = Join-Path $GemmaDir "server_ollama.py"
        if ((Test-Path $pyw) -and (Test-Path $srv)) {
            try {
                $act = New-ScheduledTaskAction -Execute $pyw -Argument "`"$srv`"" -WorkingDirectory $GemmaDir
                $trg = New-ScheduledTaskTrigger -AtLogOn
                $set = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -RestartCount 3 -RestartInterval (New-TimeSpan -Minutes 1) -ExecutionTimeLimit ([TimeSpan]::Zero)
                Register-ScheduledTask -TaskName "Gemma4_Ollama_Proxy" -Action $act -Trigger $trg -Settings $set -Force -Description "Gemma4 Ollama proxy (:8765) auto-start at logon" -ErrorAction Stop | Out-Null
                Start-ScheduledTask -TaskName "Gemma4_Ollama_Proxy" 2>$null
                Write-Host "  Gemma4 프록시 자동기동 등록 완료 (로그인 시 :8765)." -ForegroundColor Green
            }
            catch {
                Write-Host "  [안내] 프록시 자동기동 등록은 건너뜀(권한). 수동: $GemmaDir\register_ollama_proxy_task.ps1" -ForegroundColor DarkYellow
            }
        }
    }
    else {
        Write-Host "  [경고] Gemma4 클론 실패 — ttong0627 로그인 여부 확인." -ForegroundColor DarkYellow
    }
}
catch {
    Write-Host "[경고] Gemma4 두뇌/서버 셋업 실패: $($_.Exception.Message)" -ForegroundColor DarkYellow
}

# ── 5-b) 버킷 공유데이터(pull.ps1) + 시크릿(secrets_pull.ps1) ──────────
#   형 방식 그대로: GCS 버킷 gemma4-shared-ttong627 에서 마스킹 공유본을 받고,
#   .env·키·토큰은 GCP Secret Manager 에서 제자리 복원. 스크립트는 버킷 _manifest/ 사본.
$GcsAccount = "ttong627@gmail.com"
$GcsBucket  = "gs://gemma4-shared-ttong627"
if (Get-Command gcloud -ErrorAction SilentlyContinue) {
    $loggedIn = (gcloud auth list --filter="account=$GcsAccount" --format="value(account)" 2>$null)
    if (-not $loggedIn) {
        Write-Host "`n[안내] 버킷 데이터/시크릿을 받으려면 구글 로그인이 필요합니다:" -ForegroundColor Yellow
        Write-Host "    gcloud auth login $GcsAccount" -ForegroundColor White
        Write-Host "  로그인 후 이 한 줄을 다시 실행하면 데이터·시크릿까지 복원됩니다." -ForegroundColor DarkYellow
    }
    else {
        try {
            $mf = Join-Path $ToolsDir "_manifest"
            New-Item -ItemType Directory -Force -Path $mf | Out-Null
            Write-Step "버킷에서 동기화 스크립트(pull/secrets) 받는 중..."
            gcloud storage cp "$GcsBucket/_manifest/pull.ps1"         (Join-Path $mf "pull.ps1")         --quiet 2>$null
            gcloud storage cp "$GcsBucket/_manifest/secrets_pull.ps1" (Join-Path $mf "secrets_pull.ps1") --quiet 2>$null

            if (Test-Path (Join-Path $mf "pull.ps1")) {
                Write-Step "공유데이터 내려받기(pull.ps1 -> D:\Gemma4_shared, 마스킹본)..."
                powershell -NoProfile -ExecutionPolicy Bypass -File (Join-Path $mf "pull.ps1")
                Write-Host "  공유데이터 준비 완료 (D:\Gemma4_shared\gemma4, ttong_project)." -ForegroundColor Green

                # ── 5-c) 지식베이스/학습데이터를 MCP가 읽는 위치($GemmaDir)로 병합 ──
                #   MCP 서버(mcp_server.py)는 D:\Gemma4 기준으로 Dbsidian·learning_queue 등을 읽는다.
                #   pull 받은 마스킹본(D:\Gemma4_shared\gemma4)을 $GemmaDir 로 병합해야 젬마4가 두뇌를 참조한다.
                #   (clone된 코드 파일은 버킷 gemma4/에 없으므로 robocopy가 건드리지 않음)
                $SharedGemma = "D:\Gemma4_shared\gemma4"
                if (Test-Path $SharedGemma) {
                    Write-Step "지식베이스/학습데이터를 $GemmaDir 로 병합(robocopy)..."
                    # /E 하위폴더 포함, /XO 더 오래된 원본만 스킵(최신 마스킹본 우선), 로그 최소화
                    robocopy $SharedGemma $GemmaDir /E /XO /R:1 /W:1 /NFL /NDL /NJH /NJS /NC /NS 2>$null | Out-Null
                    # robocopy 종료코드 0~7 = 정상(8+ 만 오류)
                    if ($LASTEXITCODE -lt 8) { Write-Host "  두뇌 병합 완료: $GemmaDir 에 Dbsidian/learning_queue 등 채워짐." -ForegroundColor Green }
                    else { Write-Host "  [경고] 두뇌 병합 실패(robocopy code $LASTEXITCODE). 수동: robocopy $SharedGemma $GemmaDir /E" -ForegroundColor DarkYellow }
                }
                else {
                    Write-Host "  [안내] $SharedGemma 없음 — pull이 완료됐는지 확인 후 재실행하세요." -ForegroundColor DarkYellow
                }
            }
            if (Test-Path (Join-Path $mf "secrets_pull.ps1")) {
                Write-Step "시크릿(.env·키·토큰) 제자리 복원(secrets_pull.ps1)..."
                powershell -NoProfile -ExecutionPolicy Bypass -File (Join-Path $mf "secrets_pull.ps1")
                Write-Host "  시크릿 복원 완료." -ForegroundColor Green
            }
        }
        catch {
            Write-Host "  [경고] 버킷 데이터/시크릿 복원 실패: $($_.Exception.Message)" -ForegroundColor DarkYellow
            Write-Host "  수동: gcloud storage cp $GcsBucket/_manifest/pull.ps1 .; ./pull.ps1" -ForegroundColor DarkYellow
        }
    }
}
else {
    Write-Host "[안내] gcloud 미인식(방금 설치됨). 새 터미널에서 이 한 줄을 다시 실행하면 버킷 데이터까지 받습니다." -ForegroundColor Yellow
}

# ---------------------------------------------------------------------
# 마무리 안내
# ---------------------------------------------------------------------
Write-Head "세팅 완료! 남은 수동 작업"
Write-Host "1. DaVinci Resolve : 공식 사이트에서 직접 다운로드 (자동설치 불가)" -ForegroundColor White
Write-Host "2. MS Office       : 워드 실행 후 Microsoft 계정 로그인" -ForegroundColor White
Write-Host "3. 버킷 로그인 안됐으면 : gcloud auth login $GcsAccount 실행 후 이 한 줄 재실행(데이터/시크릿 복원)" -ForegroundColor White
Write-Host "4. Obsidian Vault  : 앱 실행 후 [폴더를 보관소로 열기] -> D:\Gemma4_shared\gemma4\Dbsidian\Obsidian (공유 마스킹본)" -ForegroundColor White
Write-Host "`n[참고] 코드: $Root, $GemmaDir (GitHub)  /  공유데이터: D:\Gemma4_shared (버킷 마스킹본)" -ForegroundColor Cyan
Write-Host "[참고] gemma4 확인: ollama list  /  프록시: http://127.0.0.1:8765/health" -ForegroundColor Cyan
Write-Host "[참고] 3-라인 동기화: 코드=GitHub / 데이터=GCS버킷(pull,push.ps1) / 시크릿=Secret Manager" -ForegroundColor Cyan
Write-Host "[참고] 허브에서 데이터 갱신: push.ps1 (PII 자동 마스킹 후 버킷 rsync)" -ForegroundColor Cyan
Start-Process "https://www.blackmagicdesign.com/products/davinciresolve"
Write-Host "`n끝! 새 터미널을 열면 모든 명령어가 인식됩니다." -ForegroundColor Green
