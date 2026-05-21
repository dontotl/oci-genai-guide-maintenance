# OCI GenAI Regional Guide Changelog

가이드별 `이번 업데이트 변화 요약` 섹션을 최신순으로 모은 자동 생성 파일입니다.

## 2026-05-21 (v3)

[OCI_GenAI_Regional_Model_Guide_v3_2026-05-21.md](guides/OCI_GenAI_Regional_Model_Guide_v3_2026-05-21.md)

| 구분 | 변화 | 기준일 | 이 문서의 반영 |
|---|---|---:|---|
| 신규 모델 | `xai.grok-tts` 기반 xAI Voice Text to Speech가 추가되었습니다. | 2026-05-15 | 음성 합성 모델로 별도 표에 넣었습니다. |
| import 호환 모델 추가 | `Qwen/Qwen3.6-35B-A3B`, `Qwen/Qwen3.5-9B`, `google/gemma-4-31B-it`가 import 호환 모델에 추가되었습니다. | 2026-05-11 | imported model 권장 DAC 표에 넣었습니다. |
| 신규 모델 | `cohere.rerank-v4.0-pro`, `cohere.rerank-v4.0-fast`가 Cohere Rerank 4.0으로 확인됩니다. | 2026-05-09 | 전용 DAC `RERANK_COHERE x1`로 넣었습니다. release notes는 on-demand와 dedicated를 함께 언급하지만, 개별 모델 페이지는 dedicated only라고 설명하므로 mode는 문서 간 상충으로 표시했습니다. |
| 기능 확장 | Cohere Embed 4가 configurable output dimensions와 text+image `EmbedText` payload를 지원합니다. | 2026-05-09 | 임베딩 모델 강점과 DAC 표에 반영했습니다. |
| 리전 추가 | OCI Generative AI가 UAE Central (Abu Dhabi) 리전에서 사용 가능해졌습니다. | 2026-05-05 | 서비스 가용성 표에 넣었습니다. 다만 A10/A100/H100/H200 전용 DAC 공개표에는 확인되지 않아 `문서상 미확인`으로 표시했습니다. |
| retired / replacement | Oracle retirement 문서 기준으로 Grok 3 계열과 일부 구형 Cohere / Meta 모델은 신규 설계에서 우선 제외하는 편이 안전합니다. | 2026-05-19 확인 | retired / deprecated 메모와 빠른 추천에서 제외했습니다. |
| 대표 리전 GPU 조회 | 대표 리전의 IaaS GPU shape 조회가 성공했습니다. | 2026-05-19 | IaaS/AQUA 해석 표에 반영했습니다. |
| AI catalog 공개 JSON | 43개 리전 행을 포함한 공개 스냅샷을 생성했습니다. | 2026-05-19 | GitHub Pages catalog UI에서 리전별 모델/shape 가시성과 조회 상태를 표로 확인할 수 있습니다. |
| Catalog UI 개선 | catalog 표의 컬럼별 source badge, GPU shape/status 매핑, `Query Details`, `query_attempts` 표시 기준을 추가했습니다. | 2026-05-21 | `CLI query`, `Oracle docs reference`를 구분하고 `timeout`/`failed`를 미지원이 아닌 조회 불완전으로 설명합니다. |
| Catalog 수집 profile | AI catalog 수집은 기본 `fast` profile과 필요 시 `balanced`/`deep` profile을 사용합니다. | 2026-05-21 | `fast`는 1회 빠른 수집, `balanced`/`deep`은 수동 보완 조회에 사용하며 `query_attempts`에는 최종 상태와 선택된 시도 번호를 공개합니다. |
핵심 변화는 `Cohere Rerank 4.0`, `Cohere Embed 4 기능 확장`, `xAI Voice`, `Abu Dhabi 리전`, `import 호환 모델 3개 추가`, `대표 리전 GPU 조회 성공 결과 반영`, `AI catalog 공개 JSON 생성`, `catalog UI source/status 매핑 개선`, `catalog query 재시도 기준 추가`입니다.

## 2026-05-19 (v3)

[OCI_GenAI_Regional_Model_Guide_v3_2026-05-19.md](guides/OCI_GenAI_Regional_Model_Guide_v3_2026-05-19.md)

| 구분 | 변화 | 기준일 | 이 문서의 반영 |
|---|---|---:|---|
| 신규 모델 | `xai.grok-tts` 기반 xAI Voice Text to Speech가 추가되었습니다. | 2026-05-15 | 음성 합성 모델로 별도 표에 넣었습니다. |
| import 호환 모델 추가 | `Qwen/Qwen3.6-35B-A3B`, `Qwen/Qwen3.5-9B`, `google/gemma-4-31B-it`가 import 호환 모델에 추가되었습니다. | 2026-05-11 | imported model 권장 DAC 표에 넣었습니다. |
| 신규 모델 | `cohere.rerank-v4.0-pro`, `cohere.rerank-v4.0-fast`가 Cohere Rerank 4.0으로 확인됩니다. | 2026-05-09 | 전용 DAC `RERANK_COHERE x1`로 넣었습니다. release notes는 on-demand와 dedicated를 함께 언급하지만, 개별 모델 페이지는 dedicated only라고 설명하므로 mode는 문서 간 상충으로 표시했습니다. |
| 기능 확장 | Cohere Embed 4가 configurable output dimensions와 text+image `EmbedText` payload를 지원합니다. | 2026-05-09 | 임베딩 모델 강점과 DAC 표에 반영했습니다. |
| 리전 추가 | OCI Generative AI가 UAE Central (Abu Dhabi) 리전에서 사용 가능해졌습니다. | 2026-05-05 | 서비스 가용성 표에 넣었습니다. 다만 A10/A100/H100/H200 전용 DAC 공개표에는 확인되지 않아 `문서상 미확인`으로 표시했습니다. |
| retired / replacement | Oracle retirement 문서 기준으로 Grok 3 계열과 일부 구형 Cohere / Meta 모델은 신규 설계에서 우선 제외하는 편이 안전합니다. | 2026-05-19 확인 | retired / deprecated 메모와 빠른 추천에서 제외했습니다. |
| 대표 리전 GPU 조회 | 대표 리전의 IaaS GPU shape 조회가 성공했습니다. | 2026-05-19 | IaaS/AQUA 해석 표에 반영했습니다. |
| AI catalog 공개 JSON | 43개 리전 행을 포함한 공개 스냅샷을 생성했습니다. | 2026-05-19 | GitHub Pages catalog UI에서 리전별 모델/shape 가시성과 조회 상태를 표로 확인할 수 있습니다. |
핵심 변화는 `Cohere Rerank 4.0`, `Cohere Embed 4 기능 확장`, `xAI Voice`, `Abu Dhabi 리전`, `import 호환 모델 3개 추가`, `대표 리전 GPU 조회 성공 결과 반영`, `AI catalog 공개 JSON 생성`입니다.

## 2026-05-18 (v3)

[OCI_GenAI_Regional_Model_Guide_v3_2026-05-18.md](guides/OCI_GenAI_Regional_Model_Guide_v3_2026-05-18.md)

| 구분 | 변화 | 기준일 | 이 문서의 반영 |
|---|---|---:|---|
| 신규 모델 | `xai.grok-tts` 기반 xAI Voice Text to Speech가 추가되었습니다. | 2026-05-15 | 음성 합성 모델로 별도 표에 넣었습니다. |
| import 호환 모델 추가 | `Qwen/Qwen3.6-35B-A3B`, `Qwen/Qwen3.5-9B`, `google/gemma-4-31B-it`가 import 호환 모델에 추가되었습니다. | 2026-05-11 | imported model 권장 DAC 표에 넣었습니다. |
| 신규 모델 | `cohere.rerank-v4.0-pro`, `cohere.rerank-v4.0-fast`가 Cohere Rerank 4.0으로 확인됩니다. | 2026-05-09 | 전용 DAC `RERANK_COHERE x1`로 넣었습니다. release notes는 on-demand와 dedicated를 함께 언급하지만, 개별 모델 페이지는 dedicated only라고 설명하므로 mode는 문서 간 상충으로 표시했습니다. |
| 기능 확장 | Cohere Embed 4가 configurable output dimensions와 text+image `EmbedText` payload를 지원합니다. | 2026-05-09 | 임베딩 모델 강점과 DAC 표에 반영했습니다. |
| 리전 추가 | OCI Generative AI가 UAE Central (Abu Dhabi) 리전에서 사용 가능해졌습니다. | 2026-05-05 | 서비스 가용성 표에 넣었습니다. 다만 A10/A100/H100/H200 전용 DAC 공개표에는 확인되지 않아 `문서상 미확인`으로 표시했습니다. |
| retired / replacement | Oracle retirement 문서 기준으로 Grok 3 계열과 일부 구형 Cohere / Meta 모델은 신규 설계에서 우선 제외하는 편이 안전합니다. | 2026-05-18 확인 | retired / deprecated 메모와 빠른 추천에서 제외했습니다. |
| 대표 리전 GPU 조회 | 대표 리전의 IaaS GPU shape 조회가 성공했습니다. | 2026-05-18 | IaaS/AQUA 해석 표에 반영했습니다. |
핵심 변화는 `Cohere Rerank 4.0`, `Cohere Embed 4 기능 확장`, `xAI Voice`, `Abu Dhabi 리전`, `import 호환 모델 3개 추가`, `대표 리전 GPU 조회 성공 결과 반영`입니다.

## 2026-05-18 (v2)

[OCI_GenAI_Regional_Model_Guide_v2_2026-05-18.md](guides/OCI_GenAI_Regional_Model_Guide_v2_2026-05-18.md)

| 구분 | 변화 | 기준일 | 이 문서의 반영 |
|---|---|---:|---|
| 신규 모델 | `xai.grok-tts` 기반 xAI Voice Text to Speech가 추가되었습니다. | 2026-05-15 | 음성 합성 모델로 별도 표에 넣었습니다. |
| import 호환 모델 추가 | `Qwen/Qwen3.6-35B-A3B`, `Qwen/Qwen3.5-9B`, `google/gemma-4-31B-it`가 import 호환 모델에 추가되었습니다. | 2026-05-11 | imported model 권장 DAC 표에 넣었습니다. |
| 신규 모델 | `cohere.rerank-v4.0-pro`, `cohere.rerank-v4.0-fast`가 Cohere Rerank 4.0으로 확인됩니다. | 2026-05-09 | 전용 DAC `RERANK_COHERE x1`로 넣었습니다. release notes는 on-demand와 dedicated를 함께 언급하지만, 개별 모델 페이지는 dedicated only라고 설명하므로 mode는 문서 간 상충으로 표시했습니다. |
| 기능 확장 | Cohere Embed 4가 configurable output dimensions와 text+image `EmbedText` payload를 지원합니다. | 2026-05-09 | 임베딩 모델 강점과 DAC 표에 반영했습니다. |
| 리전 추가 | OCI Generative AI가 UAE Central (Abu Dhabi) 리전에서 사용 가능해졌습니다. | 2026-05-05 | 서비스 가용성 표에 넣었습니다. 다만 A10/A100/H100/H200 전용 DAC 공개표에는 확인되지 않아 `문서상 미확인`으로 표시했습니다. |
| retired / replacement | Oracle retirement 문서 기준으로 Grok 3 계열과 일부 구형 Cohere / Meta 모델은 신규 설계에서 우선 제외하는 편이 안전합니다. | 2026-05-18 확인 | retired / deprecated 메모와 빠른 추천에서 제외했습니다. |
| 대표 리전 GPU 조회 | 대표 리전의 IaaS GPU shape 조회가 성공했습니다. | 2026-05-18 | IaaS/AQUA 해석 표에 반영했습니다. |
핵심 변화는 `Cohere Rerank 4.0`, `Cohere Embed 4 기능 확장`, `xAI Voice`, `Abu Dhabi 리전`, `import 호환 모델 3개 추가`, `대표 리전 GPU 조회 성공 결과 반영`입니다.

## 2026-05-17 (v2)

[OCI_GenAI_Regional_Model_Guide_v2_2026-05-17.md](guides/OCI_GenAI_Regional_Model_Guide_v2_2026-05-17.md)

- `2026-05-15` 기준 Oracle release notes에 `xAI Voice (Text to Speech)`가 추가되었습니다. 이 문서는 GPU/DAC 비교 중심이므로 본문 표에는 참고 항목으로만 넣었습니다.
- `2026-05-11` 기준 Oracle release notes에 OCI Generative AI import 호환 모델이 추가되었습니다.
  - `Qwen/Qwen3.6-35B-A3B`
  - `Qwen/Qwen3.5-9B`
  - `google/gemma-4-31B-it`
- `2026-05-09` 기준 Oracle release notes에 `Cohere Rerank 4.0 Pro`와 `Cohere Rerank 4.0 Fast`가 추가되었습니다. 따라서 이번 문서부터 `재정렬` 표와 `DAC 중심 모델` 표에 Rerank 4.0 계열을 반영했습니다.
- `2026-05-09` 기준 Oracle release notes에 `Cohere Embed 4`의 새 기능이 추가되었습니다.
  - configurable embedding dimensions
  - `EmbedText` API에서 텍스트와 이미지를 하나의 payload로 함께 처리
- `2026-05-05` 기준 Oracle release notes에 `UAE Central (Abu Dhabi)` 리전의 OCI Generative AI 가용성이 추가되었습니다.
- `2026-05-01` 기준 Oracle release notes와 개별 모델 페이지에 `xAI Grok 4.3`가 추가되었습니다.
- `Models by Region` 기준으로 `UAE Central (Abu Dhabi)`에는 이미 일부 관리형 기본 모델의 dedicated 표기가 보이지만, `Dedicated Cluster Shapes by Region` 쪽에는 아직 Abu Dhabi 전용 A10/A100/H100/H200 하드웨어 표가 명시적으로 보이지 않습니다. 이번 확인 범위에서는 `Cohere Rerank 4.0` 전용 dedicated regional shape 표도 같은 페이지에 아직 명시적으로 반영되지 않았습니다.
- retirement/deprecation 관련 문서는 이번 기준에서도 계속 중요합니다.
  - 신규 설계에서 우선 제외할 대상: `Cohere Command R+`, `Cohere Command R 16K`, `Cohere Command (52B)`, `Cohere Command Light`, `Meta Llama 3.1 70B`, `Meta Llama 3 70B`, `Meta Llama 2 70B`
  - 대체 방향이 명시된 주요 축: `Meta Llama 4 Maverick/Scout`, `Cohere Command A`, `Cohere Embed 4`, `xAI Grok 4.3`
- `xAI Grok 3`, `xAI Grok 3 Mini`, `xAI Grok 3 Fast`, `xAI Grok 3 Mini Fast`는 Oracle의 on-demand retirement 표에서 `xAI Grok 4.3` 대체 대상으로 정리되어 있습니다.
- CLI 실조회는 이번에도 성공하지 못했습니다.
  - `region-subscription list`: 실패
  - `compute shape list`: 실패
  - `os ns get`: 실패
  - 공통 관찰: `--debug` 기준으로 Identity / IaaS / Object Storage endpoint에 대한 GET 요청만 4회가량 반복되었고, HTTP status나 응답 본문을 받기 전에 로컬 `timeout`으로 종료되었습니다.
  - 따라서 `IaaS/AQUA GPU 재고표`는 실테넌시 live inventory가 아니라 Oracle 문서 기준 해석표로 대체했습니다.

## 2026-05-10 (v2)

[OCI_GenAI_Regional_Model_Guide_v2_2026-05-10.md](guides/OCI_GenAI_Regional_Model_Guide_v2_2026-05-10.md)

- `2026-05-05` 기준 Oracle release notes에 `UAE Central (Abu Dhabi)` 리전의 OCI Generative AI 가용성이 추가되었습니다.
- `2026-05-01` 기준 Oracle release notes와 개별 모델 페이지에 `xAI Grok 4.3`가 추가되었습니다.
- `Models by Region` 기준으로 `UAE Central (Abu Dhabi)`에는 이미 일부 관리형 기본 모델의 dedicated 표기가 보이지만, `Dedicated Cluster Shapes by Region` 쪽에는 아직 Abu Dhabi 전용 A10/A100/H100/H200 하드웨어 표가 명시적으로 보이지 않습니다. 따라서 이 문서의 `DAC A10/A100/H100/H200 가시성` 표에서는 Abu Dhabi를 `문서상 미확인`으로 유지했습니다.
- retirement/deprecation 관련 문서는 이번 기준에서도 계속 중요합니다.
  - 신규 설계에서 우선 제외할 대상: `Cohere Command R+`, `Cohere Command R 16K`, `Cohere Command (52B)`, `Cohere Command Light`, `Meta Llama 3.1 70B`, `Meta Llama 3 70B`, `Meta Llama 2 70B`
  - 대체 방향이 명시된 주요 축: `Meta Llama 4 Maverick/Scout`, `Cohere Command A`, `Cohere Embed 4`, `xAI Grok 4.3`
- `xAI Grok 3`, `xAI Grok 3 Mini`, `xAI Grok 3 Fast`, `xAI Grok 3 Mini Fast`는 Oracle의 on-demand retirement 표에서 `xAI Grok 4.3` 대체 대상으로 정리되어 있습니다.
- CLI 실조회는 이번에도 성공하지 못했습니다.
  - `region-subscription list`: 실패
  - `compute shape list`: 실패
  - `os ns get`: 실패
  - 공통 관찰: 인증 오류 응답까지 가지 못하고 OCI endpoint GET 재시도만 반복되다가 로컬 `timeout`으로 종료되었습니다.
  - 따라서 `IaaS/AQUA GPU 재고표`는 실테넌시 live inventory가 아니라 Oracle 문서 기준 해석표로 대체했습니다.

## 2026-05-03 (v2)

[OCI_GenAI_Regional_Model_Guide_v2_2026-05-03.md](guides/OCI_GenAI_Regional_Model_Guide_v2_2026-05-03.md)

- `2026-05-03` 확인 기준, Oracle `Models by Region` 페이지에 `xAI Grok 4.3`가 반영되어 있습니다.
- `2026-03-24` 기준, Oracle release notes에 `xAI Grok 4.20`과 `xAI Grok 4.20 Multi-Agent` 추가가 반영되어 있습니다.
- `2026-03-11` 기준, imported model 계열 문서와 release notes에 `Qwen 3 Embedding`과 `NVIDIA Nemotron` 계열 확장이 반영되어 있습니다.
- `2026-03-04` 기준, 관리형 `OpenAI gpt-oss` 전용 DAC 가시성이 `UAE East (Dubai)`, `Saudi Arabia Central (Riyadh)`, `US West (Phoenix)`까지 확대되어 있습니다.
- retired/deprecated 관점에서 신규 설계에서 먼저 제외할 모델군은 여전히 분명합니다.
  - retired: `Cohere Command R+`, `Cohere Command R 16K`, `Cohere Command (52B)`, `Cohere Command Light`, `Meta Llama 3.1 70B`, `Meta Llama 3 70B`
  - retirement window 주의: `Cohere Embed English Light 3`, `Cohere Embed Multilingual Light 3`는 dedicated 문서에서 `No sooner than 2026-03-29`로 표시됩니다.
- OCI Compute 문서에는 `MI300X`, `MI355X`, `B200`, `GB200`, `GB300` 같은 더 새로운 GPU 계열도 보이지만, Oracle Generative AI 관리형 DAC 문서와 imported model 권장 unit 표는 이번 기준에서도 `A10/A100/H100/H200` 축이 중심입니다.
- 이번 문서 생성 시 OCI CLI 자동 조회는 성공하지 못했습니다.
  - `region-subscription list`: 실패
  - `compute shape list`: 실패
  - `os ns get`: 실패
  - 공통 관찰: 인증 오류 메시지보다 먼저 OCI endpoint 요청이 반복되다가 로컬 타임아웃으로 종료되었습니다.
  - 따라서 `IaaS/AQUA GPU 재고표`는 실테넌시 live inventory가 아니라 Oracle 문서 기준 해석표로 대체했습니다.

## 2026-04-26 (v2)

[OCI_GenAI_Regional_Model_Guide_v2_2026-04-26.md](guides/OCI_GenAI_Regional_Model_Guide_v2_2026-04-26.md)

- `2026-03-24` 기준, Oracle release notes에 `xAI Grok 4.20`과 `xAI Grok 4.20 Multi-Agent` 추가가 반영되었습니다.
- `2026-03-04` 기준, 관리형 `OpenAI gpt-oss` 전용 DAC 가시성이 `UAE East (Dubai)`, `Saudi Arabia Central (Riyadh)`, `US West (Phoenix)`까지 확대되었습니다.
- `2026-02-26` 기준, `Cohere Embed 4` 온디맨드 지원 리전에 `US East (Ashburn)`, `Saudi Arabia Central (Riyadh)`가 추가되었습니다.
- `2026-01-21` 전후 기준, Oracle이 `Models by Region` / `Dedicated Cluster Shapes by Region` 페이지를 별도로 제공하기 시작했고, `Cohere Command A Vision`, `Cohere Command A Reasoning`, `xAI Grok 4.1 Fast`가 현재 문서 체계에 반영되었습니다.
- retired/deprecated 관점에서 신규 설계에서 먼저 제외할 모델군은 여전히 분명합니다.
  - retired: `Cohere Command R+`, `Cohere Command R 16K`, `Cohere Command (52B)`, `Cohere Command Light`, `Meta Llama 3.1 70B`, `Meta Llama 3 70B`
  - dedicated retirement window 주의: `Cohere Embed English Light 3`, `Cohere Embed Multilingual Light 3`는 Oracle 문서상 dedicated retirement date가 `No sooner than 2026-03-29`로 표시됩니다.
- 이번 문서 생성 시 OCI CLI 자동 조회는 성공하지 못했습니다.
  - `region-subscription list`: 실패
  - `compute shape list`: 실패
  - 보조 연결 확인용 `oci os ns get`: 실패
  - 실패 원인은 `권한 부족`이 아니라 `endpoint connection timeout`으로 관찰되었고, 따라서 `IaaS/AQUA 리전별 실제 GPU 재고`는 Oracle 문서 기준 해석표로 대체했습니다.

## 2026-04-19 (v2)

[OCI_GenAI_Regional_Model_Guide_v2_2026-04-19.md](guides/OCI_GenAI_Regional_Model_Guide_v2_2026-04-19.md)

- `2026-03-04` 기준, OpenAI `gpt-oss` 전용 DAC 가시성이 `UAE East (Dubai)`, `Saudi Arabia Central (Riyadh)`, `US West (Phoenix)`로 확장되었습니다.
- `2026-02-26` 기준, `Cohere Embed 4` 온디맨드가 `US East (Ashburn)`, `Saudi Arabia Central (Riyadh)`로 확대되었습니다.
- `2026-01-21` 기준, Oracle이 `Models by Region` / `Dedicated Cluster Shapes by Region` 페이지를 별도로 제공하기 시작해 리전별 판정 근거가 더 명확해졌습니다.
- 현재 기준 retired/deprecated 관점에서 신규 설계에서 먼저 제외해야 할 모델군이 분명해졌습니다.
  - retired: `Cohere Command R+`, `Cohere Command R 16K`, `Cohere Command (52B)`, `Cohere Command Light`, `Meta Llama 3.1 70B`, `Meta Llama 3 70B`
  - dedicated retirement window 경과 주의: `Cohere Embed English Light 3`, `Cohere Embed Multilingual Light 3`는 Oracle 문서상 dedicated retirement date가 `No sooner than 2026-03-29`로 표시됩니다.
- 이번 문서 생성 시 OCI CLI 자동 조회는 성공하지 못했습니다.
  - `region-subscription list`: 타임아웃
  - `compute shape list`: 타임아웃
  - 따라서 `IaaS/AQUA 리전별 실제 GPU 재고`는 문서 기준 해석표로 대체했습니다.

## 2026-04-17 (v2)

[OCI_GenAI_Regional_Model_Guide_v2_2026-04-17.md](guides/OCI_GenAI_Regional_Model_Guide_v2_2026-04-17.md)

- 변화 요약 섹션을 찾지 못했습니다.
