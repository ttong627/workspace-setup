# 형님 공통 작업 환경 (workspace-setup)

수원 웰쉐어 사협 / 화성 비봉 로지스 / 수원 세류동 집 / 갤럭시북 — 어느 PC에서든
**한 줄 명령**으로 동일한 작업 환경(코딩 + 동영상 + 문서)을 자동 구축한다.

## 다른 PC에서 시작하는 법 (한 줄)

PowerShell을 열고 아래 한 줄을 붙여넣고 실행:

```powershell
irm https://raw.githubusercontent.com/ttong627/workspace-setup/main/setup-workspace.ps1 | iex
```

## 설치되는 것

| 트랙 | 프로그램 |
|---|---|
| 코딩 | Git, Node.js LTS, VS Code, GitHub CLI, Python 3.12 |
| 영상 | CapCut (DaVinci Resolve는 공식 사이트 직접 다운로드) |
| 문서 | MS Office (실행 후 계정 로그인 필요) |

## 설치 후 수동 작업 3가지

1. **GitHub 로그인**: `gh auth login --web` → ttong627 / ttong0627 로그인
2. **DaVinci Resolve**: 공식 사이트에서 직접 다운로드 (winget 불가)
3. **MS Office**: 워드 실행 후 Microsoft 계정 로그인

## 계정 연결 규칙

- 클라우드 ttong627@gmail.com → GitHub **ttong627**
- 클라우드 ttong0627@gmail.com → GitHub **ttong0627**
- 두 계정은 절대 섞지 않는다.
