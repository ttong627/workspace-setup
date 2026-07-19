# 메인 PC(ttongfir) SSH 접속 방법 — 다른 PC에서

> Tailscale + SSH 키로 메인 PC(`ttongfir`, `100.98.244.52`)에 **비밀번호 없이** 접속한다.
> 다른 PC가 접속에 실패하는 원인 대부분은 **③번(Windows 관리자 계정 함정)** 이다.

## ⚠️ 핵심 함정 (먼저 읽기)
메인 PC의 `ttong` 계정은 **관리자**라서, Windows OpenSSH는
`~/.ssh/authorized_keys`가 **아니라** `C:\ProgramData\ssh\administrators_authorized_keys`
를 본다. 그래서 `ssh-copy-id`로 키를 넣으면 **엉뚱한 위치라 무시**되고 계속 비밀번호를 묻는다.
→ 반드시 아래 ③번 방식으로 `administrators_authorized_keys`에 등록해야 한다.

---

## ① Tailscale 연결 (같은 계정이어야 함)
```
# Tailscale 설치 후 (winget이 멈추면 https://tailscale.com/download 에서 MSI 직접 설치)
tailscale up
# → 브라우저에서 Google  ttong627@gmail.com  로그인
tailscale status
# → 목록에  'ttongfir  100.98.244.52'  가 보이면 OK
```

## ② SSH 키 생성 (그 PC에서, Git Bash)
```bash
ssh-keygen -t ed25519 -N "" -f ~/.ssh/id_ed25519
```

## ③ 공개키를 메인 PC에 등록 ★핵심★ (비밀번호 1회)
Git Bash에서 아래 한 줄. `ssh-copy-id`는 쓰지 말 것.
```bash
KEY="$(cat ~/.ssh/id_ed25519.pub)"
ssh ttong@100.98.244.52 "powershell -NoProfile -Command \"\$f = Join-Path \$env:ProgramData 'ssh\\administrators_authorized_keys'; if(-not (Test-Path \$f)){ New-Item -ItemType File -Force -Path \$f | Out-Null }; Add-Content -Path \$f -Value '$KEY'; icacls \$f /inheritance:r /grant 'Administrators:F' /grant 'SYSTEM:F' | Out-Null; Write-Output OK\""
```
- 처음이면 `Are you sure...` → `yes`
- `ttong@100.98.244.52's password:` → **메인 PC 비밀번호 입력** (화면엔 안 보임)
- `OK` 가 나오면 성공

## ④ 접속 확인
```bash
ssh ttong@100.98.244.52 "hostname"
```
→ `TTong...Fir` 가 나오면 **접속 완료**. 이후로는 비밀번호 없이 자동 접속된다.

---

## 막힐 때 (3대 원인)
| 증상 | 원인 | 해결 |
|---|---|---|
| `tailscale status`에 ttongfir 없음 | Tailscale 계정이 다름 | 같은 Google(`ttong627`)로 로그인 |
| 키 등록했는데 `Permission denied (publickey,password,...)` | ③ 관리자 함정 | `administrators_authorized_keys`에 넣기 |
| `ssh-copy-id` 했는데 계속 비번 물음 | `~/.ssh`는 관리자 계정에서 무시됨 | 위 ③ 명령으로 재등록 |

## 접속 후 할 수 있는 것
- **터미널**: `ssh ttong@100.98.244.52` (또는 `ssh ttong@ttongfir`)
- **파일 탐색기**: `\\100.98.244.52\` 또는 `\\ttongfir\`
- 메인 PC 열린 서비스: SSH(22), 파일공유 SMB(445)

## 대용량 폴더 복제 (참고)
SSH로 폴더를 통째로 가져올 때, 원격 tar는 **`cmd /c`로 감싸야** 바이너리가 안 깨진다
(메인 PC 기본 셸이 PowerShell이라 그냥 tar하면 스트림이 오염됨):
```bash
ssh ttong@100.98.244.52 'cmd /c "tar -C I:/ttong_project -cf - --exclude=node_modules ."' | tar -C /대상경로 -xf -
```
