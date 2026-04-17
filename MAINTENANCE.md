# OCI GenAI Regional Guide Maintenance Notes

이 문서는 다음 세션에서 바로 이어서 작업할 수 있도록 만든 유지보수 메모입니다.

목적:

- 현재 구조와 운영 결정을 빠르게 파악
- 무엇이 이미 끝났는지 기록
- 다음에 손대야 할 부분을 남기기
- `cron`, `GitHub`, `Codex CLI` 관련 제약을 잊지 않기

---

## 1. 현재 상태

프로젝트 경로:

```text
/home/opc/oci-genai-guide-maintenance
```

GitHub 저장소:

```text
https://github.com/dontotl/oci-genai-guide-maintenance
```

현재 기본 운영 모델:

- `cron + codex cli`
- GitHub Actions는 템플릿만 보관

최신 기준 문서:

- `docs/LATEST.md`
- `docs/INDEX.md`
- `docs/HISTORY.md`
- `docs/guides/OCI_GenAI_Regional_Model_Guide_v2_2026-04-17.md`

핵심 실행 파일:

- `scripts/new_guide.sh`
- `scripts/publish_guide.sh`
- `scripts/refresh_index.sh`
- `scripts/cron_refresh.sh`
- `OCI_GenAI_Regional_Model_Guide_Prompt.md`

---

## 2. 지금까지 끝난 일

### 2-1. 문서 구조

- 날짜 버전 가이드 저장 구조 생성
- `LATEST.md`, `INDEX.md`, `HISTORY.md` 자동 갱신 구조 생성
- 실행용 prompt-only 문서 생성
- 생성용 운영 MD 생성

### 2-2. 자동화

- `new_guide.sh`: 새 날짜 초안 + 프롬프트 생성
- `publish_guide.sh`: 초안 발행 + latest/index/history 갱신
- `refresh_index.sh`: 인덱스 파일 재생성
- `cron_refresh.sh`: 주기 실행용 래퍼

### 2-3. cron

현재 등록된 실제 cron 파일:

```text
/etc/cron.d/oci-genai-guide-refresh
```

현재 스케줄:

- 한국 시간 기준: 월요일 02:00
- UTC 기준: 일요일 17:00

등록 내용:

```cron
SHELL=/bin/bash
PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
HOME=/home/opc
MAILTO=""
0 17 * * 0 opc cd /home/opc/oci-genai-guide-maintenance && /home/opc/oci-genai-guide-maintenance/scripts/cron_refresh.sh >> /home/opc/oci-genai-guide-maintenance/runs/cron.log 2>&1
```

### 2-4. GitHub

- 별도 공개 저장소 생성 완료
- 초기 커밋 및 이후 보강 커밋 push 완료
- GitHub Actions 워크플로는 `templates/github-workflows/` 아래로 이동

이유:

- 현재 PAT에 `workflow` scope가 없어 `.github/workflows/*` push가 거부됨

---

## 3. 운영 중 확인된 제약

### 3-1. cron 관련

- `opc` 사용자는 `crontab -l` 등 `crontab` 명령 접근이 막혀 있음
- 따라서 `/etc/cron.d/` 방식이 필요함

### 3-2. Codex CLI 관련

- 설치 경로는 `/usr/local/bin/codex`
- `codex exec` 비대화형 실행 가능
- cron에서는 환경이 최소화되므로 `PATH`, `HOME`를 스크립트에서 고정함

### 3-3. OCI CLI 관련

- `region-subscription list`는 성공
- `compute shape list`는 현재 계정/권한으로 `NotAuthorizedOrNotFound`
- 따라서 IaaS GPU 리전별 실측표는 문서 기반 해석으로 대체 중

### 3-4. GitHub 관련

- 현재 PAT로는 일반 push는 가능
- workflow 파일이 포함되면 push 거부 가능
- 따라서 Actions는 템플릿 상태 유지 중

---

## 4. 현재 스크립트 설계 포인트

### 4-1. `cron_refresh.sh`

보수적으로 넣어둔 항목:

- 고정 `PATH`
- 고정 `HOME`
- `flock` 잠금
- 같은 날짜 최종 가이드가 이미 있으면 종료
- Codex 실행 타임아웃
- 마지막 Codex 메시지 파일 저장
- 가이드가 실제로 채워졌을 때만 publish
- git remote 없으면 push 생략

로그 파일:

```text
/home/opc/oci-genai-guide-maintenance/runs/cron.log
```

### 4-2. 초안과 발행 분리

중요 결정:

- 초안은 `runs/`에만 생성
- 발행 시에만 `docs/guides/`로 복사

이유:

- 초안이 `LATEST.md`로 잘못 잡히는 문제 방지

---

## 5. 다음에 이어서 할 작업 후보

우선순위 높은 것부터 적음.

1. `cron_refresh.sh`의 실제 Codex 실행 결과를 한 번 실운영 날짜로 검증
2. 갱신 결과에서 `new / deprecated / retired`를 추출해 `CHANGELOG.md` 한 페이지로 자동 반영
3. `compute shape list` 권한이 있는 OCI 프로파일을 확보하면 리전별 IaaS GPU 실측표 추가
4. 실패 시 Slack/Telegram/Webhook 알림 추가
5. GitHub Actions를 실제 활성화할지 재검토

---

## 6. 다음 세션에서 바로 해야 할 점검

다음에 이어서 수정할 때 먼저 볼 것:

1. `git pull`
2. `docs/LATEST.md` 최신 상태 확인
3. `runs/cron.log` 최근 실행 로그 확인
4. `/etc/cron.d/oci-genai-guide-refresh` 스케줄 확인
5. `codex exec --help`가 여전히 정상인지 확인
6. Oracle 문서 구조가 바뀌지 않았는지 확인

빠른 점검 명령:

```bash
cd /home/opc/oci-genai-guide-maintenance
git pull
tail -n 50 runs/cron.log
sed -n '1,20p' /etc/cron.d/oci-genai-guide-refresh
/usr/local/bin/codex exec --help | sed -n '1,40p'
```

---

## 7. 변경 이력 메모

### 2026-04-17

- 유지보수 저장소 생성
- prompt-only 문서 추가
- 새 날짜 초안/발행/인덱스 갱신 스크립트 추가
- GitHub repo 생성 및 push
- GitHub Actions 파일은 템플릿 위치로 이동
- `cron_refresh.sh` 보수적 버전으로 강화
- `/etc/cron.d/oci-genai-guide-refresh` 등록
- 실행 시각을 한국 시간 월요일 02:00 기준으로 조정

---

## 8. 주의사항

- `AQUA 가능`과 `즉시 GPU 사용 가능`은 다름
- `DAC 가능`과 `온디맨드 가능`은 다름
- Oracle 문서에 없는 내용은 추정으로 확정하지 않기
- `compute shape list` 결과가 없으면 문서 기반 해석이라고 명시하기
- workflow scope 없는 PAT로는 Actions 활성 push가 실패할 수 있음

