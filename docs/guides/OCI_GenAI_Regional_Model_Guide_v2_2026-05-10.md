# OCI Generative AI / DAC / AQUA / IaaS GPU 리전·모델 가이드 v2

최종 업데이트: 2026-05-10 (GMT)  
정리 기준: Oracle 공식 문서 우선 + OCI CLI 실조회 시도 결과  
산출물 경로: `/home/opc/oci-genai-guide-maintenance/runs/OCI_GenAI_Regional_Model_Guide_v2_2026-05-10.md`

이 문서는 `LATEST.md`로 복사될 수 있음을 전제로, 앞부분 1페이지 안에 핵심 변화와 판정 기준을 먼저 배치했다.

---

## 이번 업데이트 변화 요약

- `2026-05-05` 기준, Oracle이 `UAE Central (Abu Dhabi)`를 OCI Generative AI 지원 리전에 추가했다.
- `2026-05-01` 기준, Oracle이 `xAI Grok 4.3`를 OCI Generative AI에 추가했다.
  - 현재 Oracle `Models by Region` 표 기준으로 `US East (Ashburn)`, `US Midwest (Chicago)`, `US West (Phoenix)`에서 `on-demand only`로 확인된다.
- `retired / deprecated` 정리는 지난 문서보다 더 강하게 바뀌었다.
  - `Model Retirement Dates (Dedicated Mode)` 기준으로 `Cohere Embed English Image 3`, `Cohere Embed English Light Image 3`, `Cohere Embed Multilingual Image 3`, `Cohere Embed Multilingual Light Image 3`, `Cohere Embed English 3`, `Cohere Embed Multilingual 3`, `Cohere Embed English Light 3`, `Cohere Embed Multilingual Light 3`, `Meta Llama 3.2 90B`, `Meta Llama 3.2 11B`, `Meta Llama 3.1 405B`가 retired 표에 들어가며 retirement date가 `2026-09-30`로 명시된다.
  - `Model Retirement Dates (On-Demand Mode)` 기준으로 `Cohere Command R (08-2024)`, `Cohere Command R+ (08-2024)`도 retired 표에 있고 on-demand retirement date는 `2026-09-30`이다.
- OpenAI `gpt-oss` 전용 DAC 하드웨어 가시성은 기존 판단을 유지한다.
  - `Dubai`: `A10`, `A100 40G`
  - `Riyadh`: `H200`
  - `Chicago`: `A10`, `A100 80G`, `H100`
  - `Phoenix`: `A100 80G`
- 이번 문서 생성 시 OCI CLI 실조회는 성공하지 못했다.
  - `region-subscription list`와 `compute shape list` 모두 `RequestException`으로 끝났다.
  - 디버그 기준 실제 원인은 `socket.gaierror: [Errno -2] Name or service not known`이며, DNS/이름 해석 단계에서 막혔다.
  - 따라서 `IaaS/AQUA GPU 재고표`는 Oracle 문서 기준 해석표로 대체했다.

---

## 0. 먼저 보는 전제

### 0-1. 용어

- `Generative AI`: OCI Generative AI 관리형 서비스
- `DAC`: Dedicated AI Cluster
- `AQUA`: OCI Data Science AI Quick Actions
- `IaaS GPU`: OCI Compute 또는 OCI Data Science에서 직접 쓰는 GPU shape
- `관리형 기본 모델`: Oracle이 직접 제공하는 pretrained foundation model
- `imported model`: Hugging Face 또는 OCI Object Storage에서 가져와 DAC에 직접 배포하는 모델

### 0-2. 문서 해석 원칙

- Oracle 공식 문서에 있는 사실만 확정적으로 적었다.
- Oracle 공식 문서에 없으면 `없음`, `미공개`, `문서상 명시 없음`으로 적었다.
- `관리형 기본 모델`과 `imported model`은 분리해서 적었다.
- `LARGE_COHERE_*`, `LARGE_GENERIC*`, `SMALL_GENERIC*`, `EMBED_COHERE`, `RERANK_COHERE`는 Oracle이 underlying GPU를 공개하지 않으므로 GPU 메모리를 단정하지 않았다.
- `AQUA 지원`과 `즉시 GPU 생성 가능`은 같은 의미가 아니다.
- `리전별 실재고`와 `문서상 지원 shape 존재`는 같은 의미가 아니다.
- `리전별 DAC A10/A100/H100/H200 가시성`은 Oracle이 하드웨어 unit을 공개한 `OpenAI gpt-oss` 계열 `OAI_*` unit 기준으로만 판정했다.

---

## 1. CLI 조회 성공/실패 상태

### 1-1. 실행 상태 표

| 조회 항목 | 실행 명령 | 상태 | 결과 |
|---|---|---|---|
| CLI 버전 확인 | `oci --version` | 성공 | `3.78.0` |
| 구독 리전 조회 | `oci iam region-subscription list --all` | 실패 | `RequestException: The connection to endpoint timed out.` |
| GPU shape 조회 | `oci --region us-chicago-1 compute shape list --all -c <tenancy_ocid>` | 실패 | `RequestException: The connection to endpoint timed out.` |
| DNS 확인 | `getent hosts identity.ap-seoul-1.oci.oraclecloud.com` | 실패 | 출력 없음 |
| DNS 확인 | `getent hosts iaas.us-chicago-1.oraclecloud.com` | 실패 | 출력 없음 |

### 1-2. 실패 이유 요약

| 항목 | 관찰 내용 | 문서 반영 방식 |
|---|---|---|
| `region-subscription list` | 디버그 로그에 `GET https://identity.ap-seoul-1.oci.oraclecloud.com/.../regionSubscriptions` 반복 후 `socket.gaierror: [Errno -2] Name or service not known` | Oracle `Generative AI Regions` 문서 기준 표로 대체 |
| `compute shape list` | 디버그 로그에 `GET https://iaas.us-chicago-1.oraclecloud.com/20160918/shapes` 반복 후 `socket.gaierror: [Errno -2] Name or service not known` | Oracle `Compute Shapes` / `Data Science Supported Compute Shapes` 문서 기준 해석표로 대체 |

정리:

- 이번 환경의 실패 원인은 `권한 부족`보다 앞 단계인 `DNS/이름 해석 실패`다.
- 따라서 아래 `IaaS / AQUA GPU 재고표`는 실시간 테넌시 결과가 아니라 Oracle 공식 문서 기준 해석이다.

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
| ME | UAE Central (Abu Dhabi) | `me-abudhabi-1` | 지원 | 지원(모델별) | 지원 |
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

- Generative AI 리전 목록은 Oracle `Generative AI Regions` 문서 기준이다.
- AQUA는 Oracle 문서상 `all commercial and government regions` 지원이다.
- EU Sovereign에 대한 AQUA 지원은 이번 확인 문서에서 명시를 찾지 못했다.

---

## 3. 리전별 DAC A10 / A100 / H100 / H200 가시성

판정 기준:

- 이 표는 Oracle `Dedicated Cluster Shapes by Region` 문서의 `OpenAI gpt-oss` 행과 개별 `gpt-oss` 모델 카드만 사용했다.
- 즉, `OAI_A10_*`, `OAI_A100_*`, `OAI_H100_*`, `OAI_H200_*`가 문서에 공개된 경우만 `예`로 적었다.
- `LARGE_COHERE_*`, `LARGE_GENERIC*`는 underlying GPU가 미공개이므로 A10/A100/H100/H200 가시성 판정에 쓰지 않았다.

### 3-1. 북미 / 남미

| 리전 | A10 | A100 40G | A100 80G | H100 | H200 | 메모 |
|---|---|---|---|---|---|---|
| Brazil East (Sao Paulo) | - | - | - | 예 | - | `gpt-oss`는 `OAI_H100_X1/X2` |
| US East (Ashburn) | 예 | - | - | 예 | - | `20b`는 `A10` 또는 `H100`, `120b`는 `H100` |
| US Midwest (Chicago) | 예 | - | 예 | 예 | - | `A10 / A100 80G / H100` 공존 |
| US West (Phoenix) | - | - | 예 | - | - | `A100 80G`만 공개 |

### 3-2. 유럽 / 중동 / 아시아태평양

| 리전 | A10 | A100 40G | A100 80G | H100 | H200 | 메모 |
|---|---|---|---|---|---|---|
| Germany Central (Frankfurt) | 예 | - | - | 예 | - | `20b`는 `A10` 또는 `H100`, `120b`는 `H100` |
| EU Sovereign Central (Frankfurt) | 예 | - | - | 예 | - | `20b`는 `A10` 또는 `H100`, `120b`는 `H100` |
| UK South (London) | - | - | - | 예 | - | `H100`만 공개 |
| UK Gov South (London) | - | - | - | 예 | - | `H100`만 공개 |
| Saudi Arabia Central (Riyadh) | - | - | - | - | 예 | `20b/120b` 모두 `H200` 공개 |
| UAE Central (Abu Dhabi) | - | - | - | - | - | DAC 자체는 지원되지만 공개 `OAI_*` row는 없음 |
| UAE East (Dubai) | 예 | 예 | - | - | - | `20b`는 `A10` 또는 `A100 40G`, `120b`는 `A100 40G` |
| India South (Hyderabad) | - | - | - | 예 | - | `H100` 공개 |
| Japan Central (Osaka) | - | - | - | 예 | - | `H100` 공개 |

짧은 해석:

- 관리형 `gpt-oss` 기준으로 가장 넓게 보이는 계열은 `H100`이다.
- `H200`은 이번 확인 기준에서 `Riyadh`만 Oracle 문서상 공개된다.
- `A100 80G`는 `Chicago`, `Phoenix`에서 공개된다.
- `A100 40G`는 `Dubai`에서 공개된다.
- `Abu Dhabi`는 서비스 리전에는 들어왔지만, 공개 `OAI_*` unit 기준의 DAC 하드웨어 가시성은 아직 확인되지 않는다.

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
  -c <tenancy_ocid> \
  --query 'data[?contains(shape, `GPU`)].{shape:shape,gpus:gpus,"gpu-desc":"gpu-description",memory:"memory-in-gbs",ocpus:ocpus}' \
  --output table
```

### 4-2. 이번 실행의 해석

- 명령 문법 자체는 유효하다.
- 이번 환경에서는 두 명령 모두 인증/권한 판정 전, 엔드포인트 DNS 해석 실패로 `RequestException`이 발생했다.
- 따라서 이 문서의 `IaaS / AQUA` 관련 표는 Oracle 공식 문서의 지원 shape와 해석 규칙을 사용한다.

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

### 5-1. VM GPU shapes

| Shape | GPU | GPU 수 | 총 GPU 메모리 | OCPU | CPU 메모리 |
|---|---|---:|---:|---:|---:|
| `VM.GPU3.1` | V100 | 1 | 16 GB | 6 | 90 GB |
| `VM.GPU3.2` | V100 | 2 | 32 GB | 12 | 180 GB |
| `VM.GPU3.4` | V100 | 4 | 64 GB | 24 | 360 GB |
| `VM.GPU.A10.1` | A10 | 1 | 24 GB | 15 | 240 GB |
| `VM.GPU.A10.2` | A10 | 2 | 48 GB | 30 | 480 GB |

### 5-2. Bare metal GPU shapes

| Shape | GPU | GPU 수 | 총 GPU 메모리 | OCPU | CPU 메모리 |
|---|---|---:|---:|---:|---:|
| `BM.GPU3.8` | V100 | 8 | 128 GB | 52 | 768 GB |
| `BM.GPUA10.4` | A10 | 4 | 96 GB | 64 | 1024 GB |
| `BM.GPU4.8` | A100 40G | 8 | 320 GB | 64 | 2048 GB |
| `BM.GPU.A100-v2.8` | A100 80G | 8 | 640 GB | 64 | 2048 GB |
| `BM.GPU.H100.8` | H100 | 8 | 640 GB | 112 | 2048 GB |
| `BM.GPU.H200.8` | H200 | 8 | 1128 GB | 112 | 3072 GB |
| `BM.GPU.L40S-NC.4` | L40S | 4 | 192 GB | 112 | 1024 GB |

### 5-3. GPU 메모리 환산 규칙

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

- Oracle 공식 문서는 `리전별 실시간 GPU 재고 수량`을 제공하지 않는다.
- 따라서 이 절은 `실재고 수량표`가 아니라 `문서상 지원 shape와 운영 해석표`다.

### 6-1. Oracle 문서상 지원 shape 재고표

| GPU 계열 | OCI Compute shape 예 | Data Science / AQUA 해석 | Oracle의 리전별 실시간 재고표 |
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
| 실제 생성 가능 여부 | 문서만으로 확정 불가 | `service limit`, `shape capacity`, `reservation` 여부를 추가 확인 |
| Data Science GPU 사용 조건 | 문서 명시 있음 | 리전 내 shape 가용성과 Data Science limit가 둘 다 필요 |
| Reserved GPU 이전 | 문서 명시 있음 | Compute 예약 GPU를 Data Science로 이전 가능하나 제약 존재 |

### 6-3. 실무 메모

| 계열 | 실무 해석 |
|---|---|
| A10 | 작은 시작점이지만 리전별 실재고는 CLI/Console 실조회 필요 |
| A100 | imported/custom 시작점으로 범용적이지만 리전 편차와 capacity 이슈 확인 필요 |
| H100 | 관리형 DAC 가시성은 가장 넓지만 IaaS 실재고는 문서만으로 확정 불가 |
| H200 | shape 문서는 있으나 per-region 고정 재고표는 없음 |
| AQUA | `지원`은 `즉시 GPU 생성 가능`이 아니라 `Data Science GPU shape를 활용할 수 있는 기능 경로`로 해석해야 함 |

---

## 7. 온디맨드 핵심 모델 표

### 7-1. 관리형 기본 모델

| 모델 ID | 유형 | 컨텍스트 | 온디맨드 | 파인튜닝 | 핵심 강점 |
|---|---|---|---|---|---|
| `cohere.command-a-03-2025` | 범용 chat/agent | 256k | 예 | 불가 | tool use, RAG, multilingual |
| `cohere.command-a-vision` | 멀티모달 | 128k | 예(리전별 상이) | 불가 | 문서, 차트, 이미지 해석 |
| `cohere.embed-v4.0` | 임베딩 | 총 128k 입력 | 예 | 불가 | 텍스트/이미지 임베딩, 1536-d |
| `meta.llama-4-scout-17b-16e-instruct` | 멀티모달 | 192k | 예(리전별 상이) | 불가 | 작은 GPU footprint, agentic 활용 |
| `meta.llama-4-maverick-17b-128e-instruct-fp8` | 멀티모달 | 512k | 예(리전별 상이) | 불가 | 긴 문맥, 코딩/추론 |
| `meta.llama-3.3-70b-instruct` | 텍스트 | 128k | 예(리전별 상이) | 가능 | 현행 관리형 fine-tuning 대표 모델 |
| `openai.gpt-oss-20b` | 텍스트 reasoning | 128k | 예 | 불가 | 빠른 reasoning/coding 반복 |
| `openai.gpt-oss-120b` | 텍스트 reasoning | 128k | 예 | 불가 | 고난도 reasoning, production 지향 |

### 7-2. 외부 플랫폼 / 외부 호출 계열

| 모델 ID | 유형 | 컨텍스트 | 온디맨드 | 파인튜닝 | 핵심 강점 |
|---|---|---|---|---|---|
| `google.gemini-2.5-pro` | 멀티모달 reasoning | 1M | 예 | 불가 | 고난도 분석, 코드, 복합 멀티모달 |
| `google.gemini-2.5-flash` | 빠른 멀티모달 reasoning | 1M | 예 | 불가 | 속도/지능 균형 |
| `google.gemini-2.5-flash-lite` | 경량 멀티모달 | 1M | 예 | 불가 | 저비용 대량 처리 |
| `xai.grok-4.3` | 최신 reasoning | 1M | 예 | 불가 | 정확도 중시 reasoning, 함수 호출 |
| `xai.grok-4.20-0309-*` | reasoning / non-reasoning | 2M | 예 | 불가 | 장문, tool-calling, 멀티모달 |
| `xai.grok-code-fast-1` | 코딩 agent | 256k | 예 | 불가 | agentic coding, terminal/tool use |

메모:

- Google Gemini 계열은 Oracle 문서상 `on-demand only`이며 `External Calls` 설명이 있다.
- xAI Grok 계열도 Oracle 문서상 `on-demand only`다.
- `Cohere Command A Reasoning`은 현재 Oracle region matrix 기준으로 DAC 중심 모델로 보는 편이 안전하다.
- `예(리전별 상이)`는 모델별 region matrix를 따로 확인해야 한다는 뜻이다.

---

## 8. DAC 중심 모델 표

### 8-1. 현재 운영 관점에서 먼저 볼 관리형 DAC 모델

| 모델 ID | 호스팅 DAC unit | 파인튜닝 | 메모 |
|---|---|---|---|
| `cohere.command-a-03-2025` | `LARGE_COHERE_V3 x1` | 불가 | `Dubai`는 `SMALL_COHERE_4 x1` 공개 |
| `cohere.command-a-vision` | `LARGE_COHERE_V3 x1` | 불가 | `Dubai`는 `SMALL_COHERE_4 x1` 공개 |
| `cohere.command-a-reasoning` | `LARGE_COHERE_V2_2 x1` | 불가 | `Dubai`는 `SMALL_COHERE_4 x1` 공개 |
| `cohere.embed-v4.0` | `EMBED_COHERE x1` | 불가 | 임베딩 전용 |
| `Cohere Rerank 3.5` | `RERANK_COHERE x1` | 불가 | rerank 전용 |
| `meta.llama-4-scout-17b-16e-instruct` | `LARGE_GENERIC_V2 x1` | 불가 | 멀티모달, 작은 footprint |
| `meta.llama-4-maverick-17b-128e-instruct-fp8` | `LARGE_GENERIC_2 x1` | 불가 | 512k 컨텍스트 |
| `meta.llama-3.3-70b-instruct` | `LARGE_GENERIC x1` hosting / `LARGE_GENERIC x2` fine-tuning | 가능 | OC1 fine-tuning 가능, OC4/OC19 불가 |
| `openai.gpt-oss-20b` | 리전별 `OAI_A10_X2 / OAI_A100_40G_X1 / OAI_A100_80G_X1 / OAI_H100_X1 / OAI_H200_X1` | 불가 | 하드웨어 종류가 가장 명확 |
| `openai.gpt-oss-120b` | 리전별 `OAI_A100_40G_X4 / OAI_A100_80G_X2 / OAI_H100_X2 / OAI_H200_X1` | 불가 | 고난도 reasoning |

### 8-2. retired 상태를 먼저 인지해야 할 구형 DAC 모델

| 모델/계열 | 현재 판단 | 메모 |
|---|---|---|
| `cohere.command-r-08-2024` | on-demand retired 표 / dedicated retired 표 | 신규 설계 시작점으로는 비권장 |
| `cohere.command-r-plus-08-2024` | on-demand retired 표 / dedicated retired 표 | 신규 설계 비권장 |
| `cohere.embed-english-v3.0` 등 Embed 3 계열 | dedicated retired 표 | replacement는 `cohere.embed-v4.0` 우선 |
| `meta.llama-3.2-90b-vision` | dedicated retired 표 | replacement는 `Llama 4` 계열 우선 |
| `meta.llama-3.2-11b-vision` | dedicated retired 표 | replacement는 `Llama 4` 계열 우선 |
| `meta.llama-3.1-405b-instruct` | dedicated retired 표 | replacement는 `Llama 4` 계열 우선 |

---

## 9. DAC 유닛별 배포 필요 GPU 메모리 표

중요:

- 아래 9-1은 이름만으로 GPU 메모리를 계산할 수 있는 unit만 넣었다.
- 아래 9-2는 Oracle이 underlying GPU를 공개하지 않는 unit이다.

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
- 아래 표는 Oracle `Compatible Models for Import` 계열 문서에 직접 나온 `Recommended Dedicated AI Cluster Unit Shape`를 우선 반영했다.
- Oracle 문서 공통 메모: 추천 unit이 해당 리전에 없으면 더 높은 tier를 선택하라고 안내한다. 예: `A100`이 없으면 `H100`.

### 10-1. Oracle 문서에 직접 나온 권장 예시

| 용도 | 모델 예시 | Oracle 권장 DAC |
|---|---|---|
| 경량 텍스트 | `microsoft/phi-4` | `A100_80G_X1` |
| 경량 멀티모달 | `google/gemma-3-4b-it` | `A100_80G_X1` |
| 임베딩 | `intfloat/e5-mistral-7b-instruct` | `A10_X1` |
| 중형 텍스트 | `deepseek-ai/DeepSeek-R1-Distill-Qwen-32B` | `A100_80G_X2` |
| 중형 멀티모달 | `google/gemma-3-27b-it` | `A100_80G_X2` |
| Mixtral 계열 | `mistralai/Mixtral-8x7B-Instruct-v0.1` | `A100_80G_X2` |
| 70B 전후 텍스트 | `meta-llama/Llama-3.3-70B-Instruct` | `A100_80G_X4` |
| OpenAI imported | `openai/gpt-oss-20b` | `H100_X1` |
| OpenAI imported | `openai/gpt-oss-120b` | `H100_X2` |
| Meta 멀티모달 | `meta-llama/Llama-4-Scout-17B-16E-Instruct` | `H100_X4` |
| Meta 대형 멀티모달 | `meta-llama/Llama-4-Maverick-17B-128E-Instruct-FP8` | `H100_X8` |
| Phi 비전 | `microsoft/Phi-3-vision-128k-instruct` | `H100_X1` |
| Nemotron 대형 | `nvidia/NVIDIA-Nemotron-3-Super-120B-A12B-BF16` | `H100_X8` |

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
| `meta.llama-3.3-70b-instruct` | 가능 | LoRA, OC1에서 지원. OC4/OC19는 불가 |
| `cohere.command-r-08-2024` | 가능 | 문서상 fine-tuning 가능하지만 retired 표도 함께 확인 필요 |
| `cohere.command-a-03-2025` | 불가 | 모델 카드 기준 |
| `cohere.command-a-vision` | 불가 | 모델 카드 기준 |
| `cohere.command-a-reasoning` | 불가 | 모델 카드 기준 |
| `cohere.embed-v4.0` | 불가 | 모델 카드 기준 |
| `Cohere Rerank 3.5` | 불가 | 모델 카드 기준 |
| `meta.llama-4-scout-17b-16e-instruct` | 불가 | 모델 카드 기준 |
| `meta.llama-4-maverick-17b-128e-instruct-fp8` | 불가 | 모델 카드 기준 |
| `openai.gpt-oss-20b` | 불가 | 모델 카드 기준 |
| `openai.gpt-oss-120b` | 불가 | 모델 카드 기준 |
| `google.gemini-2.5-*` | 불가 | 기능 표 기준 `Tuning: No` |
| `xai.grok-*` | 불가 | Oracle 문서상 tuning 경로 없음, on-demand only |

### 11-2. imported model 기준

| 항목 | Oracle 문서 기준 |
|---|---|
| fine-tuned imported model 지원 | 가능 |
| 조건 | 지원 base model과 transformer version 일치 |
| 조건 | 파라미터 수가 원본 대비 `±10%` 이내 |
| 주의 | 지원 목록에 없는 모델은 production 전 별도 검증 권장 |

### 11-3. retired 관점의 주의

| 모델 | 현재 판단 |
|---|---|
| `meta.llama-3.1-70b-instruct` | retired, 신규 파인튜닝 설계 비권장 |
| `cohere.command-r-16k` | retired, 신규 파인튜닝 설계 비권장 |

---

## 12. A100 / H100 / H200 선택 가이드

| 선택 기준 | A100 80G | H100 | H200 |
|---|---|---|---|
| GPU당 메모리 | 80 GB | 80 GB | 141 GB |
| 관리형 `gpt-oss` 가시성 | `Chicago`, `Phoenix` 중심 | 가장 넓음 | `Riyadh` 확인 |
| imported 모델 권장 빈도 | 높음 | 높음 | 상대적으로 적음 |
| 추천 상황 | 비용/범용성 균형 | 성능/처리량 우선 | 메모리 병목 우선 |
| 주의 | A100 리전 편차 큼 | IaaS 실재고는 별도 확인 필요 | 공식 문서상 공개 리전이 좁음 |

짧게 정리:

- `A100 80G`: imported/custom 시작점으로 가장 범용적이다.
- `H100`: 관리형 `gpt-oss`와 imported 대형 모델에서 선택지가 가장 넓다.
- `H200`: GPU당 메모리 여유가 가장 크지만, 공개 리전 가시성은 가장 좁다.

---

## 13. 모델 강점 요약

| 모델 | 강점 한 줄 요약 |
|---|---|
| `cohere.command-a-03-2025` | 기업형 RAG / tool use / multilingual 범용 챗 |
| `cohere.command-a-vision` | 문서, 차트, 이미지가 섞인 멀티모달 업무 |
| `cohere.command-a-reasoning` | 복합 논리와 긴 문서 reasoning |
| `cohere.embed-v4.0` | 텍스트와 이미지를 아우르는 임베딩 |
| `meta.llama-4-scout` | 작은 GPU footprint와 agentic 활용의 균형 |
| `meta.llama-4-maverick` | 긴 문맥과 강한 코딩/추론 |
| `meta.llama-3.3-70b-instruct` | 관리형 fine-tuning 가능한 대표 텍스트 모델 |
| `openai.gpt-oss-20b` | 빠른 reasoning/coding 반복 |
| `openai.gpt-oss-120b` | 고난도 reasoning 및 production 수준 추론 |
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
- 메모리 병목이 가장 우선이면: `H200` 계열을 검토하되, 공개 리전은 별도 확인

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

### 15-2. 2026-05-10 기준 retired 표에서 다시 확인된 항목

| 모델/계열 | 현재 표 상태 | replacement 방향 |
|---|---|---|
| `Cohere Command R (08-2024)` | on-demand retired / dedicated retired | `Cohere Command A` |
| `Cohere Command R+ (08-2024)` | on-demand retired / dedicated retired | `Cohere Command A` |
| Embed 3 계열 | dedicated retired | `Cohere Embed 4` |
| `Meta Llama 3.2 90B` | dedicated retired | `Meta Llama 4` 계열 |
| `Meta Llama 3.2 11B` | dedicated retired | `Meta Llama 4` 계열 |
| `Meta Llama 3.1 405B` | dedicated retired | `Meta Llama 4` 계열 |

---

## 16. 최종 하단 메모

### 16-1. 사용한 주요 공식 문서 범주

- OCI Generative AI 리전 문서
- OCI Generative AI `Models by Region`
- OCI Generative AI `Dedicated Cluster Shapes by Region`
- OCI Generative AI 개별 모델 카드
- OCI Generative AI imported model 호환성 문서
- OCI Generative AI model retirement 문서
- OCI Data Science `Supported Compute Shapes`
- OCI Data Science `Using GPUs`
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
