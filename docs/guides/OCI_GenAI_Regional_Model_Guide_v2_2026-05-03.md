# OCI Generative AI / DAC / AQUA / IaaS GPU 리전·모델 가이드 v2

최종 업데이트: 2026-05-03 (GMT)  
정리 기준: Oracle 공식 문서 우선 + OCI CLI 실조회 시도 결과  
산출물 경로: `/home/opc/oci-genai-guide-maintenance/runs/OCI_GenAI_Regional_Model_Guide_v2_2026-05-03.md`

이 문서는 `LATEST.md`로 복사될 수 있음을 전제로, 앞부분 1페이지 안에 핵심 변화와 판정 기준을 먼저 배치했다.

---

## 이번 업데이트 변화 요약

- Oracle 공개 문서 기준으로 `xAI Grok 4.3`가 모델 카드와 `Models by Region` 표에 나타난다.
  - 다만 이번 확인에서는 `xAI Grok 4.3` 전용 공개 릴리스 노트 페이지는 찾지 못했다.
- `2026-03-24` 기준, Oracle이 `xAI Grok 4.20` 및 `xAI Grok 4.20 Multi-Agent`를 OCI Generative AI에 추가했다.
- `2026-03-04` 기준, OpenAI `gpt-oss-20b` / `gpt-oss-120b` 전용 DAC 가시성이 `UAE East (Dubai)`, `Saudi Arabia Central (Riyadh)`, `US West (Phoenix)`까지 확장됐다.
- `2026-01-21` 기준, `Cohere Command A Reasoning`, `Cohere Command A Vision`이 추가됐고, `Models by Region` / `Dedicated Cluster Shapes by Region` 페이지가 별도 제공되기 시작해 리전 판정 근거가 더 명확해졌다.
- retired 모델은 이번 문서에서도 신규 설계 제외 대상으로 먼저 본다.
  - `Cohere Command R+`
  - `Cohere Command R 16K`
  - `Cohere Command (52B)`
  - `Cohere Command Light`
  - `Meta Llama 3.1 70B`
  - `Meta Llama 3 70B`
  - `Meta Llama 2 70B`
- dedicated retirement window 주의 모델:
  - `Cohere Embed English Image 3`
  - `Cohere Embed Multilingual Image 3`
  - `Cohere Embed English Light Image 3`
  - `Cohere Embed Multilingual Light Image 3`
  - `Cohere Embed English 3`
  - `Cohere Embed Multilingual 3`
  - `Cohere Embed English Light 3`
  - `Cohere Embed Multilingual Light 3`
  - Oracle 문서상 dedicated retirement date는 모두 `No sooner than 2026-03-29`
- 이번 문서 생성 시 OCI CLI 실조회는 성공하지 못했다.
  - `oci iam region-subscription list --all`: `timeout` 종료 코드 `124`
  - `oci compute shape list --all`: `timeout` 종료 코드 `124`
  - 따라서 `IaaS/AQUA GPU 재고`는 Oracle 문서 기준 해석표로 대체했다.

---

## 0. 먼저 보는 전제

### 0-1. 용어

- `Generative AI`: OCI Generative AI 관리형 서비스
- `DAC`: Dedicated AI Cluster
- `AQUA`: OCI Data Science AI Quick Actions
- `IaaS GPU`: OCI Compute 또는 OCI Data Science에서 직접 쓰는 GPU shape

### 0-2. 문서 해석 원칙

- Oracle 공식 문서에 있는 사실만 확정적으로 적었다.
- Oracle 공식 문서에 없는 내용은 `없음`, `미공개`, `문서상 명시 없음`으로 적었다.
- `관리형 기본 모델`과 `imported model`은 분리해서 적었다.
- `LARGE_COHERE_*`, `LARGE_GENERIC*`, `SMALL_GENERIC*`처럼 Oracle이 underlying GPU를 고객에게 공개하지 않는 DAC unit은 GPU 메모리를 단정하지 않았다.
- `AQUA 지원`과 `즉시 GPU 생성 가능`은 같은 의미가 아니다.
- `리전별 실재고`와 `문서상 지원 shape 존재`는 같은 의미가 아니다.

---

## 1. CLI 조회 성공/실패 상태

### 1-1. 실행 상태 표

| 조회 항목 | 실행 명령 | 상태 | 결과 |
|---|---|---|---|
| 구독 리전 조회 | `oci iam region-subscription list --all` | 실패 | `timeout` 종료 코드 `124` |
| GPU shape 조회 | `oci --region us-chicago-1 compute shape list --all -c <tenancy_ocid>` | 실패 | `timeout` 종료 코드 `124` |

### 1-2. 실패 이유 요약

| 항목 | 관찰 내용 | 문서 반영 방식 |
|---|---|---|
| `region-subscription list` | `identity.ap-seoul-1.oci.oraclecloud.com`로 GET 요청이 반복되지만 응답 완료 전에 `timeout` 종료 | Oracle 리전 문서 기준 표로 대체 |
| `compute shape list` | `iaas.us-chicago-1.oraclecloud.com/20160918/shapes`로 GET 요청이 반복되지만 응답 완료 전에 `timeout` 종료 | Compute/Data Science shape 문서 기준 해석표로 대체 |

정리:

- 이번 환경에서는 `NotAuthorizedOrNotFound`보다 `API 응답 타임아웃`이 먼저 확인됐다.
- 따라서 아래의 `IaaS/AQUA GPU 재고표`는 실시간 테넌시 재고가 아니라 Oracle 문서 기준 해석이다.

---

## 2. 리전별 Generative AI / DAC / AQUA 지원

### 2-1. 상용 리전

| 권역 | 리전 | 리전 식별자 | Generative AI | DAC | AQUA |
|---|---|---|---|---|---|
| SA | Brazil East (Sao Paulo) | `sa-saopaulo-1` | 지원 | 지원(모델별) | 지원 |
| EU | Germany Central (Frankfurt) | `eu-frankfurt-1` | 지원 | 지원(모델별) | 지원 |
| AP | India South (Hyderabad) | `ap-hyderabad-1` | 지원 | 지원(모델별) | 지원 |
| AP | Japan Central (Osaka) | `ap-osaka-1` | 지원 | 지원(모델별) | 지원 |
| ME | Saudi Arabia Central (Riyadh) | `me-riyadh-1` | 지원 | 지원(모델별) | 지원 |
| ME | UAE East (Dubai) | `me-dubai-1` | 지원 | 지원(모델별) | 지원 |
| EU | UK South (London) | `uk-london-1` | 지원 | 지원(모델별) | 지원 |
| NA | US East (Ashburn) | `us-ashburn-1` | 지원 | 지원(모델별) | 지원 |
| NA | US Midwest (Chicago) | `us-chicago-1` | 지원 | 지원(모델별) | 지원 |
| NA | US West (Phoenix) | `us-phoenix-1` | 지원 | 지원(모델별) | 지원 |

### 2-2. 정부 / 소버린 리전

| 권역 | 리전 | 리전 식별자 | Generative AI | DAC | AQUA |
|---|---|---|---|---|---|
| GOV | UK Gov South (London) | `uk-gov-london-1` | 지원 | 지원(모델별) | 지원 |
| SOV | EU Sovereign Central (Frankfurt) | `eu-frankfurt-2` | 지원 | 지원(모델별) | 문서상 명시 없음 |

메모:

- Generative AI 리전 목록은 Oracle의 `Generative AI Regions` 페이지 기준이다.
- AQUA는 Oracle 문서상 `all commercial and government regions` 지원이다.
- EU Sovereign에 대한 AQUA 지원은 이번 기준 문서에서 확인하지 못했다.

---

## 3. 리전별 DAC A10 / A100 / H100 / H200 가시성

판정 기준:

- 이 표는 Oracle이 하드웨어 unit을 명시한 `OpenAI gpt-oss` 모델 카드와 `Dedicated Cluster Shapes by Region` 페이지만 사용했다.
- 즉, `OAI_*` unit이 Oracle 문서에 드러난 경우만 `가시성 있음`으로 적었다.
- `LARGE_COHERE_*`, `LARGE_GENERIC*`는 underlying GPU 종류가 Oracle 문서에 공개되지 않아 여기서는 A10/A100/H100/H200 가시성 판정에 사용하지 않았다.

### 3-1. 상용 리전

| 리전 | A10 | A100 40G | A100 80G | H100 | H200 | 메모 |
|---|---|---|---|---|---|---|
| Sao Paulo | - | - | - | 예 | - | `gpt-oss`는 H100 계열만 문서 확인 |
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

짧은 해석:

- 관리형 `gpt-oss` 기준으로 가장 넓게 보이는 계열은 `H100`이다.
- `H200`은 이번 기준에서 `Riyadh`만 Oracle 문서상 확인된다.
- `A100 80G`는 `Chicago`, `Phoenix`에 명시된다.
- `A100 40G`는 `Dubai`에 명시된다.

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

- 명령 문법 자체는 유효하다.
- 이번 환경에서는 두 명령 모두 API 응답 완료 전에 `timeout`으로 종료됐다.
- 따라서 이 문서의 `IaaS/AQUA` 관련 표는 Oracle 공식 문서의 지원 shape와 해석 규칙을 사용한다.

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

### 5-2. GPU 메모리 환산 규칙

| 계열 | GPU당 메모리 | 예시 |
|---|---:|---|
| A10 | 24 GB | `A10_X2` = 48 GB |
| A100 40G | 40 GB | `A100_40G_X4` = 160 GB |
| A100 80G | 80 GB | `A100_80G_X2` = 160 GB |
| H100 | 80 GB | `H100_X4` = 320 GB |
| H200 | 141 GB | `H200_X2` = 282 GB |

---

## 6. IaaS / AQUA GPU 재고표

중요:

- Oracle 공식 문서는 `리전별 실시간 GPU 재고표`를 제공하지 않는다.
- 따라서 이 절은 `리전별 실재고 수량`이 아니라 `문서상 지원 shape와 운영 해석법`이다.

### 6-1. Oracle 문서상 지원 shape 재고표

| GPU 계열 | IaaS Compute shape 예 | Data Science / AQUA에서 해석되는 shape | Oracle의 리전별 고정 재고표 |
|---|---|---|---|
| V100 | `VM.GPU3.*`, `BM.GPU3.8` | 지원 shape 문서 존재 | 없음 |
| A10 | `VM.GPU.A10.*`, `BM.GPUA10.4` | 지원 shape 문서 존재 | 없음 |
| A100 40G | `BM.GPU4.8` | 지원 shape 문서 존재 | 없음 |
| A100 80G | `BM.GPU.A100-v2.8` | 지원 shape 문서 존재 | 없음 |
| H100 | `BM.GPU.H100.8` | 지원 shape 문서 존재 | 없음 |
| H200 | `BM.GPU.H200.8` | 지원 shape 문서 존재 | 없음 |
| L40S | `BM.GPU.L40S-NC.4` | 지원 shape 문서 존재 | 없음 |

### 6-2. 문서 기준 해석표

| 항목 | Oracle 문서 상태 | 이 문서의 처리 |
|---|---|---|
| IaaS GPU per-region 재고 수량 | 없음 | CLI 성공 시 실제 결과 우선, 실패 시 `없음` 유지 |
| AQUA per-region GPU 재고 수량 | 없음 | Data Science 지원 shape 기준으로만 해석 |
| 실제 생성 가능 여부 | 문서만으로 확정 불가 | service limit, host capacity, reservation 필요 여부를 추가 확인 |

### 6-3. 실무 메모

| 계열 | 실무 해석 |
|---|---|
| A10 | 상대적으로 작은 시작점이나, 리전별 실재고는 CLI/Console 실조회가 필요 |
| A100 | reservation 또는 host capacity 이슈를 자주 확인해야 하는 계열 |
| H100 | 관리형 DAC 가시성은 넓지만 IaaS 실재고는 문서만으로 확정 불가 |
| H200 | shape 문서는 있으나 per-region 고정 재고표는 없음 |
| L40S | 문서상 shape는 확인되지만 AQUA/리전별 실재고는 별도 확인 필요 |

---

## 7. 온디맨드 핵심 모델 표

### 7-1. 범용 / 멀티모달 / reasoning

| 모델 ID | 유형 | 컨텍스트 | 온디맨드 | 파인튜닝 | 핵심 강점 |
|---|---|---|---|---|---|
| `cohere.command-a-03-2025` | 범용 chat/agent | 256k | 예 | 불가 | RAG, tool use, multilingual |
| `cohere.command-a-vision` | 멀티모달 | 128k | 예(리전별 상이) | 불가 | 문서·차트·이미지 해석 |
| `cohere.command-a-reasoning` | 고난도 reasoning | 256k | 예(리전별 상이) | 불가 | 복합 추론, 구조화 논증 |
| `meta.llama-4-scout-17b-16e-instruct` | 멀티모달 | 192k | 예(리전별 상이) | 불가 | 작은 footprint, agentic/coding |
| `meta.llama-4-maverick-17b-128e-instruct-fp8` | 멀티모달 | 512k | 예(리전별 상이) | 불가 | 긴 문맥, 코딩/추론 |
| `openai.gpt-oss-20b` | 텍스트 reasoning | 128k | 예 | 불가 | 빠른 reasoning/coding 반복 |
| `openai.gpt-oss-120b` | 텍스트 reasoning | 128k | 예 | 불가 | 더 높은 reasoning 품질 |

### 7-2. 임베딩 / 외부 플랫폼 / 코딩

| 모델 ID | 유형 | 컨텍스트 | 온디맨드 | 파인튜닝 | 핵심 강점 |
|---|---|---|---|---|---|
| `cohere.embed-v4.0` | 임베딩 | 입력 총합 128k | 예 | 불가 | 텍스트/이미지 임베딩, 1536-d |
| `google.gemini-2.5-pro` | 멀티모달 reasoning | 1M | 예 | 불가 | 고난도 분석, 코드, 대형 입력 |
| `google.gemini-2.5-flash` | 빠른 멀티모달 reasoning | 1M | 예 | 불가 | 속도/지능 균형 |
| `google.gemini-2.5-flash-lite` | 경량 멀티모달 | 1M | 예 | 불가 | 저비용 대량 처리 |
| `xai.grok-4.3` | 최신 reasoning | 1M | 예 | 불가 | 정확도 중시 복합 추론 |
| `xai.grok-4.20-*` | reasoning / non-reasoning | 2M | 예 | 불가 | 장문, tool-calling, 멀티모달 |
| `xai.grok-code-fast-1` | 코딩 agent | 256k | 예 | 불가 | agentic coding, tool-use |

메모:

- Google Gemini 계열은 Oracle 문서상 온디맨드 전용이며 `external calls` 설명이 있다.
- xAI Grok 계열도 Oracle 문서상 온디맨드 전용이다.
- `예(리전별 상이)`는 모델별 region matrix를 확인해야 한다는 뜻이다.

---

## 8. DAC 중심 모델 표

### 8-1. 관리형 기본 모델 중심

| 모델 ID | 호스팅 DAC unit | 지역 특이사항 | 파인튜닝 | 메모 |
|---|---|---|---|---|
| `cohere.command-a-03-2025` | `LARGE_COHERE_V3 x1` | UAE East는 `SMALL_COHERE_4 x1` 계열 문서 확인 | 불가 | 범용 관리형 chat |
| `cohere.command-a-vision` | `LARGE_COHERE_V3 x1` | UAE East는 `SMALL_COHERE_4 x1` 계열 문서 확인 | 불가 | 멀티모달 |
| `cohere.command-a-reasoning` | `LARGE_COHERE_V2_2 x1` | UAE East는 `SMALL_COHERE_4 x1` 계열 문서 확인 | 불가 | reasoning 중심 |
| `cohere.embed-v4.0` | `EMBED_COHERE x1` | 리전별 온디맨드/전용 차이 존재 | 불가 | 임베딩 전용 |
| `cohere.rerank.v3-5` | `RERANK_COHERE x1` | DAC 중심 | 불가 | 검색 후 재정렬 |
| `meta.llama-4-scout-17b-16e-instruct` | `LARGE_GENERIC_V2 x1` | 일부 리전만 온디맨드 병행 | 불가 | 작은 footprint |
| `meta.llama-4-maverick-17b-128e-instruct-fp8` | `LARGE_GENERIC_2 x1` | 일부 리전만 온디맨드 병행 | 불가 | 512k 컨텍스트 |
| `meta.llama-3.3-70b-instruct` | `LARGE_GENERIC x1` hosting / `LARGE_GENERIC x2` fine-tuning | EU Sovereign, UK Gov는 fine-tuning 불가 | 가능 | 현재 대표적 fine-tuning 베이스 |
| `openai.gpt-oss-20b` | 리전별 `OAI_A10_X2 / OAI_A100_40G_X1 / OAI_A100_80G_X1 / OAI_H100_X1 / OAI_H200_X1` | 리전별 하드웨어 편차 큼 | 불가 | GPU 계열이 가장 명확 |
| `openai.gpt-oss-120b` | 리전별 `OAI_A100_40G_X4 / OAI_A100_80G_X2 / OAI_H100_X2 / OAI_H200_X1` | 리전별 하드웨어 편차 큼 | 불가 | 고난도 reasoning |

### 8-2. 현재 Oracle 문서상 파인튜닝 가능한 관리형 베이스 모델

| 베이스 모델 | 현재 상태 | 학습 방식 | 메모 |
|---|---|---|---|
| `meta.llama-3.3-70b-instruct` | 가능 | LoRA | 현재 주력 fine-tuning 대상 |
| `cohere.command-r-08-2024` | 가능 | T-Few, LoRA | active지만 replacement 검토 권장 |
| `meta.llama-3.1-70b-instruct` | retired | LoRA | 신규 설계 비권장 |
| `cohere.command-r-16k` | retired | T-Few, LoRA | 신규 설계 비권장 |

---

## 9. DAC 유닛별 배포 필요 GPU 메모리 표

중요:

- 아래 9-1은 이름만으로 GPU 메모리를 계산할 수 있는 unit만 넣었다.
- 아래 9-2는 Oracle이 underlying GPU를 문서에 공개하지 않는 unit이다.

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

| DAC unit | GPU 타입 | GPU 메모리 | 메모 |
|---|---|---|---|
| `SMALL_COHERE_4` | 미공개 | 미공개 | Oracle 문서상 underlying GPU 비공개 |
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

- 이 절은 `imported model` 또는 `custom deployment` 관점이다.
- 관리형 기본 모델용 `LARGE_COHERE_*`, `LARGE_GENERIC*`, `OAI_*`와 혼동하지 않는다.
- 아래 표는 Oracle의 `Compatible Models for Import` 계열 문서에 명시된 `Recommended Dedicated AI Cluster Unit Shape`를 우선 반영했다.
- Oracle 문서 공통 메모: 추천 unit이 해당 리전에 없으면 더 높은 tier를 선택하라고 안내한다. 예: `A100`이 없으면 `H100`.

### 10-1. Oracle 문서에 직접 나온 권장 예시

| 용도 | 모델 예시 | Oracle 권장 DAC |
|---|---|---|
| 작은 텍스트 배포 | `microsoft/phi-4` | `A100_80G_X1` |
| 작은 멀티모달 배포 | `google/gemma-3-4b-it` | `A100_80G_X1` |
| 임베딩 imported 모델 | `intfloat/e5-mistral-7b-instruct` | `A10_X1` |
| 중간 텍스트 추론 | `deepseek-ai/DeepSeek-R1-Distill-Qwen-32B` | `A100_80G_X2` |
| 중간 멀티모달 | `google/gemma-3-27b-it` | `A100_80G_X2` |
| Mixtral 계열 | `mistralai/Mixtral-8x7B-Instruct-v0.1` | `A100_80G_X2` |
| 큰 텍스트 모델 | `meta-llama/Llama-3.3-70B-Instruct` | `A100_80G_X4` |
| OpenAI imported 20b | `openai/gpt-oss-20b` | `H100_X1` |
| OpenAI imported 120b | `openai/gpt-oss-120b` | `H100_X2` |
| 비전 포함 Meta 중형 | `meta-llama/Llama-4-Scout-17B-16E-Instruct` | `H100_X4` |
| 비전 포함 Meta 대형 | `meta-llama/Llama-4-Maverick-17B-128E-Instruct-FP8` | `H100_X8` |
| 비전 포함 Phi | `microsoft/Phi-3-vision-128k-instruct` | `H100_X1` |

### 10-2. 시작점 선택 가이드

| 상황 | 권장 시작점 |
|---|---|
| 경량 텍스트/임베딩 테스트 | `A10_X1` 또는 `A100_80G_X1` |
| 30B 전후 텍스트 모델 | `A100_80G_X2` |
| 70B 전후 텍스트 모델 | `A100_80G_X4` |
| OpenAI imported `gpt-oss-20b` | `H100_X1` |
| OpenAI imported `gpt-oss-120b` | `H100_X2` |
| 긴 문맥 멀티모달 Meta Llama 4 Scout | `H100_X4` |
| 더 큰 멀티모달 Meta Llama 4 Maverick | `H100_X8` |
| 리전에 A100이 없고 상위 호환이 필요 | `H100` 우선 검토 |

---

## 11. 파인튜닝 가능 여부

### 11-1. OCI Generative AI 관리형 기본 모델 기준

| 모델/계열 | 파인튜닝 가능 여부 | 메모 |
|---|---|---|
| `meta.llama-3.3-70b-instruct` | 가능 | LoRA, OC1에서 지원 |
| `cohere.command-r-08-2024` | 가능 | T-Few, LoRA |
| `cohere.command-a-03-2025` | 불가 | 모델 카드 기준 |
| `cohere.command-a-vision` | 불가 | 모델 카드 기준 |
| `cohere.command-a-reasoning` | 불가 | 모델 카드 기준 |
| `cohere.embed-v4.0` | 불가 | 모델 카드 기준 |
| `cohere.rerank.v3-5` | 불가 | 모델 카드 기준 |
| `meta.llama-4-scout-17b-16e-instruct` | 불가 | 모델 카드 기준 |
| `meta.llama-4-maverick-17b-128e-instruct-fp8` | 불가 | 모델 카드 기준 |
| `openai.gpt-oss-20b` | 불가 | 모델 카드 기준 |
| `openai.gpt-oss-120b` | 불가 | 모델 카드 기준 |
| `google.gemini-2.5-*` | 불가 | Oracle 문서상 tuning 없음 |
| `xai.grok-*` | 불가 | Oracle 문서상 on-demand only |

### 11-2. imported model 기준

| 항목 | Oracle 문서 기준 |
|---|---|
| imported fine-tuned model 지원 | 지원 가능 |
| 조건 | 지원 base model과 transformer version 일치 |
| 조건 | 파라미터 수가 원본 대비 `±10%` 이내 |
| 주의 | 지원 목록에 없는 모델은 production 전 별도 검증 권장 |

### 11-3. retired 주의

| 모델 | 현재 판단 |
|---|---|
| `meta.llama-3.1-70b-instruct` | retired, 신규 파인튜닝 설계 비권장 |
| `cohere.command-r-16k` | retired, 신규 파인튜닝 설계 비권장 |

---

## 12. A100 / H100 / H200 선택 가이드

| 선택 기준 | A100 80G | H100 | H200 |
|---|---|---|---|
| GPU당 메모리 | 80 GB | 80 GB | 141 GB |
| 관리형 `gpt-oss` 가시성 | Chicago, Phoenix 중심 | 가장 넓음 | Riyadh 확인 |
| imported model 권장 빈도 | 높음 | 높음 | 상대적으로 적음 |
| 추천 상황 | 비용/범용성 균형 | 성능/처리량 우선 | 메모리 병목 우선 |
| 주의 | A100 리전 편차 큼 | IaaS 실재고는 별도 확인 필요 | per-region 고정 재고표 없음 |

짧게 정리:

- `A100 80G`: imported/custom 시작점으로 가장 범용적이다.
- `H100`: 관리형 `gpt-oss`와 imported 대형 모델에서 선택지가 가장 넓다.
- `H200`: GPU당 메모리 여유가 가장 크지만, 공식 문서상 리전 가시성은 좁다.

---

## 13. 모델 강점 요약

| 모델 | 강점 한 줄 요약 |
|---|---|
| `cohere.command-a-03-2025` | 기업형 RAG / tool use / multilingual 범용 챗 |
| `cohere.command-a-vision` | 문서, 차트, 이미지가 섞인 멀티모달 업무 |
| `cohere.command-a-reasoning` | 긴 문서와 복합 reasoning |
| `cohere.embed-v4.0` | 텍스트와 이미지를 아우르는 임베딩 |
| `meta.llama-4-scout` | 작은 GPU footprint와 agentic use case의 균형 |
| `meta.llama-4-maverick` | 더 긴 문맥과 강한 코딩/추론 |
| `meta.llama-3.3-70b-instruct` | 관리형 fine-tuning 가능한 대표 텍스트 모델 |
| `openai.gpt-oss-20b` | 빠른 reasoning/coding 반복 |
| `openai.gpt-oss-120b` | 고난도 reasoning 및 agentic workload |
| `google.gemini-2.5-pro` | 복잡한 멀티모달 문제 해결 |
| `google.gemini-2.5-flash` | 속도와 지능의 균형 |
| `google.gemini-2.5-flash-lite` | 대량 처리, 저비용 |
| `xai.grok-4.3` | 최신 고정밀 reasoning 중심 |
| `xai.grok-4.20-*` | 2M 컨텍스트, reasoning/non-reasoning 분리 |
| `xai.grok-code-fast-1` | agentic coding, tool-use 중심 |

---

## 14. 빠른 추천

- 기업형 범용 챗 / RAG / tool-use: `cohere.command-a-03-2025`
- 문서·차트·이미지 이해: `cohere.command-a-vision`
- 복합 reasoning DAC: `cohere.command-a-reasoning` 또는 `openai.gpt-oss-120b`
- 최신 온디맨드 reasoning 우선: `xai.grok-4.3`
- 관리형 fine-tuning 출발점: `meta.llama-3.3-70b-instruct`
- 작은 GPU footprint와 긴 문맥: `meta.llama-4-scout`
- 온디맨드 멀티모달 최고 난도: `google.gemini-2.5-pro`
- 속도/가격 균형: `google.gemini-2.5-flash`
- 대량 배치/저비용: `google.gemini-2.5-flash-lite`
- 코딩 에이전트: `xai.grok-code-fast-1`
- imported model을 Oracle 권장 DAC로 시작: 70B급은 `A100_80G_X4`, OpenAI imported는 `H100_X1` 또는 `H100_X2`
- 메모리 병목이 가장 우선이면: `H200` 계열을 검토하되, 리전 가시성은 별도 확인

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
| `Meta Llama 2 70B` | retired |

### 15-2. retirement window 주의 모델

| 모델 | 메모 |
|---|---|
| `Cohere Command R (08-2024)` | active지만 replacement 검토 권장 |
| `Cohere Command R+ (08-2024)` | active지만 replacement 검토 권장 |
| `Cohere Embed English Image 3` | dedicated retirement window가 `No sooner than 2026-03-29` |
| `Cohere Embed Multilingual Image 3` | dedicated retirement window가 `No sooner than 2026-03-29` |
| `Cohere Embed English Light Image 3` | dedicated retirement window가 `No sooner than 2026-03-29` |
| `Cohere Embed Multilingual Light Image 3` | dedicated retirement window가 `No sooner than 2026-03-29` |
| `Cohere Embed English 3` | dedicated retirement window가 `No sooner than 2026-03-29` |
| `Cohere Embed Multilingual 3` | dedicated retirement window가 `No sooner than 2026-03-29` |
| `Cohere Embed English Light 3` | dedicated retirement window가 `No sooner than 2026-03-29` |
| `Cohere Embed Multilingual Light 3` | dedicated retirement window가 `No sooner than 2026-03-29` |

---

## 16. 최종 하단 메모

### 16-1. 사용한 주요 공식 문서 범주

- OCI Generative AI 리전 문서
- OCI Generative AI `Models by Region`
- OCI Generative AI `Dedicated Cluster Shapes by Region`
- OCI Generative AI 개별 모델 카드
- OCI Generative AI retirement / fine-tuning / imported models 문서
- OCI Data Science `Supported Compute Shapes`
- OCI Data Science `AI Quick Actions`
- OCI Generative AI release notes

### 16-2. 이 문서에서 명시적으로 없는 것

- Oracle 공식 문서만으로 확정 가능한 `IaaS GPU 리전별 실시간 재고 수량`
- Oracle 공식 문서만으로 확정 가능한 `AQUA GPU 리전별 실시간 재고 수량`
- Oracle 공식 문서만으로 확정 가능한 `LARGE_COHERE_* / LARGE_GENERIC*` 계열의 실제 GPU 메모리

즉:

- `관리형 기본 모델의 리전/모드/DAC unit`은 Oracle 문서로 비교적 명확하게 정리 가능
- `IaaS/AQUA의 리전별 실재고`는 CLI 또는 Console 실조회가 없으면 확정할 수 없음
- `generic/cohere DAC unit의 실제 GPU 메모리`는 Oracle이 숨기므로 단정하면 안 됨
