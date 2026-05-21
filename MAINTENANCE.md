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
- `docs/CHANGELOG.md`
- `docs/catalog.html`
- `docs/catalog-notes.md`
- `docs/data/latest-catalog.json`
- `docs/data/dac-reference.json`
- `docs/appendix/private-endpoint-architecture.md`
- `docs/archive/README.md`
- `docs/guides/OCI_GenAI_Regional_Model_Guide_v3_2026-05-19.md`

핵심 실행 파일:

- `scripts/new_guide.sh`
- `scripts/collect_oci_probe.sh`
- `scripts/collect_oci_ai_catalog.sh`
- `scripts/check_public_docs.sh`
- `scripts/publish_guide.sh`
- `scripts/refresh_index.sh`
- `scripts/cron_refresh.sh`
- `OCI_GenAI_Regional_Model_Guide_Prompt.md`

---

## 2. 지금까지 끝난 일

### 2-1. 문서 구조

- 날짜 버전 가이드 저장 구조 생성
- `LATEST.md`, `INDEX.md`, `HISTORY.md` 자동 갱신 구조 생성
- `CHANGELOG.md` 자동 갱신 구조 생성
- 실행용 prompt-only 문서 생성
- 생성용 운영 MD 생성
- 초기 가이드와 과거 운영 메모를 `docs/archive/` 아래로 편입

### 2-2. 자동화

- `new_guide.sh`: 새 날짜 초안 + 프롬프트 생성
- `publish_guide.sh`: 초안 발행 + latest/index/history 갱신
- `refresh_index.sh`: 인덱스와 changelog 파일 재생성
- `cron_refresh.sh`: 주기 실행용 래퍼
- `collect_oci_probe.sh`: Codex 실행 전에 VM 일반 환경에서 OCI CLI 조회 결과 수집
- `collect_oci_probe.sh`는 raw 조회 결과와 별도로 `probe.json`, `customer-summary.md`를 생성해 고객용 리포트에 안전하게 반영할 수 있는 정규화 입력을 제공합니다.
- `collect_oci_ai_catalog.sh`: 구독 READY 리전 기준으로 GenAI 모델, Data Science shape, IaaS GPU shape를 조회하고 공개 가능한 날짜별 catalog 스냅샷을 생성
- `docs/catalog.html`: GitHub Pages에서 정적 JSON을 읽어 리전별 AI catalog를 필터링해 보여주는 UI
- `docs/catalog-notes.md`: catalog 컬럼별 source badge, query status, retry 취합 해석 기준
- `docs/data/dac-reference.json`: v3 가이드 기준 공식 DAC GPU family 공개 reference. CLI 관측값이 아니라 공식 문서 기준 보조 데이터입니다.
- `docs/appendix/private-endpoint-architecture.md`: GenAI/DAC/GPU 미지원 리전에서 private endpoint와 cross-region 접근을 어떻게 설명할지 정리한 별첨
- `check_public_docs.sh`: 공개 JSON과 docs 문서의 민감 문자열 노출 여부를 발행 전 검사

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
- 2026-05-19 AI catalog 스냅샷 기준 `compute shape list`는 43개 리전에서 success로 정규화됨
- 일부 GenAI model list 조회는 리전별로 실패할 수 있으므로 공개 가이드는 공식 문서와 스냅샷 조회 상태를 분리해서 해석함
- shape 가시성은 즉시 생성 가능 또는 capacity 보장을 뜻하지 않음

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
- Codex 실행 전 `runs/<date>-oci-probe/summary.md`에 OCI CLI 사전 조회 결과 저장
- Codex 실행 전 `runs/<date>-oci-probe/probe.json`과 `customer-summary.md`에 리포트 생성용 정규화 결과 저장
- Codex 실행 전 `runs/<date>-ai-catalog/`에 리전별 AI catalog raw 결과 저장
- Codex 실행 전 `docs/data/catalog-<date>.json`에 공개 가능한 스냅샷 저장. 성공한 CLI 조회가 하나 이상 있을 때만 `docs/data/latest-catalog.json` 갱신
- AI catalog 수집은 기본 `OCI_CATALOG_PROFILE=fast`로 실행하며 timeout `20`, attempts `1`, retry delay `0`, parallelism `24`를 사용
- 보완 조회는 `balanced`, 장애 조사/발행 전 수동 확인은 `deep` profile을 명시해 실행
- 공개 JSON의 `query_attempts`는 최종 상태, 선택된 시도 번호, 관측 항목 수만 저장하고 raw 경로와 오류 전문은 공개하지 않음
- 날짜별 공개 스냅샷은 `OCI_CATALOG_RETENTION_COUNT` 기준으로 보관하며 기본값은 `12`
- 공개 JSON 생성 후 내부 식별자, raw 출력 경로, 요청 추적값, profile 문자열이 들어갔는지 자동 검사
- 발행 전 `./scripts/check_public_docs.sh`로 `docs/data/*.json` 문법과 공개 문서 금지 패턴을 확인
- Codex 실행 타임아웃
- 마지막 Codex 메시지 파일 저장
- 가이드가 실제로 채워졌을 때만 publish
- git commit 실패 시 중단
- git push 실패 시 중단하고 로그 기록
- git remote 없으면 push 생략

로그 파일:

```text
/home/opc/oci-genai-guide-maintenance/runs/cron.log
```

OCI 사전 조회 결과:

```text
/home/opc/oci-genai-guide-maintenance/runs/<date>-oci-probe/summary.md
/home/opc/oci-genai-guide-maintenance/runs/<date>-oci-probe/probe.json
/home/opc/oci-genai-guide-maintenance/runs/<date>-oci-probe/customer-summary.md
```

`summary.md`와 raw `*.out`, `*.err`, `*.meta` 파일은 운영자 검증용입니다. 고객용 리포트 작성에는 `probe.json`과 `customer-summary.md`를 우선 사용합니다. 이 결과는 Codex 샌드박스 네트워크 제한과 실제 OCI CLI 조회 실패를 구분하기 위한 기준입니다.

### 4-2. 초안과 발행 분리

중요 결정:

- 초안은 `runs/`에만 생성
- 발행 시에만 `docs/guides/`로 복사

이유:

- 초안이 `LATEST.md`로 잘못 잡히는 문제 방지

---

## 5. 다음에 이어서 할 작업 후보

우선순위 높은 것부터 적음.

1. `cron_refresh.sh`의 commit/push 실패 처리 변경이 다음 실운영 날짜에도 정상 동작하는지 검증
2. `compute shape list` 권한이 있는 OCI 프로파일을 확보하면 리전별 IaaS GPU 실측표 추가
3. GitHub Actions를 실제 활성화할지 재검토
4. v3 문서 구조에서도 `probe.json` 입력 계약은 유지
5. 공개 catalog JSON에는 OCID, tenancy OCID, compartment OCID, namespace, OCI profile, raw stdout/stderr 경로, 요청 추적값, raw 오류 전문을 넣지 않기
6. GitHub Pages UI는 정적 스냅샷 필터링만 수행하고 OCI API를 직접 호출하지 않기
7. `docs/archive/`의 오래된 기준 문서는 최신 설계 근거가 아니라 참고 이력으로만 사용하기

제외한 항목:

- 실패 시 Slack/Telegram/Webhook 알림은 현재 운영 범위에서 제외

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

### 2026-05-18

- 리포트 본문 말투를 `~습니다` 체로 통일
- `.codex` bind mount 파일을 `.gitignore`에 추가
- `refresh_index.sh`가 `docs/CHANGELOG.md`를 자동 생성하도록 변경
- `cron_refresh.sh`가 git commit/push 실패를 숨기지 않고 실패로 종료하도록 변경
- 실패 알림 연동은 현재 범위에서 제외

### 2026-05-21

- 상위 디렉토리에 있던 현재 프로젝트 관련 초기 가이드와 생성 지침을 `docs/archive/`로 편입
- `docs/UPDATE_2026-05-18.md`를 `docs/archive/update-notes/`로 이동해 과거 운영 메모로 분류
- `refresh_index.sh`가 INDEX에 최신 가이드, catalog, latest, changelog, history, private endpoint, archive 진입점을 함께 생성하도록 정리

### 2026-05-21 catalog UI / retry

- `collect_oci_ai_catalog.sh`에 `fast`/`balanced`/`deep` profile과 best-result 취합을 추가
- `docs/data/latest-catalog.json`에 `query_attempts` 공개 메타데이터를 추가
- `docs/catalog.html`에서 컬럼별 source badge, GPU shape/status 매핑, `Query Details`를 명확히 표시
- `timeout`과 `failed`는 미지원이 아니라 조회 불완전으로 설명
- timeout-only 실행은 날짜별 스냅샷에 보존하되 `latest-catalog.json`은 마지막 유효 스냅샷으로 유지

---

## 8. 주의사항

- `AQUA 가능`과 `즉시 GPU 사용 가능`은 다름
- `DAC 가능`과 `온디맨드 가능`은 다름
- Oracle 문서에 없는 내용은 추정으로 확정하지 않기
- `compute shape list` 결과가 없으면 문서 기반 해석이라고 명시하기
- 고객용 리포트에는 raw stdout/stderr 경로, namespace, tenancy OCID, 로컬 경로를 노출하지 않기
- workflow scope 없는 PAT로는 Actions 활성 push가 실패할 수 있음
- 생성되는 리포트 본문은 `~다`, `~했다`, `~썼다` 체가 아니라 `~습니다`, `~했습니다`, `~썼습니다` 체로 통일하기
