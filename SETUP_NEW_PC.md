# 새 PC 셋업 — 처음부터 (형 전용, 한 번만)

> 새 PC에서 이 순서대로 하면 형의 작업환경(도구 + 프로젝트 코드 + Claude 스킬·룰·메모리·프로젝트룰)이
> **그대로 복제**되고, 이후 **매시간 자동 동기화**됩니다. 소요 약 30분(설치 시간 포함).

핵심 구조 — 동기화 라인 2개:
- **claude-config**(비공개, ttong0627) → `~/.claude` : 스킬·룰·에이전트·메모리·공통룰
- **workspace-setup**(공개, ttong627) → 프로젝트 코드 + 매시간 자동 pull 워커

---

## 0단계: 준비물
- Windows + 인터넷
- **Microsoft Store**에서 **"앱 설치 관리자(App Installer)"** 설치 (winget 명령 제공). 이미 있으면 통과.

## 1단계: 기본 도구 설치
PowerShell을 열고 한 줄:
```powershell
irm https://raw.githubusercontent.com/ttong627/workspace-setup/main/setup-workspace.ps1 | iex
```
→ Git·Node·GitHub CLI·Python·VS Code 등 자동 설치. 끝에 **"GitHub 로그인 필요"** 안내가 뜨면 정상. 다음 단계로.

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

## 4단계: 프로젝트 코드 + 자동 동기화 등록
```powershell
gh auth switch --user ttong627
irm https://raw.githubusercontent.com/ttong627/workspace-setup/main/setup-workspace.ps1 | iex
```
→ 두 계정 전 프로젝트 코드 clone + **1시간마다 자동 pull**(코드 + claude-config + 공통룰 배포) 작업 등록. 콘솔창 안 뜸.

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
2. 아무 프로젝트 폴더(예: `T:\TTong_total\new_project\yyplus`)에서 `claude` 실행 →
   그 프로젝트의 **`CLAUDE.md`(프로젝트 룰)가 자동 로드**되어 계정·규칙을 미리 앎
3. 자동 동기화 작업 확인:
   ```powershell
   schtasks /query /tn "TTong-Workspace-Sync"
   ```

---

## 이후 (자동)
- 매시간: 프로젝트 코드 + 스킬·룰·메모리 + 공통룰이 자동 최신화.
- 형이 허브 PC에서 새 스킬/룰/메모리 만들고 push → 1시간 내 이 PC에도 전파.

## 막힐 때
- `claude-config` clone이 "Repository not found" → 활성 계정이 ttong627임. `gh auth switch --user ttong0627` 후 재시도.
- 명령을 못 찾음(`gh`/`node`) → 새 PowerShell 창을 열고 다시.
- T 드라이브 없는 PC → 코드는 `%USERPROFILE%\TTong_total\new_project`에 받아짐(정상).
