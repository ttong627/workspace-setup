# 형님 공통 작업 환경 (workspace-setup) — 강화판

수원 웰쉐어 사협 / 화성 비봉 로지스 / 수원 세류동 집 / 갤럭시북 — 어느 PC에서든
**한 줄 명령**으로 동일한 작업 환경을 구축한다:
**도구 설치 + 두 계정 전 프로젝트 코드 클론 + 1시간마다 자동 pull.**

## 다른 PC에서 시작하는 법 (한 줄)

PowerShell을 열고 아래 한 줄을 붙여넣고 실행:

```powershell
irm https://raw.githubusercontent.com/ttong627/workspace-setup/main/setup-workspace.ps1 | iex
```

### 새 PC 진행 순서 (3분)
1. **1번째 실행** → 도구(Git·Node·VS Code·gh·Python·CapCut·Office) 설치. 끝나면 "GitHub 로그인 필요" 안내가 뜸.
2. **GitHub 로그인** (한 번만):
   ```
   gh auth login --web      ← ttong627 로그인
   gh auth login --web      ← ttong0627 로그인
   ```
3. **새 터미널 열고 위 한 줄 다시 실행** → 두 계정 전 저장소 자동 클론 + 1시간마다 자동 pull 작업 등록.

> 이미 다 깔린 PC에서 다시 실행해도 안전합니다(없으면 clone, 있으면 pull). 콘솔 창은 뜨지 않습니다.

## 설치되는 것

| 트랙 | 프로그램 |
|---|---|
| 코딩 | Git, Node.js LTS, VS Code, GitHub CLI, Python 3.12 |
| 영상 | CapCut (DaVinci Resolve는 공식 사이트 직접 다운로드) |
| 문서 | MS Office (실행 후 계정 로그인 필요) |

## 코드 동기화 동작

- **클론 위치**: `T:\` 가 있으면 `T:\TTong_total\new_project`, 없으면 `%USERPROFILE%\TTong_total\new_project`.
- **자동 pull**: 작업 스케줄러 `TTong-Workspace-Sync`(1시간마다) + `TTong-Workspace-Sync-Logon`(로그인 시)가 `git pull --ff-only` 실행. VBS 런처로 **콘솔 창이 전혀 뜨지 않음**. 관리자 권한 불필요(`schtasks`).
- **방향은 받기 전용**: 각 PC는 GitHub에서 코드를 받기만 함. **작업 결과는 평소대로 `git push`** 하면 → 기흥 허브 PC가 1시간 내 자동 수집.
- **로그**: `%LOCALAPPDATA%\TTongWorkspace\sync-pull.log`

## 설치 후 수동 작업 3가지

1. **DaVinci Resolve**: 공식 사이트에서 직접 다운로드 (winget 불가)
2. **MS Office**: 워드 실행 후 Microsoft 계정 로그인
3. **.env(비밀키)**: GitHub에 올라가지 않으므로, 필요한 프로젝트는 기흥 PC에서 해당 `.env` 파일만 따로 복사

## 계정 연결 규칙

- 클라우드 ttong627@gmail.com → GitHub **ttong627**
- 클라우드 ttong0627@gmail.com → GitHub **ttong0627**
- 두 계정은 절대 섞지 않는다.

## 수동으로 동기화 한 번 돌리기 / 작업 끄기

```powershell
# 지금 한 번 동기화
powershell -ExecutionPolicy Bypass -File "$env:LOCALAPPDATA\TTongWorkspace\sync-pull.ps1"

# 자동 동기화 작업 제거
schtasks /Delete /TN "TTong-Workspace-Sync" /F
schtasks /Delete /TN "TTong-Workspace-Sync-Logon" /F
```
