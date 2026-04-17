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
├── README.md
├── OCI_GenAI_Regional_Model_Guide_Prompt.md
├── docs/
│   ├── INDEX.md
│   ├── LATEST.md
│   ├── HISTORY.md
│   └── guides/
├── runs/
├── scripts/
│   ├── cron_refresh.sh
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

### 1. 새 날짜 파일과 실행용 프롬프트 생성

```bash
cd /home/opc/oci-genai-guide-maintenance
./scripts/new_guide.sh
```

생성 결과:

- `runs/OCI_GenAI_Regional_Model_Guide_v2_<date>.md`
- `runs/<date>-refresh-prompt.md`

### 2. 생성된 프롬프트를 Codex 같은 에이전트에 입력

예:

```bash
cat runs/$(date -u +%F)-refresh-prompt.md
```

이 프롬프트는 새 가이드를 갱신하도록 설계돼 있습니다.

### 3. 작성이 끝난 가이드를 latest/index에 반영

```bash
./scripts/publish_guide.sh runs/OCI_GenAI_Regional_Model_Guide_v2_$(date -u +%F).md
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
2. `codex exec` 또는 `codex`로 prompt 실행 시도
3. 결과 파일이 채워졌다고 판단되면 `publish_guide.sh` 실행
4. Git 저장소라면 자동 commit/push 시도

### 2. cron 등록 예시

```cron
0 2 * * 1 cd /home/opc/oci-genai-guide-maintenance && ./scripts/cron_refresh.sh >> /home/opc/oci-genai-guide-maintenance/runs/cron.log 2>&1
```

의미:

- 매주 월요일 UTC 02:00 실행
- 로그는 `runs/cron.log`에 누적

### 3. 주의

- `codex` CLI가 로그인되어 있어야 함
- 비대화형 실행이 가능한 버전이어야 함
- OCI CLI 또는 웹 조회가 필요한 경우 네트워크/권한 상태가 맞아야 함
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
