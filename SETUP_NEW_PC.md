# 새 PC 셋업 — 처음부터 (형 전용, 한 번만)

> 새 PC에서 이 순서대로 하면 형의 작업환경이 **집(홈 허브) PC와 똑같이** 복제됩니다.
> 도구 + 프로젝트 코드 + Claude 스킬·룰·메모리 + **Ollama 젬마4 + Obsidian + Gemma4 두뇌(데이터·시크릿)**까지.
> 이후 **매시간 자동 동기화**. 소요 약 30~60분(모델 9.6GB 다운로드 포함).

## 핵심 구조 — 동기화 3-라인 (형이 이미 구축한 방식)
| 라인 | 대상 | 도구 | 위치 |
|------|------|------|------|
| **① 코드** | 스킬·룰·메모리 / 프로젝트 / Gemma4 서버코드 | GitHub `git clone` | `~/.claude`, 프로젝트폴더, `D:\Gemma4` |
| **② 데이터** | Vault(나무위키·학습)·학습데이터·프로젝트자료 | **GCS 버킷 `pull.ps1`** (PII 자동 마스킹) | `D:\Gemma4_shared` |
| **③ 시크릿** | .env·서비스계정키·토큰 (37개) | **GCP Secret Manager `secrets_pull.ps1`** | 각 제자리 복원 |

- **버킷**: `gs://gemma4-shared-ttong627` (비공개, 서울, ttong627@gmail.com / wssc-nutrition)
- **모델**: Ollama `gemma4`(9.6GB)는 `ollama pull gemma4`로 각 PC에서 재현(스크립트가 자동)

---

## 0단계: 준비물
- Windows + 인터넷 + (권장) NVIDIA GPU
- **Microsoft Store**에서 **"앱 설치 관리자(App Installer)"** 설치 (winget 명령 제공). 이미 있으면 통과.

## 1단계: 기본 도구 설치
PowerShell을 열고 한 줄:
```powershell
irm https://raw.githubusercontent.com/ttong627/workspace-setup/main/setup-workspace.ps1 | iex
```
→ Git·Node·GitHub CLI·Python·VS Code·**Ollama·Obsidian·Google Cloud SDK**·CapCut·Office 자동 설치.
끝에 **"GitHub 로그인 필요"** 안내가 뜨면 정상.

## 2단계: GitHub 두 계정 로그인
**새 PowerShell 창**을 열고:
```powershell
gh auth login --web    # ttong627 로그인
gh auth login --web    # 한 번 더 → ttong0627 로그인
```

## 3단계: 구글(버킷) 로그인 — 데이터·시크릿용
```powershell
gcloud auth login ttong627@gmail.com
```
→ 브라우저에서 구글 로그인. (Google Cloud SDK는 1단계에서 설치됨)

## 4단계: Claude 두뇌 받기 (스킬·룰·메모리)
```powershell
gh auth switch --user ttong0627
$c="$HOME\.claude"
if(Test-Path "$c\.git"){git -C $c pull --ff-only}else{if(Test-Path $c){Rename-Item $c "$c.bak_$(Get-Date -Format yyyyMMddHHmmss)"};git clone https://github.com/ttong0627/claude-config.git $c}
```

## 5단계: 프로젝트 + 젬마4 + 데이터 + 시크릿 (한 줄 재실행)
```powershell
gh auth switch --user ttong627
irm https://raw.githubusercontent.com/ttong627/workspace-setup/main/setup-workspace.ps1 | iex
```
이 한 줄이 자동으로 처리합니다:
- 두 계정 전 프로젝트 코드 clone + **1시간마다 자동 pull** 등록
- **`ollama pull gemma4`** — 집 PC와 100% 동일한 9.6GB 모델 재현
- **`D:\Gemma4` 서버코드 clone** + `.venv` + 의존성 + 프록시(:8765) 자동기동 등록
- **② 데이터**: 버킷 `pull.ps1` → `D:\Gemma4_shared` (마스킹 공유본) → **`robocopy`로 `D:\Gemma4`에 병합** (MCP 서버가 읽는 위치에 Dbsidian·learning_queue 채움)
- **③ 시크릿**: `secrets_pull.ps1` → .env·키·토큰 제자리 복원

> 모델 다운로드(9.6GB)로 시간이 걸립니다. "ollama/gcloud 못 찾음" 안내가 나오면
> **새 터미널을 열고 위 한 줄만 다시** 실행하세요(방금 깐 도구 인식됨).

## 6단계: Claude Code 설치 + 로그인
```powershell
npm install -g @anthropic-ai/claude-code
claude
```

## 7단계: 확인 (제대로 됐는지)
1. `claude` 실행 후 `/` → **`/작업` `/확인` `/검사`** 보이면 스킬 OK
2. `ollama list` → `gemma4:latest` 9.6GB 보이면 OK
3. `curl http://127.0.0.1:8765/health` → 프록시 응답 OK (로그인 후 자동 기동)
4. Obsidian 실행 → "폴더를 보관소로 열기" → `D:\Gemma4\Dbsidian\Obsidian` (병합된 마스킹본, MCP와 동일 경로)
5. 자동작업 확인:
   ```powershell
   schtasks /query /tn "TTong-Workspace-Sync"
   schtasks /query /tn "Gemma4_Ollama_Proxy"
   ```

---

## 이후 (자동 + 수동)
- **매시간 자동**: 코드(스킬·룰·메모리·프로젝트)가 GitHub에서 최신화.
- **데이터 갱신(허브 PC에서 수동)**: 새 지식·학습데이터를 버킷에 올릴 때
  ```powershell
  # 버킷 _manifest/push.ps1 → PII 자동 마스킹 후 버킷 rsync(변경분만)
  gcloud storage cp gs://gemma4-shared-ttong627/_manifest/push.ps1 .; ./push.ps1
  ```
- **새 PC에서 데이터 최신화**: `pull.ps1` 다시 실행하면 `D:\Gemma4_shared`가 갱신됨.

## 중요 — PII 마스킹 원칙 (형 시스템)
- 버킷·타 PC 데이터는 **전부 PII 마스킹본**(전화·주민번호 자동 마스킹).
- **원본 PII는 허브 PC(`D:\Gemma4`)에만** 존재. 타 PC는 참조용 마스킹본.
- 바이너리 오피스(xlsx·pdf·hwp 등)·`99_원본`·시크릿은 버킷에서 의도적 제외.

## 막힐 때
- `claude-config`/`Gemma4` clone이 "Repository not found" → `gh auth switch --user ttong0627` 후 재시도.
- 명령 못 찾음(`gh`/`node`/`ollama`/`gcloud`) → 새 PowerShell 창 열고 다시.
- 버킷 데이터/시크릿이 안 받아짐 → `gcloud auth login ttong627@gmail.com` 후 5단계 한 줄 재실행.
- 프록시(:8765) 자동기동 등록이 권한으로 실패 → 관리자 PowerShell에서 `D:\Gemma4\register_ollama_proxy_task.ps1` 한 번 실행.
- D 드라이브 없는 PC → 서버코드는 `%USERPROFILE%\Gemma4`. MCP 서버는 `D:\Gemma4` 기준이라 경로 조정 필요(안토니에게 요청).
