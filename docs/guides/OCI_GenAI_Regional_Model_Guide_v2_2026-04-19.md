# OCI Generative AI / DAC / AQUA / IaaS GPU 리전·모델 가이드 v2

최종 업데이트: 2026-04-19 (GMT)  
정리 기준: Oracle 공식 문서 우선 + OCI CLI 실조회 시도 결과

이 문서는 `LATEST.md`로 복사될 수 있음을 고려해, 앞부분 1페이지 안에 핵심 변화와 현재 판정 기준을 먼저 배치했습니다.

---

## 이번 업데이트 변화 요약

- `2026-03-04` 기준, OpenAI `gpt-oss` 전용 DAC 가시성이 `UAE East (Dubai)`, `Saudi Arabia Central (Riyadh)`, `US West (Phoenix)`로 확장되었다.
- `2026-02-26` 기준, `Cohere Embed 4` 온디맨드가 `US East (Ashburn)`, `Saudi Arabia Central (Riyadh)`로 확대되었다.
- `2026-01-21` 기준, Oracle이 `Models by Region` / `Dedicated Cluster Shapes by Region` 페이지를 별도로 제공하기 시작해 리전별 판정 근거가 더 명확해졌다.
- 현재 기준 retired/deprecated 관점에서 신규 설계에서 먼저 제외해야 할 모델군이 분명해졌다.
  - retired: `Cohere Command R+`, `Cohere Command R 16K`, `Cohere Command (52B)`, `Cohere Command Light`, `Meta Llama 3.1 70B`, `Meta Llama 3 70B`
  - dedicated retirement window 경과 주의: `Cohere Embed English Light 3`, `Cohere Embed Multilingual Light 3`는 Oracle 문서상 dedicated retirement date가 `No sooner than 2026-03-29`로 표시된다.
- 이번 문서 생성 시 OCI CLI 자동 조회는 성공하지 못했다.
  - `region-subscription list`: 타임아웃
  - `compute shape list`: 타임아웃
  - 따라서 `IaaS/AQUA 리전별 실제 GPU 재고`는 문서 기준 해석표로 대체했다.

---

## 0. 먼저 보는 전제

### 0-1. 용어

- `Generative AI`: OCI Generative AI 관리형 서비스
- `DAC`: Dedicated AI Cluster
- `AQUA`: OCI Data Science AI Quick Actions
- `IaaS GPU`: OCI Compute/Data Science에서 직접 쓰는 GPU shape

### 0-2. 문서 해석 원칙

- Oracle 문서에 있는 사실만 확정적으로 썼다.
- Oracle 문서에 없는 리전별 고정 재고표는 `없음`으로 적었다.
- 관리형 기본 모델용 DAC unit과 imported model용 GPU unit을 구분했다.
- `LARGE_COHERE_V3`, `LARGE_GENERIC_V2` 같은 일부 DAC unit은 Oracle 문서가 하드웨어 구성을 고객에게 숨긴다고 밝히므로, GPU 메모리를 단정하지 않았다.

---

## 1. CLI 조회 상태

### 1-1. 실행 상태 표

| 조회 항목 | 실행 명령 | 상태 | 비고 |
|---|---|---|---|
| 구독 리전 조회 | `oci iam region-subscription list --all` | 실패 | 20초, 60초 타임아웃 재시도 모두 실패 |
| GPU shape 조회 | `oci compute shape list --all -c <tenancy_ocid>` | 실패 | `ap-seoul-1`, `us-ashburn-1` 모두 타임아웃 |

### 1-2. 실패 이유

| 항목 | 관찰 내용 | 문서 반영 방식 |
|---|---|---|
| `region-subscription list` | Identity endpoint로 요청은 나가지만 응답이 타임아웃 안에 돌아오지 않음 | Oracle 리전 문서 기준 표로 대체 |
| `compute shape list` | IaaS endpoint로 요청은 나가지만 응답이 타임아웃 안에 돌아오지 않음 | Compute/Data Science shape 문서 + 해석표로 대체 |

실무 메모:

- 이번 실행에서는 `권한 부족(NotAuthorizedOrNotFound)`보다 `API 응답 타임아웃`이 먼저 확인되었다.
- 따라서 이 문서의 `IaaS/AQUA 리전별 재고`는 실제 테넌시 live inventory가 아니라 Oracle 공식 문서 기준 해석이다.

---

## 2. 리전별 Generative AI / DAC / AQUA 지원

### 2-1. 상용 리전

| 권역 | 리전 | Generative AI | DAC | AQUA | 비고 |
|---|---|---|---|---|---|
| SA | Brazil East (Sao Paulo) | 지원 | 지원(모델별) | 지원 | 상용 리전 |
| EU | Germany Central (Frankfurt) | 지원 | 지원(모델별) | 지원 | 상용 리전 |
| AP | India South (Hyderabad) | 지원 | 지원(모델별) | 지원 | 상용 리전 |
| AP | Japan Central (Osaka) | 지원 | 지원(모델별) | 지원 | 상용 리전 |
| ME | Saudi Arabia Central (Riyadh) | 지원 | 지원(모델별) | 지원 | 상용 리전 |
| ME | UAE East (Dubai) | 지원 | 지원(모델별) | 지원 | 상용 리전 |
| EU | UK South (London) | 지원 | 지원(모델별) | 지원 | 상용 리전 |
| NA | US East (Ashburn) | 지원 | 지원(모델별) | 지원 | 상용 리전 |
| NA | US Midwest (Chicago) | 지원 | 지원(모델별) | 지원 | 상용 리전 |
| NA | US West (Phoenix) | 지원 | 지원(모델별) | 지원 | 상용 리전 |

### 2-2. 정부 / 소버린 리전

| 권역 | 리전 | Generative AI | DAC | AQUA | 비고 |
|---|---|---|---|---|---|
| GOV | UK Gov South (London) | 지원 | 지원(모델별) | 지원 | AQUA는 정부 리전 지원 문서 존재 |
| SOV | EU Sovereign Central (Frankfurt) | 지원 | 지원(모델별) | Oracle 문서상 명시 없음 | AQUA sovereign 지원 여부는 본 문서 기준 미확인 |

정리:

- Generative AI 서비스 자체는 Oracle의 공식 리전 문서에 위 12개 리전이 명시된다.
- AQUA는 Oracle 문서상 `all commercial and government regions` 지원이다.
- AQUA의 sovereign 리전 지원은 이번 기준 문서에서 확인하지 못했다.

---

## 3. 리전별 DAC A10 / A100 / H100 / H200 가시성

판정 기준:

- 이 표는 Oracle의 `OpenAI gpt-oss-20b / 120b` 모델 카드와 `Dedicated Cluster Shapes by Region` 페이지에서 확인되는 DAC hardware unit만 사용했다.
- 즉, `OAI_*` unit이 Oracle 문서에 드러난 리전만 `가시성 있음`으로 기록했다.
- 다른 관리형 모델의 `LARGE_COHERE_*`, `LARGE_GENERIC_*`는 GPU 종류가 고객에게 공개되지 않으므로 여기서는 A/H 계열 가시성 판정에 쓰지 않았다.

### 3-1. 상용 리전

| 리전 | A10 | A100 40G | A100 80G | H100 | H200 | 메모 |
|---|---|---|---|---|---|---|
| Sao Paulo | - | - | - | 예 | - | `gpt-oss`는 H100 계열 |
| Frankfurt | 예 | - | - | 예 | - | `20b`는 A10 또는 H100 |
| Hyderabad | - | - | - | 예 | - | H100 계열 |
| Osaka | - | - | - | 예 | - | H100 계열 |
| Riyadh | - | - | - | - | 예 | H200 계열 |
| Dubai | 예 | 예 | - | - | - | A10 / A100 40G 계열 |
| London | - | - | - | 예 | - | H100 계열 |
| Ashburn | 예 | - | - | 예 | - | `20b`는 A10 또는 H100 |
| Chicago | 예 | - | 예 | 예 | - | A10 / A100 80G / H100 공존 |
| Phoenix | - | - | 예 | - | - | A100 80G 계열 |

### 3-2. 정부 / 소버린 리전

| 리전 | A10 | A100 40G | A100 80G | H100 | H200 | 메모 |
|---|---|---|---|---|---|---|
| UK Gov South | - | - | - | 예 | - | `gpt-oss`는 H100 계열만 문서 확인 |
| EU Sovereign Central | 예 | - | - | 예 | - | `20b`는 A10 또는 H100, `120b`는 H100 |

요약:

- 관리형 `gpt-oss` 기준으로 가장 넓게 보이는 계열은 `H100`이다.
- `H200`은 이번 기준에서 `Riyadh`의 `gpt-oss` 전용 DAC에서만 공식 확인된다.
- `A100 80G`는 `Chicago`, `Phoenix`에서 공식 확인된다.
- `A100 40G`는 `Dubai`에서 공식 확인된다.

---

## 4. IaaS GPU shape 조회 명령과 결과 해석법

### 4-1. 조회 명령

```bash
oci iam region-subscription list --all \
  --query 'data[]."region-name"' \
  --raw-output
```

```bash
oci --region <region> compute shape list --all \
  -c <tenancy_or_compartment_ocid> \
  --query 'data[?contains(shape, `GPU`)].{shape:shape,gpus:gpus,"gpu-desc":"gpu-description",memory:"memory-in-gbs",ocpus:ocpus}' \
  --output table
```

### 4-2. 이번 실행의 해석

- 명령 자체는 유효하다.
- 이번 환경에서는 두 명령 모두 타임아웃으로 자동 수집에 실패했다.
- 따라서 이 문서의 IaaS/AQUA 리전 표는 아래 `shape-to-GPU 매핑`과 `Data Science supported shapes` 문서로 읽어야 한다.

### 4-3. 결과 해석법

| CLI에 보이는 shape | 해석 |
|---|---|
| `VM.GPU3.*`, `BM.GPU3.8` | V100 계열 |
| `VM.GPU.A10.*`, `BM.GPUA10.4` | A10 계열 |
| `BM.GPU4.8` | A100 40GB 계열 |
| `BM.GPU.A100-v2.8` | A100 80GB 계열 |
| `BM.GPU.H100.8` | H100 계열 |
| `BM.GPU.H200.8` | H200 계열 |
| `BM.GPU.L40S-NC.4` | L40S 계열 |

---

## 5. shape-to-GPU 매핑

### 5-1. Compute / Data Science 공통 해석 표

| Shape | GPU | GPU 수 | 총 GPU 메모리 | OCPU | CPU 메모리 |
|---|---|---:|---:|---:|---:|
| `VM.GPU3.1` | V100 | 1 | 16 GB | 6 | 90 GB |
| `VM.GPU3.2` | V100 | 2 | 32 GB | 12 | 180 GB |
| `VM.GPU3.4` | V100 | 4 | 64 GB | 24 | 360 GB |
| `BM.GPU3.8` | V100 | 8 | 128 GB | 52 | 768 GB |
| `VM.GPU.A10.1` | A10 | 1 | 24 GB | 15 | 240 GB |
| `VM.GPU.A10.2` | A10 | 2 | 48 GB | 30 | 480 GB |
| `BM.GPUA10.4` | A10 | 4 | 96 GB | 64 | 1024 GB |
| `BM.GPU4.8` | A100 | 8 | 320 GB | 64 | 2048 GB |
| `BM.GPU.A100-v2.8` | A100 | 8 | 640 GB | 64 | 2048 GB |
| `BM.GPU.H100.8` | H100 | 8 | 640 GB | 112 | 2048 GB |
| `BM.GPU.H200.8` | H200 | 8 | 1128 GB | 112 | 3072 GB |
| `BM.GPU.L40S-NC.4` | L40S | 4 | 192 GB | 112 | 1024 GB |

### 5-2. 메모리 환산 규칙

| 계열 | GPU당 메모리 | 예시 |
|---|---:|---|
| A10 | 24 GB | `A10_X2` = 48 GB |
| A100 40G | 40 GB | `A100_40G_X4` = 160 GB |
| A100 80G | 80 GB | `A100_80G_X2` = 160 GB |
| H100 | 80 GB | `H100_X4` = 320 GB |
| H200 | 141 GB | `H200_X2` = 282 GB |

---

## 6. IaaS / AQUA GPU 재고표

### 6-1. Oracle 문서상 지원 shape 재고표

| 계열 | IaaS Compute shape 예 | Data Science / AQUA shape 예 | Oracle의 리전별 고정 재고표 |
|---|---|---|---|
| V100 | `VM.GPU3.*`, `BM.GPU3.8` | 지원 | 없음 |
| A10 | `VM.GPU.A10.*`, `BM.GPUA10.4` | 지원 | 없음 |
| A100 40G | `BM.GPU4.8` | 지원 | 없음 |
| A100 80G | `BM.GPU.A100-v2.8` | 지원 | 없음 |
| H100 | `BM.GPU.H100.8` | 지원 | 없음 |
| H200 | `BM.GPU.H200.8` | 지원 | 없음 |
| L40S | `BM.GPU.L40S-NC.4` | 지원 | 없음 |

### 6-2. 리전별 판정 규칙

| 항목 | Oracle 문서 상태 | 이 문서의 처리 방식 |
|---|---|---|
| IaaS GPU per-region 고정표 | 없음 | CLI 실조회가 성공하면 그 결과를 우선, 실패 시 `없음`으로 유지 |
| AQUA per-region GPU 고정표 | 없음 | Data Science 지원 shape + 한도/용량/예약 주의사항으로 해석 |
| 실제 생성 가능 여부 | 문서만으로 확정 불가 | 서비스 한도 + host capacity + reservation 필요 여부를 함께 확인 |

### 6-3. 실무 해석표

| 계열 | 실무 메모 |
|---|---|
| A10 | 일부 리전에서는 reservation 없이도 가능한 경우가 있다고 Oracle 문서가 설명 |
| A100 | reservation이 필요한 경우가 많고, Data Science 예약 수용도 특정 리전에 한정될 수 있음 |
| H100 | host capacity 영향이 크며 reservation 검토가 현실적 |
| H200 | 지원 shape는 문서에 있으나 per-region 고정표는 없음 |
| L40S | Oracle 문서상 reservation이 필요한 경우가 많다고 보는 편이 안전 |

중요:

- `AQUA = Data Science GPU shape 활용`으로 이해하는 것이 안전하다.
- Oracle 문서상 `service limit`과 `shape capacity`는 다르다.
- limit이 있어도 `Out of host capacity`가 날 수 있다.

---

## 7. 온디맨드 핵심 모델 표

### 7-1. 범용 / 멀티모달 / 추론

| 모델 ID | 유형 | 컨텍스트 | 온디맨드 | 파인튜닝 | 핵심 강점 |
|---|---|---|---|---|---|
| `cohere.command-a-03-2025` | 범용 chat/agent | 256k | 예 | 불가 | RAG, tool use, 멀티링구얼 |
| `cohere.command-a-vision` | 멀티모달 | 128k | 예 | 불가 | 문서·차트·이미지 해석 |
| `cohere.command-a-reasoning` | 고난도 reasoning | 256k | 문서상 리전별 상이 | 불가 | 복합 추론, 구조화 논증 |
| `meta.llama-4-scout-17b-16e-instruct` | 멀티모달 | 192k | Chicago | 불가 | 작은 GPU footprint, 긴 문맥 |
| `meta.llama-4-maverick-17b-128e-instruct-fp8` | 멀티모달 | 512k | Chicago | 불가 | 코딩/추론, 초장문 문맥 |
| `openai.gpt-oss-20b` | text reasoning | 128k | 예 | 불가 | 빠른 반복, 코딩, STEM |
| `openai.gpt-oss-120b` | text reasoning | 128k | 예 | 불가 | production급 reasoning |

### 7-2. 임베딩 / 외부 플랫폼 / 코딩 특화

| 모델 ID | 유형 | 컨텍스트 | 온디맨드 | 파인튜닝 | 핵심 강점 |
|---|---|---|---|---|---|
| `cohere.embed-v4.0` | 임베딩 | 입력 총합 128k | 예 | 불가 | 텍스트/이미지 임베딩, 1536-d |
| `google.gemini-2.5-pro` | 멀티모달 reasoning | 1M | 예 | 불가 | 복잡한 문제 해결, 대형 입력 |
| `google.gemini-2.5-flash` | 멀티모달 fast reasoning | 1M | 예 | 불가 | 속도/지능 균형 |
| `google.gemini-2.5-flash-lite` | 멀티모달 경량 | 1M | 예 | 불가 | 저비용, 대량 처리 |
| `xai.grok-code-fast-1` | 코딩 agent | 256k | 예 | 불가 | agentic coding, tool-use |

메모:

- Gemini 계열은 Oracle 문서상 온디맨드 전용이다.
- xAI Grok 계열도 Oracle 문서상 온디맨드 전용이다.
- Google 모델은 OCI Generative AI를 통해 접근하지만 Oracle 문서상 `external calls` 설명이 있다.

---

## 8. DAC 중심 모델 표

### 8-1. 현재 설계에서 자주 보는 DAC 호스팅 모델

| 모델 ID | 호스팅 DAC unit | 지역 특이사항 | 파인튜닝 | 메모 |
|---|---|---|---|---|
| `cohere.command-a-03-2025` | `LARGE_COHERE_V3 x1` | Dubai는 `SMALL_COHERE_4 x1` | 불가 | 범용 관리형 chat |
| `cohere.command-a-vision` | `LARGE_COHERE_V3 x1` | Dubai는 `SMALL_COHERE_4 x1` | 불가 | 멀티모달 |
| `cohere.command-a-reasoning` | `LARGE_COHERE_V2_2 x1` | Dubai는 `SMALL_COHERE_4 x1` | 불가 | reasoning 중심 |
| `cohere.embed-v4.0` | `EMBED_COHERE x1` | 리전별 온디맨드/전용 다름 | 불가 | 임베딩 전용 |
| `cohere.rerank.v3-5` | `RERANK_COHERE x1` | DAC 중심 | 불가 | 검색 후 재정렬 |
| `meta.llama-4-scout-17b-16e-instruct` | `LARGE_GENERIC_V2 x1` | Chicago on-demand, 그 외는 전용 위주 | 불가 | 작은 footprint |
| `meta.llama-4-maverick-17b-128e-instruct-fp8` | `LARGE_GENERIC_2 x1` | Chicago on-demand, 타 리전은 전용 위주 | 불가 | 512k 컨텍스트 |
| `openai.gpt-oss-20b` | 리전별 `OAI_A10_X2 / OAI_A100_40G_X1 / OAI_A100_80G_X1 / OAI_H100_X1 / OAI_H200_X1` | 리전별 하드웨어 편차 큼 | 불가 | 공개된 GPU 계열이 가장 명확 |
| `openai.gpt-oss-120b` | 리전별 `OAI_A100_40G_X4 / OAI_A100_80G_X2 / OAI_H100_X2 / OAI_H200_X1` | 리전별 하드웨어 편차 큼 | 불가 | 고난도 reasoning |

### 8-2. 파인튜닝 가능한 베이스 모델

| 베이스 모델 | 현재 상태 | 학습 방식 | 비고 |
|---|---|---|---|
| `meta.llama-3.3-70b-instruct` | 가능 | LoRA | Oracle fine-tuning method 문서 기준 |
| `cohere.command-r-08-2024` | 가능 | T-Few, LoRA | Oracle fine-tuning method 문서 기준 |
| `meta.llama-3.1-70b-instruct` | retired 반영 필요 | LoRA | 과거 지원 모델, 신규 설계 대상 아님 |
| `cohere.command-r-16k` | retired 반영 필요 | T-Few, LoRA | 과거 지원 모델, 신규 설계 대상 아님 |

---

## 9. DAC 유닛별 배포 필요 GPU 메모리 표

중요:

- 아래 9-1 표는 `A10/A100/H100/H200`처럼 이름만으로 GPU 메모리를 계산할 수 있는 unit만 넣었다.
- 아래 9-2 표는 Oracle이 하드웨어를 숨기는 unit이다. GPU 메모리를 Oracle 공식 문서만으로는 단정할 수 없다.

### 9-1. GPU 메모리를 계산할 수 있는 DAC unit

| DAC unit | GPU 해석 | 총 GPU 메모리 |
|---|---|---:|
| `A10_X1` | 1x A10 | 24 GB |
| `A10_X2` | 2x A10 | 48 GB |
| `A10_X4` | 4x A10 | 96 GB |
| `A100_40G_X1` | 1x A100 40G | 40 GB |
| `A100_40G_X2` | 2x A100 40G | 80 GB |
| `A100_40G_X4` | 4x A100 40G | 160 GB |
| `A100_40G_X8` | 8x A100 40G | 320 GB |
| `A100_80G_X1` | 1x A100 80G | 80 GB |
| `A100_80G_X2` | 2x A100 80G | 160 GB |
| `A100_80G_X4` | 4x A100 80G | 320 GB |
| `A100_80G_X8` | 8x A100 80G | 640 GB |
| `H100_X1` | 1x H100 | 80 GB |
| `H100_X2` | 2x H100 | 160 GB |
| `H100_X4` | 4x H100 | 320 GB |
| `H100_X8` | 8x H100 | 640 GB |
| `H200_X1` | 1x H200 | 141 GB |
| `H200_X2` | 2x H200 | 282 GB |
| `H200_X4` | 4x H200 | 564 GB |
| `H200_X8` | 8x H200 | 1128 GB |
| `OAI_A10_X2` | 2x A10 | 48 GB |
| `OAI_A100_40G_X1` | 1x A100 40G | 40 GB |
| `OAI_A100_40G_X4` | 4x A100 40G | 160 GB |
| `OAI_A100_80G_X1` | 1x A100 80G | 80 GB |
| `OAI_A100_80G_X2` | 2x A100 80G | 160 GB |
| `OAI_H100_X1` | 1x H100 | 80 GB |
| `OAI_H100_X2` | 2x H100 | 160 GB |
| `OAI_H200_X1` | 1x H200 | 141 GB |

### 9-2. Oracle이 하드웨어를 숨기는 DAC unit

| DAC unit | GPU 타입 | GPU 메모리 | 비고 |
|---|---|---|---|
| `SMALL_COHERE_4` | 미공개 | 미공개 | Oracle이 underlying hardware를 숨김 |
| `LARGE_COHERE_V2_2` | 미공개 | 미공개 | same |
| `LARGE_COHERE_V3` | 미공개 | 미공개 | same |
| `EMBED_COHERE` | 미공개 | 미공개 | same |
| `RERANK_COHERE` | 미공개 | 미공개 | same |
| `SMALL_GENERIC_V2` | 미공개 | 미공개 | same |
| `LARGE_GENERIC` | 미공개 | 미공개 | same |
| `LARGE_GENERIC_2` | 미공개 | 미공개 | same |
| `LARGE_GENERIC_V2` | 미공개 | 미공개 | same |
| `LARGE_GENERIC_V1` | 미공개 | 미공개 | same |

---

## 10. import / custom deployment 권장 DAC

중요:

- Oracle 공식 문서는 imported model마다 정답형 권장 unit 표를 제공하지 않는다.
- 따라서 아래 표는 `Oracle이 공개한 GPU 메모리`만으로 만든 보수적 시작점이다.
- 실제 선택은 `vendor model card의 VRAM 요구량`, `양자화 여부`, `컨텍스트 길이`, `동시성`으로 최종 확정해야 한다.
- 이 절은 imported/custom deployment 기준이며, `OAI_*` unit은 관리형 `gpt-oss` 전용 표에서 별도로 본다.

| 필요 VRAM 기준 | 권장 시작 DAC | 해석 |
|---|---|---|
| 24 GB 전후 | `A10_X1` | 가장 작은 시작점 |
| 48 GB 전후 | `A10_X2` | 경량 배포 / 테스트 용이 |
| 80 GB 전후 | `A100_80G_X1` 또는 `H100_X1` | 중간급 여유 메모리 |
| 141 GB 전후 | `H200_X1` | 단일 unit 최대 메모리 여유 |
| 160 GB 전후 | `A100_40G_X4`, `A100_80G_X2`, `H100_X2` | 대형 단일 배포의 보편적 구간 |
| 320 GB 전후 | `A100_80G_X4` 또는 `H100_X4` | 큰 모델 / 더 긴 컨텍스트 / 여유 버퍼 |
| 564 GB 이상 | `H200_X4` 이상 | 메모리 병목 우선 해소용 |

실무 메모:

- imported model에서 메모리 병목이 먼저 걱정되면 `H200`이 가장 단순하다.
- throughput과 생태계 균형을 보려면 `H100`이 무난하다.
- 비용과 범용성을 먼저 보면 `A100 80G`가 시작점으로 좋다.

---

## 11. 파인튜닝 가능 여부

### 11-1. OCI Generative AI 기준

| 모델/계열 | 파인튜닝 가능 여부 | 메모 |
|---|---|---|
| `meta.llama-3.3-70b-instruct` | 가능 | LoRA |
| `cohere.command-r-08-2024` | 가능 | T-Few, LoRA |
| `cohere.command-a-03-2025` | 불가 | 모델 카드에 not available for fine-tuning |
| `cohere.command-a-vision` | 불가 | same |
| `cohere.command-a-reasoning` | 불가 | same |
| `cohere.embed-v4.0` | 불가 | same |
| `cohere.rerank.v3-5` | 불가 | same |
| `meta.llama-4-scout-17b-16e-instruct` | 불가 | same |
| `meta.llama-4-maverick-17b-128e-instruct-fp8` | 불가 | same |
| `openai.gpt-oss-20b` | 불가 | same |
| `openai.gpt-oss-120b` | 불가 | same |
| `google.gemini-2.5-*` | 불가 | on-demand only |
| `xai.grok-*` | 불가 | on-demand only |

### 11-2. retired 주의

| 모델 | 현재 판단 |
|---|---|
| `meta.llama-3.1-70b-instruct` | retired 반영 대상, 신규 파인튜닝 설계 권장하지 않음 |
| `cohere.command-r-16k` | retired 반영 대상, 신규 파인튜닝 설계 권장하지 않음 |

---

## 12. A100 / H100 / H200 선택 가이드

| 선택 기준 | A100 80G | H100 | H200 |
|---|---|---|---|
| 메모리 | 80 GB/GPU | 80 GB/GPU | 141 GB/GPU |
| 관리형 `gpt-oss` 가시성 | Chicago, Phoenix 중심 | 가장 넓음 | Riyadh 확인 |
| 추천 상황 | 비용/범용성 균형 | 성능/처리량 우선 | 메모리 병목 우선 |
| IaaS/AQUA 주의 | reservation 가능성 높음 | reservation 가능성 높음 | per-region 고정표 없음 |

짧게 정리하면:

- `A100 80G`: 비용과 범용성의 균형이 필요한 imported/custom 시작점
- `H100`: 관리형 DAC 선택지가 넓고 성능 우선일 때 유리
- `H200`: 한 unit에서 더 큰 메모리 여유가 필요할 때 우선 검토

---

## 13. 모델 강점 요약

| 모델 | 강점 한 줄 요약 |
|---|---|
| `cohere.command-a-03-2025` | 기업형 RAG / tool use / multilingual 범용 챗 |
| `cohere.command-a-vision` | 문서, 차트, 이미지가 섞인 멀티모달 업무 |
| `cohere.command-a-reasoning` | 긴 문서와 복합 reasoning |
| `cohere.embed-v4.0` | 텍스트+이미지 임베딩을 하나로 정리 |
| `meta.llama-4-scout` | 작은 GPU footprint와 긴 문맥의 균형 |
| `meta.llama-4-maverick` | 더 긴 문맥과 강한 코딩/추론 |
| `openai.gpt-oss-20b` | 빠른 reasoning/coding 반복 |
| `openai.gpt-oss-120b` | 더 높은 reasoning 품질 |
| `google.gemini-2.5-pro` | 가장 어려운 멀티모달 문제 해결 |
| `google.gemini-2.5-flash` | 속도와 지능의 균형 |
| `google.gemini-2.5-flash-lite` | 대량 처리, 저비용 |
| `xai.grok-code-fast-1` | agentic coding, tool-use 중심 |

---

## 14. 빠른 추천

- 기업형 범용 챗 / RAG / tool-use: `cohere.command-a-03-2025`
- 문서·차트·이미지 이해: `cohere.command-a-vision`
- 복합 reasoning 전용 DAC: `cohere.command-a-reasoning` 또는 `openai.gpt-oss-120b`
- 작은 GPU footprint로 긴 문맥: `meta.llama-4-scout`
- 온디맨드 멀티모달 최고 난도: `google.gemini-2.5-pro`
- 속도/가격 균형: `google.gemini-2.5-flash`
- 대량 배치/저비용: `google.gemini-2.5-flash-lite`
- 임베딩 표준화: `cohere.embed-v4.0`
- 코딩 에이전트: `xai.grok-code-fast-1` 또는 `openai.gpt-oss-20b`
- imported model을 메모리 우선으로 시작: `H200_X1` 먼저, 범용성 우선이면 `H100_X1` 또는 `A100_80G_X1`

---

## 15. retired / deprecated 메모

### 15-1. 신규 설계에서 우선 제외할 retired 모델

| 모델 | 상태 |
|---|---|
| `Cohere Command R+` | retired |
| `Cohere Command R 16K` | retired |
| `Cohere Command (52B)` | retired |
| `Cohere Command Light` | retired |
| `Meta Llama 3.1 70B` | retired |
| `Meta Llama 3 70B` | retired |

### 15-2. 주의해서 볼 deprecated / retirement window

| 모델 | 메모 |
|---|---|
| `Cohere Command R (08-2024)` | active지만 replacement 관점 검토 필요 |
| `Cohere Command R+ (08-2024)` | active지만 replacement 관점 검토 필요 |
| `Cohere Embed English Light 3` | dedicated retirement window가 `No sooner than 2026-03-29` |
| `Cohere Embed Multilingual Light 3` | dedicated retirement window가 `No sooner than 2026-03-29` |

---

## 16. 최종 하단 메모

### 16-1. 사용한 주요 공식 문서 범주

- OCI Generative AI 리전 문서
- OCI Generative AI `Models by Region` / `Dedicated Cluster Shapes by Region`
- OCI Generative AI 개별 모델 카드
- OCI Generative AI retirement / fine-tuning 문서
- OCI Compute shape 문서
- OCI Data Science `Supported Compute Shapes`, `Using GPUs`, `AI Quick Actions` 문서
- OCI CLI Generative AI / Dedicated AI Cluster 명령 참조

### 16-2. 이 문서에서 명시적으로 없는 것

- Oracle 공식 문서만으로 확정 가능한 `IaaS GPU 리전별 실시간 재고표`
- Oracle 공식 문서만으로 확정 가능한 `AQUA GPU 리전별 실시간 재고표`
- Oracle 공식 문서만으로 확정 가능한 `LARGE_COHERE_* / LARGE_GENERIC_*`의 실제 GPU 메모리

즉:

- `관리형 기본 모델 리전/모드/DAC unit`은 Oracle 문서로 상당히 명확하게 정리 가능
- `IaaS/AQUA의 리전별 실재고`는 CLI 또는 Console 실조회가 없으면 확정할 수 없음
- `generic/cohere DAC unit의 실제 GPU 메모리`는 Oracle이 숨기므로 단정하면 안 됨
