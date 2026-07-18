# 새 PC 셋업 — 처음부터 (형 전용, 한 번만)

> 새 PC에서 이 순서대로 하면 형의 작업환경이 **집(홈 허브) PC와 똑같이** 복제됩니다.
> 도구 + 프로젝트 코드 + Claude 스킬·룰·메모리 + **Ollama 젬마4 + Obsidian + Gemma4 두뇌**까지.
> 이후 **매시간 자동 동기화**. 소요 약 30~60분(모델 9.6GB 다운로드 포함).

핵심 구조 — 동기화 라인 3개:
- **claude-config**(비공개, ttong0627) → `~/.claude` : 스킬·룰·에이전트·메모리·공통룰
- **workspace-setup**(공개, ttong627) → 프로젝트 코드 + 매시간 자동 pull 워커 + 이 셋업 스크립트
- **Gemma4**(비공개, ttong0627) → `D:\Gemma4` : MCP 서버 + 지식베이스 두뇌(나무위키·학습노트)

무거운 것 2가지는 Git이 아니라 별도로:
- **Ollama gemma4 모델(9.6GB)** → `ollama pull gemma4` 로 각 PC에서 재현(스크립트가 자동 실행)
- **원본 회사자료(16.5GB: 웰쉐어·사협 등)** → OneDrive 등 클라우드로 별도 동기화(아래 마지막 참고)

---

## 0단계: 준비물
- Windows + 인터넷 + (권장) NVIDIA GPU
- **Microsoft Store**에서 **"앱 설치 관리자(App Installer)"** 설치 (winget 명령 제공). 이미 있으면 통과.

## 1단계: 기본 도구 설치
PowerShell을 열고 한 줄:
```powershell
irm https://raw.githubusercontent.com/ttong627/workspace-setup/main/setup-workspace.ps1 | iex
```
→ Git·Node·GitHub CLI·Python·VS Code·**Ollama·Obsidian**·CapCut·Office 자동 설치.
끝에 **"GitHub 로그인 필요"** 안내가 뜨면 정상. 다음 단계로.

## 2단계: GitHub 두 계정 로그인
**새 PowerShell 창**을 열고(방금 깐 도구 인식):
```powershell
gh auth login --web
```
→ 브라우저에서 **ttong627** 로그인. 끝나면 한 번 더:
```powershell
gh auth login --web
```
→ **ttong0627** 로그인.

## 3단계: Claude 두뇌 받기 (스킬·룰·메모리·공통룰)
```powershell
gh auth switch --user ttong0627
$c="$HOME\.claude"
if(Test-Path "$c\.git"){git -C $c pull --ff-only}else{if(Test-Path $c){Rename-Item $c "$c.bak_$(Get-Date -Format yyyyMMddHHmmss)"};git clone https://github.com/ttong0627/claude-config.git $c}
```
→ `~/.claude`에 스킬·룰·에이전트·메모리·`shared-rules`가 통째로 복제됩니다.

## 4단계: 프로젝트 코드 + 젬마4 + Gemma4 서버 (한 줄 재실행)
```powershell
gh auth switch --user ttong627
irm https://raw.githubusercontent.com/ttong627/workspace-setup/main/setup-workspace.ps1 | iex
```
이 한 줄이 자동으로 **5단계까지** 처리합니다:
- 2단계) 두 계정 전 프로젝트 코드 clone + **1시간마다 자동 pull** 등록
- 3단계) 자동 동기화 작업 등록(콘솔창 안 뜸)
- **4단계) `ollama pull gemma4`** — 집 PC와 100% 동일한 9.6GB 모델 재현
- **5단계) `D:\Gemma4` 두뇌 clone + `.venv` 생성 + 의존성 설치 + 프록시(:8765) 로그인 자동기동 등록**

> 모델 다운로드(9.6GB)로 시간이 걸립니다. 중간에 "ollama 못 찾음" 안내가 나오면
> **새 터미널을 열고 위 한 줄만 다시** 실행하세요(방금 깐 ollama 인식됨).

## 5단계: Claude Code 설치 + 로그인
claude 명령이 없으면 설치:
```powershell
npm install -g @anthropic-ai/claude-code
```
그다음 실행해서 로그인(토큰은 PC마다 새로):
```powershell
claude
```

## 6단계: 확인 (제대로 됐는지)
1. `claude` 실행 후 `/` 입력 → **`/작업` `/확인` `/검사`** 보이면 스킬 OK
2. 젬마4 모델 확인:
   ```powershell
   ollama list          # gemma4:latest 9.6GB 보이면 OK
   ```
3. Gemma4 프록시 상태(로그인 후 자동 기동됨):
   ```powershell
   curl http://127.0.0.1:8765/health
   ```
4. Obsidian 실행 → **"폴더를 보관소로 열기"** → `D:\Gemma4\Dbsidian\Obsidian` 선택 → 나무위키·학습노트 보이면 OK
5. 자동 동기화 작업 확인:
   ```powershell
   schtasks /query /tn "TTong-Workspace-Sync"
   schtasks /query /tn "Gemma4_Ollama_Proxy"
   ```

---

## 이후 (자동)
- 매시간: 프로젝트 코드 + 스킬·룰·메모리 + 공통룰 + **Gemma4 두뇌(나무위키·학습)**가 자동 최신화.
- 형이 허브 PC에서 새 스킬/룰/메모리/지식 만들고 push → 1시간 내 이 PC에도 전파.

## 원본 회사자료(16.5GB) 별도 동기화 — 필요할 때만
젬마4 두뇌(나무위키·학습노트)는 Git으로 자동 복제되지만, **웰쉐어·사협 등 원본 회계·법인 파일 16.5GB는 용량이 커서 Git에서 제외**됩니다. 이 파일이 새 PC에도 필요하면:
1. 홈 PC에서 `D:\Gemma4\Dbsidian\Obsidian` 의 무거운 폴더(★웰쉐어·☆사협·김기흥_개인·99_원본)를 OneDrive/Google Drive에 올림
2. 새 PC에서 같은 클라우드 폴더를 같은 위치로 동기화
   (젬마4의 RAG 학습에는 불필요 — 두뇌 6폴더만 참조하므로 이 원본은 "파일 열람용"입니다)

## 막힐 때
- `claude-config`/`Gemma4` clone이 "Repository not found" → 활성 계정이 ttong627임. `gh auth switch --user ttong0627` 후 재시도.
- 명령을 못 찾음(`gh`/`node`/`ollama`) → 새 PowerShell 창을 열고 다시.
- D 드라이브 없는 PC → 두뇌는 `%USERPROFILE%\Gemma4`에 받아짐. MCP 서버는 `D:\Gemma4` 기준이라 경로 조정이 필요할 수 있음(안토니에게 요청).
- 프록시(:8765) 자동기동 등록이 권한으로 실패 → 관리자 PowerShell에서 `D:\Gemma4\register_ollama_proxy_task.ps1` 한 번 실행.
