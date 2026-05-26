# OCI GenAI Regional Guide Maintenance

OCI Generative AI / DAC / AQUA / IaaS GPU 리전 가이드를
반복 생성하고 최신본을 관리하기 위한 운영 폴더입니다.

이 폴더의 목적은 세 가지입니다.

- 날짜가 붙은 가이드 파일 자동 생성
- 에이전트에 바로 넣을 수 있는 prompt-only 문서 제공
- `cron + codex cli` 또는 GitHub에서 주기적 갱신 관리

---

## 구조

```text
oci-genai-guide-maintenance/
├── MAINTENANCE.md
├── README.md
├── OCI_GenAI_Regional_Model_Guide_Prompt.md
├── docs/
│   ├── INDEX.md
│   ├── LATEST.md
│   ├── HISTORY.md
│   ├── catalog.html
│   ├── data/
│   ├── appendix/
│   ├── archive/
│   └── guides/
├── runs/
├── scripts/
│   ├── cron_refresh.sh
│   ├── collect_oci_probe.sh
│   ├── collect_oci_ai_catalog.sh
│   ├── check_public_docs.sh
│   ├── new_guide.sh
│   ├── publish_guide.sh
│   └── refresh_index.sh
└── templates/
    └── github-workflows/
        ├── refresh-request.yml
        └── publish-latest.yml
```

---

## 기본 흐름

작업을 이어서 할 때는 먼저 [MAINTENANCE.md](MAINTENANCE.md) 를 보는 것을 권장합니다.

문서만 읽을 때는 아래 순서가 가장 빠릅니다.

- [docs/INDEX.md](docs/INDEX.md): 공개 문서 진입점
- [docs/LATEST.md](docs/LATEST.md): 최신 가이드 한 페이지 복사본
- [docs/catalog.html](docs/catalog.html): 리전별 AI catalog 정적 UI
- [docs/catalog-notes.md](docs/catalog-notes.md): catalog 컬럼, source badge, query retry 해석 기준
- [docs/appendix/private-endpoint-architecture.md](docs/appendix/private-endpoint-architecture.md): private endpoint 별첨
- [docs/archive/README.md](docs/archive/README.md): 초기 가이드와 과거 운영 메모 보관 위치

`docs/LATEST.md`, `docs/INDEX.md`, `docs/HISTORY.md`, `docs/CHANGELOG.md`는 `scripts/refresh_index.sh`가 다시 생성합니다. 영구적으로 바꿀 내용은 해당 스크립트나 원본 가이드에 반영합니다.

### 1. 새 날짜 파일과 실행용 프롬프트 생성

```bash
cd /home/opc/oci-genai-guide-maintenance
./scripts/new_guide.sh
```

생성 결과:

- `runs/OCI_GenAI_Regional_Model_Guide_v3_<date>.md`
- `runs/<date>-refresh-prompt.md`

### 2. 생성된 프롬프트를 Codex 같은 에이전트에 입력

예:

```bash
cat runs/$(date -u +%F)-refresh-prompt.md
```

이 프롬프트는 새 가이드를 갱신하도록 설계돼 있습니다.

### 3. 작성이 끝난 가이드를 latest/index에 반영

```bash
./scripts/publish_guide.sh runs/OCI_GenAI_Regional_Model_Guide_v3_$(date -u +%F).md
```

반영 결과:

- `runs/`의 초안이 `docs/guides/`로 복사
- `docs/LATEST.md` 갱신
- `docs/INDEX.md` 재생성
- `docs/HISTORY.md` 갱신

---

## cron 운영 방식

GitHub Actions를 쓰지 않아도, 로컬 또는 VM에서 `cron`으로 충분히 운영할 수 있습니다.

### 1. 한 번 실행

```bash
cd /home/opc/oci-genai-guide-maintenance
./scripts/cron_refresh.sh
```

이 스크립트는 아래 순서로 동작합니다.

1. 새 날짜 초안과 prompt 생성
2. VM의 일반 실행 환경에서 OCI CLI 사전 조회 결과를 `runs/<date>-oci-probe/`에 저장
3. VM의 일반 실행 환경에서 리전별 AI catalog 스냅샷을 수집하고 공개용 JSON을 `docs/data/`에 저장
4. `codex exec` 또는 `codex`로 prompt 실행 시도
5. 결과 파일이 채워졌다고 판단되면 `publish_guide.sh` 실행
6. `refresh_index.sh`가 `docs/index.html`을 보장해 GitHub Pages 루트 URL이 `catalog.html`로 연결되도록 갱신
7. Git 저장소라면 자동 commit/push 시도

OCI 사전 조회 산출물:

- `runs/<date>-oci-probe/*.out`, `*.err`, `*.meta`: 운영자 검증용 raw 조회 결과
- `runs/<date>-oci-probe/probe.json`: 리포트 생성용 정규화 데이터
- `runs/<date>-oci-probe/customer-summary.md`: 고객용 리포트에 반영 가능한 요약
- `runs/<date>-oci-probe/summary.md`: 운영자용 상세 요약

고객용 리포트는 `probe.json`과 `customer-summary.md`를 우선 사용하고, raw 출력 경로, namespace, tenancy OCID, 로컬 경로 같은 내부 값은 본문에 노출하지 않습니다.

AI catalog 스냅샷 산출물:

- `docs/data/latest-catalog.json`: GitHub Pages UI가 읽는 최신 유효 공개용 스냅샷
- `docs/data/catalog-<date>.json`: 날짜별 공개용 스냅샷
- `docs/data/dac-reference.json`: 현재 v3 가이드 기준 DAC GPU family 공개 reference
- `docs/catalog.html`: 정적 리전 탐색 UI
- `docs/index.html`: GitHub Pages 루트 URL에서 `catalog.html`로 보내는 진입점
- `docs/catalog-notes.md`: catalog 컬럼별 데이터 기준과 `timeout`/`failed` 해석 기준
- `runs/<date>-ai-catalog/*.json`, `*.err`, `*.meta`: 운영자 검증용 raw 조회 결과
- `runs/<date>-ai-catalog/customer-matrix.md`: 고객용 표에 반영 가능한 요약

공개용 JSON에는 리전, 모델 표시명, vendor, capability, lifecycle state, GPU family, shape name, 정규화된 조회 상태만 넣습니다. OCID, tenancy OCID, compartment OCID, namespace, OCI profile, raw stdout/stderr 경로, 요청 추적값, raw 오류 전문은 넣지 않습니다.

AI catalog 수집은 기본적으로 여러 OCI CLI 조회를 병렬 실행합니다.

- `OCI_CATALOG_PROFILE`: 수집 profile, 기본값 `fast`
- `fast`: 기본 운영용. timeout `20`, attempts `1`, retry delay `0`, parallelism `24`
- `balanced`: 보완 조회용. timeout `30`, attempts `2`, retry delay `10`, parallelism `16`
- `deep`: 장애 조사/발행 전 수동 확인용. timeout `45`, attempts `3`, retry delay `60`, parallelism `8`
- `OCI_CATALOG_PARALLELISM`: 동시 실행 수. 지정하면 profile 기본값보다 우선
- `OCI_CATALOG_TIMEOUT_SECONDS`: 조회별 timeout. 지정하면 profile 기본값보다 우선
- `OCI_CATALOG_ATTEMPTS`: 조회 시도 횟수. 지정하면 profile 기본값보다 우선
- `OCI_CATALOG_RETRY_DELAY_SECONDS`: 재시도 전 대기 시간. 지정하면 profile 기본값보다 우선
- `OCI_CATALOG_RETRY_ONLY_INCOMPLETE`: 완료된 조회를 다시 실행하지 않을지 여부, 기본값 `1`
- `OCI_CATALOG_RETRY_EMPTY_RESULTS`: 조회 성공이지만 결과가 비어 있는 항목도 재시도할지 여부, 기본값 `1`
- `OCI_CATALOG_RETENTION_COUNT`: `docs/data/catalog-*.json` 보관 개수, 기본값 `12`, `0`이면 삭제하지 않음
- `OCI_CATALOG_REGIONS`: 공백으로 구분한 테스트/제한 리전 목록
- `OCI_CATALOG_COMPARTMENT_ID`: 조회 대상 compartment OCID. 없으면 probe 설정 또는 OCI config의 tenancy 값을 사용

일반 운영은 `fast`를 사용합니다. timeout/failed가 많은 날의 완전성 확인은 별도 수동 실행으로 `OCI_CATALOG_PROFILE=balanced` 또는 `OCI_CATALOG_PROFILE=deep`를 지정합니다.

AI catalog 공개 JSON에는 각 조회 항목의 최종 상태와 선택된 시도 번호를 `query_attempts`로 저장합니다. `success`는 조회 성공을 뜻하며, 실제 생성 가능, service limit, quota, capacity 보장은 아닙니다. `timeout`이나 `failed`는 미지원이 아니라 조회 불완전으로 해석하고, 재조회 또는 공식 문서 확인이 필요합니다.

`docs/data/catalog-<date>.json`은 실행 결과를 항상 남깁니다. 하지만 모든 CLI 조회가 `timeout`/`failed`로 끝나 성공 조회가 하나도 없으면 `docs/data/latest-catalog.json`은 덮어쓰지 않습니다. 이 경우 날짜별 스냅샷으로 실패 실행을 추적하고, GitHub Pages UI는 마지막 유효 스냅샷을 계속 사용합니다.

공개 JSON 생성 후에는 내부 식별자, raw 출력 경로, 요청 추적값, profile 문자열이 들어갔는지 자동 검사합니다. 금지 패턴이 발견되면 catalog 수집은 실패로 종료합니다.

발행 전 공개 문서 검사는 아래 명령으로 수행합니다.

```bash
./scripts/check_public_docs.sh
```

이 검사는 `docs/data/*.json`의 JSON 문법과 공개 금지 패턴을 확인하고, `docs/*.md`, `docs/*.html` 계열에서 내부 경로와 요청 식별자 같은 고위험 문자열을 찾습니다.

GenAI private endpoint 아키텍처 별첨은 `docs/appendix/private-endpoint-architecture.md`에 있습니다. private endpoint는 미지원 리전에 모델이나 GPU capacity를 새로 만드는 기능이 아니라, 지원 리전에 있는 GenAI endpoint를 private network로 접근하는 패턴으로 설명합니다.

### 2. cron 등록 예시

이 VM은 `opc` 사용자가 `crontab` 명령에 직접 접근하지 못할 수 있으므로,
권장 방식은 `/etc/cron.d/`에 root가 엔트리를 추가하는 것입니다.

예:

```cron
SHELL=/bin/bash
PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
HOME=/home/opc
MAILTO=""
0 17 * * 0 opc cd /home/opc/oci-genai-guide-maintenance && /home/opc/oci-genai-guide-maintenance/scripts/cron_refresh.sh >> /home/opc/oci-genai-guide-maintenance/runs/cron.log 2>&1
```

의미:

- 매주 월요일 KST 02:00 실행
- UTC 기준으로는 일요일 17:00 실행
- 로그는 `runs/cron.log`에 누적

### 3. 주의

- `codex` CLI가 로그인되어 있어야 함
- 비대화형 실행이 가능한 버전이어야 함
- OCI CLI 또는 웹 조회가 필요한 경우 네트워크/권한 상태가 맞아야 함
- OCI CLI 조회는 Codex 샌드박스 안이 아니라 `collect_oci_probe.sh`가 먼저 수집한 정규화 결과를 우선 사용
- 실패 시 `runs/` 아래 프롬프트와 초안이 남으므로 수동 후속 작업 가능

---

## GitHub 운영 방식

현재 저장소에는 GitHub Actions 파일을 **템플릿**으로만 넣어 두었습니다.
이유는 현재 PAT에 `workflow` scope가 없어서 `.github/workflows/*`를 포함한 push가 거부되기 때문입니다.

나중에 GitHub Actions를 켜고 싶으면:

```bash
mkdir -p .github/workflows
cp templates/github-workflows/*.yml .github/workflows/
git add .github/workflows templates/github-workflows README.md
git commit -m "Enable GitHub Actions workflows"
git push
```

그 시점에는 `workflow` scope가 있는 PAT 또는 웹 UI 업로드가 필요할 수 있습니다.

준비된 워크플로 템플릿은 아래 두 개입니다.

### 1. `refresh-request.yml`

- 주 1회 실행
- 새 리프레시 요청 이슈 생성
- 사람이 직접 또는 에이전트로 갱신 작업 시작

### 2. `publish-latest.yml`

- `docs/guides/*.md` 변경 시 자동 실행
- `LATEST.md`, `INDEX.md`, `HISTORY.md` 자동 갱신
- 변경 사항을 자동 커밋

즉, 완전 자동 생성이 아니라도:

- 주기적으로 갱신 요청이 뜨고
- 새 가이드를 커밋하면
- 최신 1페이지와 이력이 자동 정리됩니다.

---

## 한 페이지 최신본 관리

`docs/LATEST.md`는 항상 **가장 최신 가이드의 복사본**입니다.

권장 운영 방식:

- 새 모델 추가
- deprecated / retired 모델 반영
- 신규 리전 추가
- DAC 유닛 변경

이런 변경이 있으면 새 날짜 가이드를 생성하고 `publish_guide.sh`를 실행합니다.
그러면 `LATEST.md`만 보면 최신 상태를 한 페이지로 볼 수 있습니다.

---

## 권장 업데이트 주기

- 월 1회
- Oracle Generative AI 릴리즈 노트 발표 후
- 새 리전 발표 후
- 주요 모델 deprecated/retired 공지 후

---

## 중요 메모

- `compute shape list`는 권한이 없으면 실패할 수 있습니다.
- 이 경우 문서 기준 shape 해석표로 대체하고, 문서에 실패 사유를 적습니다.
- `AQUA 지원`과 `즉시 GPU 생성 가능`은 같은 의미가 아닙니다.
- `DAC 가능`과 `온디맨드 가능`은 반드시 분리해 적습니다.
- 현재 우선 운영 모델은 `cron + codex cli` 입니다.
