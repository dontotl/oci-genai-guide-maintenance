# OCI Generative AI / DAC / AQUA / IaaS GPU 리전·모델 정리 v2

작성일: 2026-04-17  
정리 기준: Oracle 공식 문서 + 현재 테넌시 OCI CLI 조회 시도 결과

이 문서는 아래를 한 번에 보기 좋게 정리한 요약본입니다.

- 리전별 Generative AI / DAC / AQUA 지원 현황
- A100 / H100 보유·활용 관점 정리
- OCI CLI 기준 IaaS GPU shape 조회 방법과 shape-to-GPU 매핑
- 온디맨드 제공 모델 요약
- DAC 배포 단위와 권장 유닛
- 파인튜닝 가능 여부
- 모델 유형별 특징과 강점

가로 폭이 너무 길어지지 않도록 표를 여러 개로 나눴습니다.

---

## 0. 먼저 봐야 하는 전제

### 0-1. 용어

- `DAC`: OCI Generative AI의 Dedicated AI Cluster
- `AQUA`: OCI Data Science의 AI Quick Actions
- `IaaS VM`: OCI Compute / Data Science에서 직접 쓰는 GPU shape

### 0-2. 중요한 제한사항

- Oracle은 `OCI Generative AI`의 **리전별 모델/DAC 표**는 공식 문서로 제공합니다.
- 하지만 `IaaS VM`과 `AQUA(Data Science)`의 **A100/H100 per-region 정적 고정 표**는 한 장으로 제공하지 않습니다.
- `Data Science`/`AQUA` 쪽 GPU 사용 가능 여부는 **리전별 서비스 한도(limit), 실제 host capacity, 예약(reservation) 여부** 영향을 받습니다.
- Oracle 문서상 A100/H100/L40S는 Data Science에서 **예약 기반으로 필요한 경우가 많다**고 보는 것이 안전합니다.
- 이번 정리에서 `oci compute shape list`로 **실제 리전별 IaaS GPU shape 조회를 시도**했지만, 현재 사용 중인 API key / instance principal 모두 `ListShapes` 권한이 없어 자동 수집은 실패했습니다.

즉:

- `DAC`는 리전/모델/유닛 정보를 비교적 명확하게 표로 정리 가능
- `IaaS VM`, `AQUA`는 **지원 shape는 문서화되어 있지만**, 실제 “이 리전에 지금 항상 있다”는 식의 확정 표는 공식적으로 고정 제공되지 않음
- 따라서 `IaaS GPU 리전별 보유 여부`는 **CLI 조회값 + shape 문서 매핑**을 함께 보는 방식이 가장 정확함

### 0-3. 이번 v2에서 추가한 것

- `oci compute shape list`용 실제 명령 예시
- shape 이름을 `V100 / A10 / A100 / H100 / H200 / L40S`로 매핑한 표
- `A100 / H100 / H200 선택 가이드`

---

## 1. 리전별 지원 요약

### 1-1. Generative AI / DAC / AQUA 리전 요약

| 권역 | 리전 | Generative AI 서비스 | DAC | AQUA | 비고 |
|---|---|---|---|---|---|
| SA | Brazil East (Sao Paulo) | 지원 | 지원 | 지원 | 상용 리전 |
| EU | Germany Central (Frankfurt) | 지원 | 지원 | 지원 | 상용 리전 |
| AP | India South (Hyderabad) | 지원 | 지원 | 지원 | 상용 리전 |
| AP | Japan Central (Osaka) | 지원 | 지원 | 지원 | 상용 리전 |
| ME | Saudi Arabia Central (Riyadh) | 지원 | 지원 | 지원 | 상용 리전 |
| ME | UAE East (Dubai) | 지원 | 지원 | 지원 | 상용 리전 |
| EU | UK South (London) | 지원 | 지원 | 지원 | 상용 리전 |
| NA | US East (Ashburn) | 지원 | 지원 | 지원 | 상용 리전 |
| NA | US Midwest (Chicago) | 지원 | 지원 | 지원 | 상용 리전 |
| NA | US West (Phoenix) | 지원 | 지원 | 지원 | 상용 리전 |
| GOV | UK Gov South (London) | 지원 | 모델별 상이 | 지원 | 정부 리전 |
| SOV | EU Sovereign Central (Frankfurt) | 지원 | 모델별 상이 | 문서상 별도 명시 없음 | sovereign 리전 |

### 1-2. 리전별 DAC에서 OpenAI 전용 A/H 계열(OAI_*) 가시성

아래 표는 **`openai.gpt-oss-20b` / `openai.gpt-oss-120b` 모델 카드 기준**으로 확인되는 `OAI_A10 / OAI_A100 / OAI_H100 / OAI_H200` 유닛 가시성입니다.

| 리전 | DAC 지원 | OAI_A10 | OAI_A100 40G | OAI_A100 80G | OAI_H100 | OAI_H200 | 메모 |
|---|---|---|---|---|---|---|---|
| Sao Paulo | 예 | - | - | - | 예 | - | gpt-oss 20b/120b 모두 H100 계열 |
| Frankfurt | 예 | 예 | - | - | 예 | - | 20b는 A10도 가능 |
| Hyderabad | 예 | - | - | - | 예 | - | H100 계열 |
| Osaka | 예 | - | - | - | 예 | - | H100 계열 |
| Riyadh | 예 | - | - | - | - | 예 | H200 계열 |
| Dubai | 예 | 예 | 예 | - | - | - | A10, A100 40G 계열 중심 |
| London | 예 | - | - | - | 예 | - | H100 계열 |
| Ashburn | 예 | 예 | - | - | 예 | - | 20b는 A10 가능 |
| Chicago | 예 | 예 | - | 예 | 예 | - | 가장 선택지가 넓은 편 |
| Phoenix | 예 | - | - | 예 | - | - | A100 80G 계열 |
| UK Gov South | 모델별 상이 | 문서상 확인 어려움 | 문서상 확인 어려움 | 문서상 확인 어려움 | 문서상 확인 어려움 | 문서상 확인 어려움 | 모델별 region page 확인 필요 |
| EU Sovereign Central | 모델별 상이 | 문서상 확인 어려움 | 문서상 확인 어려움 | 문서상 확인 어려움 | 문서상 확인 어려움 | 문서상 확인 어려움 | 모델별 region page 확인 필요 |

### 1-3. IaaS VM / AQUA의 A100 / H100 리전 판정 방법

| 항목 | Oracle 공식 문서 상태 | 실무 해석 |
|---|---|---|
| IaaS VM의 A100/H100 per-region 고정표 | 한 장의 정적 표 없음 | 리전별 shape capacity와 Compute 가용성 확인 필요 |
| AQUA의 A100/H100 per-region 고정표 | 한 장의 정적 표 없음 | AQUA는 Data Science GPU shape를 사용하므로 Data Science limit/capacity/reservation 확인 필요 |
| AQUA 리전 범위 | 상용 + 정부 리전 | sovereign는 별도 확인 필요 |
| Data Science GPU | shape 자체는 지원 | 실제 region availability는 limit/capacity/reservation 영향 |
| A100/H100/L40S | 자주 reservation 필요 | “언제나 즉시 생성 가능”으로 보면 안 됨 |

### 1-4. 리전별 A100 / H100 보유 여부 해석표

아래 표는 사용자 관점에서 많이 묻는 `이 리전에서 A100/H100을 바로 기대할 수 있나?`를 좁게 정리한 것입니다.

| 리전 | DAC A100 | DAC H100 | IaaS VM A100 | IaaS VM H100 | AQUA A100 | AQUA H100 | 메모 |
|---|---|---|---|---|---|---|---|
| Sao Paulo | 아니오 | 예 | 정적표 없음 | 정적표 없음 | 정적표 없음 | 정적표 없음 | DAC는 H100 계열 확인 |
| Frankfurt | 아니오 | 예 | 정적표 없음 | 정적표 없음 | 정적표 없음 | 정적표 없음 | DAC는 A10/H100 계열 중심 |
| Hyderabad | 아니오 | 예 | 정적표 없음 | 정적표 없음 | 정적표 없음 | 정적표 없음 | DAC는 H100 계열 확인 |
| Osaka | 아니오 | 예 | 정적표 없음 | 정적표 없음 | 정적표 없음 | 정적표 없음 | DAC는 H100 계열 확인 |
| Riyadh | 아니오 | 아니오 | 정적표 없음 | 정적표 없음 | 정적표 없음 | 정적표 없음 | DAC는 H200 계열 확인 |
| Dubai | 예 | 아니오 | 정적표 없음 | 정적표 없음 | 정적표 없음 | 정적표 없음 | DAC는 A10/A100 40G 계열 확인 |
| London | 아니오 | 예 | 정적표 없음 | 정적표 없음 | 정적표 없음 | 정적표 없음 | DAC는 H100 계열 확인 |
| Ashburn | 아니오 | 예 | 정적표 없음 | 정적표 없음 | 정적표 없음 | 정적표 없음 | DAC는 A10/H100 계열 중심 |
| Chicago | 예 | 예 | 정적표 없음 | 정적표 없음 | 정적표 없음 | 정적표 없음 | DAC 선택지가 가장 넓음 |
| Phoenix | 예 | 아니오 | 정적표 없음 | 정적표 없음 | 정적표 없음 | 정적표 없음 | DAC는 A100 80G 계열 확인 |
| UK Gov South | 모델별 상이 | 모델별 상이 | 정적표 없음 | 정적표 없음 | 정적표 없음 | 정적표 없음 | 정부 리전은 모델 카드 재확인 필요 |
| EU Sovereign Central | 모델별 상이 | 모델별 상이 | 정적표 없음 | 정적표 없음 | 별도 확인 필요 | 별도 확인 필요 | sovereign 문서 재확인 필요 |

---

## 2. OCI CLI 기준 IaaS GPU shape 조회와 문서 매핑

### 2-1. 리전별 IaaS GPU shape 조회 명령

권한이 있는 계정이라면 아래 명령으로 **각 리전에서 실제로 보이는 GPU shape**를 확인할 수 있습니다.

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

권한이 있으면 `gpu-description`에 GPU 계열이 함께 나오는 경우가 많고, 부족하면 `NotAuthorizedOrNotFound`가 발생할 수 있습니다.

### 2-2. 현재 테넌시에서 확인한 CLI 조회 상태

| 항목 | 결과 |
|---|---|
| `region-subscription list` | 성공 |
| `compute shape list` | 실패 |
| 실패 코드 | `NotAuthorizedOrNotFound` |
| 해석 | 현재 계정/주체에 `Compute ListShapes` 조회 권한 부족 가능성 높음 |

### 2-3. shape 이름과 GPU 모델 매핑

아래 표는 Oracle 문서에 나오는 shape와 실제 GPU 계열 매핑입니다.

| Shape | GPU 계열 | GPU 수 | 총 GPU 메모리 | 비고 |
|---|---|---:|---:|---|
| `VM.GPU3.1` | V100 | 1 | 16 GB | 구세대 단일 GPU |
| `VM.GPU3.2` | V100 | 2 | 32 GB | 구세대 중형 |
| `VM.GPU3.4` | V100 | 4 | 64 GB | 구세대 다중 GPU |
| `BM.GPU3.8` | V100 | 8 | 128 GB | 구세대 bare metal |
| `VM.GPU.A10.1` | A10 | 1 | 24 GB | 소형 추론/경량 튜닝 |
| `VM.GPU.A10.2` | A10 | 2 | 48 GB | 중형 추론 |
| `BM.GPUA10.4` | A10 | 4 | 96 GB | 고밀도 A10 |
| `BM.GPU4.8` | A100 40G | 8 | 320 GB | A100 40GB 세대 |
| `BM.GPU.A100-v2.8` | A100 80G | 8 | 640 GB | A100 80GB 세대 |
| `BM.GPU.H100.8` | H100 80G | 8 | 640 GB | 최신 고성능 |
| `BM.GPU.H200.8` | H200 141G | 8 | 1128 GB | 초고메모리 |
| `BM.GPU.L40S-NC.4` | L40S | 4 | 192 GB | 시각/멀티모달 적합 |

### 2-4. CLI 결과를 문서 표로 바꾸는 법

`compute shape list` 결과에 아래 shape가 보이면 이렇게 해석하면 됩니다.

| CLI에 보이는 shape | 해석 |
|---|---|
| `VM.GPU3.*`, `BM.GPU3.8` | V100 리전 |
| `VM.GPU.A10.*`, `BM.GPUA10.4` | A10 리전 |
| `BM.GPU4.8` | A100 40G 리전 |
| `BM.GPU.A100-v2.8` | A100 80G 리전 |
| `BM.GPU.H100.8` | H100 리전 |
| `BM.GPU.H200.8` | H200 리전 |
| `BM.GPU.L40S-NC.4` | L40S 리전 |

---

## 3. IaaS VM / AQUA에서 볼 수 있는 GPU 재고

`AQUA`는 Data Science GPU shape를 쓰므로, 아래 표는 사실상 **AQUA/DS에서 검토하는 GPU 재고표**로도 보면 됩니다.

### 3-1. Data Science / AQUA GPU shape

| Shape | GPU | GPU 수 | 총 GPU 메모리 | GPU당 메모리 | OCPU | CPU 메모리 | 용도 메모 |
|---|---|---:|---:|---:|---:|---:|---|
| `VM.GPU3.1` | V100 | 1 | 16 GB | 16 GB | 6 | 90 GB | 구형 CUDA 워크로드 |
| `VM.GPU3.2` | V100 | 2 | 32 GB | 16 GB | 12 | 180 GB | 구형 학습/추론 |
| `VM.GPU3.4` | V100 | 4 | 64 GB | 16 GB | 24 | 360 GB | 구형 중형 학습 |
| `VM.GPU.A10.1` | A10 | 1 | 24 GB | 24 GB | 15 | 240 GB | 소형 추론/경량 튜닝 |
| `VM.GPU.A10.2` | A10 | 2 | 48 GB | 24 GB | 30 | 480 GB | 중간급 추론 |
| `BM.GPU3.8` | V100 | 8 | 128 GB | 16 GB | 52 | 768 GB | 구형 대형 학습 |
| `BM.GPUA10.4` | A10 | 4 | 96 GB | 24 GB | 64 | 1024 GB | 멀티모델/AQUA 고밀도 |
| `BM.GPU4.8` | A100 | 8 | 320 GB | 40 GB | 64 | 2048 GB | 구형 A100 40G 계열 |
| `BM.GPU.A100-v2.8` | A100 | 8 | 640 GB | 80 GB | 64 | 2048 GB | 대형 모델/긴 컨텍스트 |
| `BM.GPU.H100.8` | H100 | 8 | 640 GB | 80 GB | 112 | 2048 GB | 최신 고성능 추론/배포 |
| `BM.GPU.H200.8` | H200 | 8 | 1128 GB | 141 GB | 112 | 3072 GB | 초대형/장문맥/고메모리 |
| `BM.GPU.L40S-NC.4` | L40S | 4 | 192 GB | 48 GB | 112 | 1024 GB | 시각/멀티모달/비용 절충 |

### 3-2. IaaS Compute Bare Metal GPU shape

| Shape | GPU | 총 GPU 메모리 | 네트워크/RDMA 메모 |
|---|---|---:|---|
| `BM.GPU3.8` | 8x V100 | 128 GB | 구형 bare metal GPU |
| `BM.GPU4.8` | 8x A100 | 320 GB | 8 x 200 Gbps RDMA |
| `BM.GPU.A100-v2.8` | 8x A100 | 640 GB | 16 x 100 Gbps RDMA |
| `BM.GPU.H100.8` | 8x H100 | 640 GB | H100 계열 고성능 bare metal |

---

## 4. 온디맨드 + 전용(DAC) 실무 핵심 모델

폭을 줄이기 위해 실무에서 많이 비교하는 **핵심 모델 위주**로 먼저 정리했습니다.

### 4-1. 종합 / 멀티모달 / 추론 / 임베딩

| 모델 | 유형 | 파라미터 / 컨텍스트 | 온디맨드 | DAC 배포 유닛 | FT | 강한 부분 |
|---|---|---|---|---|---|---|
| `cohere.command-a-03-2025` | 종합, 에이전트 | 256k 컨텍스트 | 예 | `LARGE_COHERE_V3 x1` (Dubai: `SMALL_COHERE_4 x1`) | 불가 | RAG, tool use, agent, 멀티링구얼 |
| `cohere.command-a-vision` | 멀티모달 | 112B, 128k | 일부 리전 예 | `LARGE_COHERE_V3 x1` (Dubai: `SMALL_COHERE_4 x1`) | 불가 | 문서/차트/이미지 이해 |
| `cohere.embed-v4.0` | 임베딩 | 1536-d, 입력 총합 128k | 예 | `EMBED_COHERE x1` | 불가 | 텍스트/이미지 임베딩, 검색 |
| `meta.llama-4-scout-17b-16e-instruct` | 멀티모달, 종합 | 17B active / ~109B total, 192k | Chicago만 예 | `LARGE_GENERIC_V2 x1` | 불가 | 긴 문맥, 멀티모달, 경량 배포 |
| `meta.llama-4-maverick-17b-128e-instruct-fp8` | 멀티모달, 종합 | 17B active / ~400B total, 512k | Chicago만 예 | `LARGE_GENERIC_2 x1` | 불가 | 코딩/추론 성능, 초장문 문맥 |
| `openai.gpt-oss-20b` | 추론, 에이전트 | 21B, 128k | 예 | 지역별 `OAI_A10_X2` / `OAI_A100_40G_X1` / `OAI_A100_80G_X1` / `OAI_H100_X1` / `OAI_H200_X1` | 불가 | STEM, 코딩, 빠른 반복 |
| `openai.gpt-oss-120b` | 추론, 에이전트 | 117B, 128k | 예 | 지역별 `OAI_A100_40G_X4` / `OAI_A100_80G_X2` / `OAI_H100_X2` / `OAI_H200_X1` | 불가 | 고난도 추론, production급 reasoning |
| `google.gemini-2.5-pro` | 멀티모달, 추론 | 1M context | 예, 온디맨드 전용 | N/A | 튜닝 불가 | 복잡한 문제 해결, 과학/수학/코드 |
| `google.gemini-2.5-flash` | 멀티모달, 종합 | 공개 파라미터 미기재 | 예, 온디맨드 전용 | N/A | 불가(문서상 tuning 없음) | 속도/지능 균형 |
| `google.gemini-2.5-flash-lite` | 멀티모달, 경량 | 공개 파라미터 미기재 | 예, 온디맨드 전용 | N/A | 불가 | 저비용, 고속, 대량 처리 |
| `xai.grok-code-fast-1` | 에이전트 코딩 | 256k | 예, 온디맨드 전용 | N/A | 불가 | tool-use 중심 agentic coding |

### 4-2. 전용(DAC) 중심 모델

| 모델 | 유형 | 파라미터 / 컨텍스트 | 온디맨드 | DAC 배포 유닛 | FT | 강한 부분 |
|---|---|---|---|---|---|---|
| `cohere.command-a-reasoning` | 추론, 에이전트 | 111B, 256k | 사실상 DAC 중심 | `LARGE_COHERE_V2_2 x1` (Dubai: `SMALL_COHERE_4 x1`) | 불가 | 복합 추론, 문서 리뷰, 구조화 논증 |
| `cohere.rerank.v3-5` | 리랭크 | query + text list | 불가 | `RERANK_COHERE x1` | 불가 | 검색 후 재정렬, relevance scoring |

### 4-3. DAC 유닛별 배포 필요 GPU 메모리 감

이 표는 모델 카드에 나오는 `권장 DAC 유닛`을 실제 GPU 메모리 기준으로 짧게 해석한 것입니다.

| DAC 유닛 | 대응 GPU | 총 GPU 메모리 | 적합한 용도 |
|---|---|---:|---|
| `OAI_A10_X2` | 2x A10 | 48 GB | 경량 추론, 20B급 시작점 |
| `OAI_A100_40G_X1` | 1x A100 40G | 40 GB | 20B급 최소 배포 |
| `OAI_A100_40G_X4` | 4x A100 40G | 160 GB | 120B급 최소 배포 |
| `OAI_A100_80G_X1` | 1x A100 80G | 80 GB | 20B급 여유 운영 |
| `OAI_A100_80G_X2` | 2x A100 80G | 160 GB | 120B급 표준 시작점 |
| `OAI_H100_X1` | 1x H100 | 80 GB | 20B급 고성능 추론 |
| `OAI_H100_X2` | 2x H100 | 160 GB | 120B급 고성능 추론 |
| `OAI_H200_X1` | 1x H200 | 141 GB | 메모리 여유가 필요한 대형 추론 |
| `A100_80G_X1` | 1x A100 80G | 80 GB | 경량 import/custom |
| `A100_80G_X4` | 4x A100 80G | 320 GB | 70B급 imported model |
| `H100_X1` | 1x H100 | 80 GB | gpt-oss-20b import 권장 |
| `H100_X2` | 2x H100 | 160 GB | gpt-oss-120b import 권장 |
| `H100_X4` | 4x H100 | 320 GB | Llama 4 Scout import 권장 |
| `H100_X8` | 8x H100 | 640 GB | Llama 4 Maverick import 권장 |

---

## 5. 온디맨드/전용 여부를 빠르게 보는 요약표

### 5-1. 서비스 모드 관점

| 모델 | 온디맨드 | DAC | 비고 |
|---|---|---|---|
| Cohere Command A | 예 | 예 | 가장 범용적인 Cohere chat |
| Cohere Command A Vision | 일부 리전 예 | 예 | 멀티모달 |
| Cohere Command A Reasoning | 제한적 / DAC 중심 | 예 | reasoning 특화 |
| Cohere Embed 4 | 예 | 예 | 임베딩 |
| Cohere Rerank 3.5 | 아니오 | 예 | 전용 리랭크 |
| Meta Llama 4 Scout | Chicago만 예 | 예 | 장문맥/경량 |
| Meta Llama 4 Maverick | Chicago만 예 | 예 | 장문맥/상위급 추론 |
| OpenAI gpt-oss-20b | 예 | 예 | reasoning/agentic |
| OpenAI gpt-oss-120b | 예 | 예 | 고난도 reasoning |
| Google Gemini 2.5 계열 | 예 | 아니오 | 외부 호스팅 / on-demand only |
| xAI Grok 계열 | 예 | 아니오 | on-demand only |

---

## 6. Import / Custom Deployment 기준 권장 DAC

이 섹션은 **“Oracle이 관리하는 내장 온디맨드 모델”**이 아니라,  
`OCI Generative AI Imported Models` 기준에서 **오픈모델/커스텀 엔드포인트 배포 시 참고하는 DAC 권장값**입니다.

### 6-1. OpenAI 계열 import

| Hugging Face ID | Capability | 권장 DAC |
|---|---|---|
| `openai/gpt-oss-20b` | TEXT_TO_TEXT | `H100_X1` |
| `openai/gpt-oss-120b` | TEXT_TO_TEXT | `H100_X2` |

### 6-2. Meta 계열 import

| Hugging Face ID | Capability | 권장 DAC |
|---|---|---|
| `meta-llama/Llama-4-Maverick-17B-128E-Instruct-FP8` | IMAGE_TEXT_TO_TEXT | `H100_X8` |
| `meta-llama/Llama-4-Scout-17B-16E-Instruct` | IMAGE_TEXT_TO_TEXT | `H100_X4` |
| `meta-llama/Llama-3.3-70B-Instruct` | TEXT_TO_TEXT | `A100_80G_X4` |
| `meta-llama/Llama-3.2-3B-Instruct` | TEXT_TO_TEXT | `A100_80G_X1` |
| `meta-llama/Llama-3.2-1B-Instruct` | TEXT_TO_TEXT | `A100_80G_X1` |

### 6-3. Import 모델의 튜닝 관련 메모

| 항목 | 정리 |
|---|---|
| Fine-tuned imported model 지원 | 가능 |
| 조건 | base transformer 버전이 맞고, 파라미터 수가 원본 대비 ±10% 이내여야 함 |
| 컨텍스트 | native context를 쓰지만, 실제 usable length는 하드웨어에 영향 받음 |
| 권장 shape가 없을 때 | Oracle 문서상 A100이 없으면 한 단계 높은 shape(H100 등) 선택 권장 |

---

## 7. 파인튜닝 관점 정리

### 7-1. OCI Generative AI (내장 모델 카드 기준)

아래 핵심 모델들은 모델 카드 기준으로 모두 **“Not available for fine-tuning”** 입니다.

- Cohere Command A
- Cohere Command A Vision
- Cohere Command A Reasoning
- Cohere Embed 4
- Cohere Rerank 3.5
- Meta Llama 4 Scout
- Meta Llama 4 Maverick
- OpenAI gpt-oss-20b
- OpenAI gpt-oss-120b

즉, **내장 모델을 그대로 DAC에 올려 운영하는 것은 가능하지만**,  
해당 카드 기준으로는 **OCI Generative AI managed base model 자체를 직접 fine-tune 하는 경로는 대부분 제공되지 않습니다.**

### 7-2. AQUA / Data Science 관점

`AQUA`는 Data Science notebook 안에서 foundation model을 **배포 / 평가 / 파인튜닝**할 수 있도록 설계되어 있습니다.

정리:

- AQUA는 상용 + 정부 리전에서 사용 가능
- AQUA는 Data Science GPU shape를 사용
- 모델별 정확한 “권장 GPU shape”를 Oracle이 한 장의 정적 표로 제공하지는 않음
- Oracle 튜토리얼에는 open-source LLM fine-tuning을 `A10` GPU shape로 수행하는 예가 있음
- AI Quick Actions v2.0 릴리즈에는 `Llama 4 fine-tuning support` 추가가 명시됨

실무 해석:

- 경량 / LoRA / 작은 instruct 모델: A10부터 검토
- 70B급 이상 또는 멀티모달/초장문맥: A100 80G 이상 검토
- Llama 4 Maverick, gpt-oss-120b 급 커스텀/수입 모델: H100 이상부터 검토

### 7-3. A100 / H100 / H200 선택 가이드

| 기준 | A100 80G | H100 80G | H200 141G |
|---|---|---|---|
| 추천 상황 | 70B 전후, 안정 운영 | 최신 추론, 빠른 응답 | 초고메모리, 초장문맥 |
| 장점 | 비용 대비 균형 | 연산 성능 우수 | 메모리 여유 최고 |
| 추천 용도 | 일반 대형 LLM, FT, serving | reasoning, MoE, 멀티모달 | 매우 큰 imported 모델 |
| 시작 판단 | 예산 중시 | 성능 중시 | 메모리 병목 해소 |
| 실무 메모 | 가장 무난한 표준 | 최신 워크로드 우선 검토 | region/capacity 제약 주의 |

---

## 8. 모델별 강점 한 줄 정리

| 분류 | 추천 모델 | 잘하는 부분 |
|---|---|---|
| 종합형 업무/에이전트 | Cohere Command A | RAG, tool use, enterprise agent |
| 추론 특화 | Cohere Command A Reasoning / gpt-oss-120b | 논리 추론, 긴 문서 reasoning |
| 빠른 reasoning / 코딩 | gpt-oss-20b | 코딩, STEM, 빠른 반복 |
| 멀티모달 문서 해석 | Cohere Command A Vision | 차트/문서/이미지 인사이트 |
| 멀티모달 장문맥 | Llama 4 Scout / Maverick | 초장문맥, 멀티모달, 코드 |
| 검색 임베딩 | Cohere Embed 4 | 텍스트+이미지 임베딩 |
| 검색 후 재정렬 | Cohere Rerank 3.5 | relevance scoring |
| 초대형 reasoning SaaS | Gemini 2.5 Pro | 1M context, complex reasoning |
| 저비용 고속 멀티모달 | Gemini 2.5 Flash / Flash-Lite | latency, cost efficiency |
| 에이전트 코딩 | xAI Grok Code Fast 1 | tool use, repo edits, coding loop |

---

## 9. 빠른 추천

### 9-1. 바로 써보기

| 목적 | 추천 |
|---|---|
| 가장 빨리 시작 | `gpt-oss-20b` on-demand |
| 복잡한 reasoning | `gpt-oss-120b` 또는 `Gemini 2.5 Pro` |
| enterprise RAG/agent | `Cohere Command A` |
| 문서/이미지 이해 | `Cohere Command A Vision` |
| 장문맥 멀티모달 | `Llama 4 Maverick` |
| 벡터 검색 | `Cohere Embed 4` |
| rerank | `Cohere Rerank 3.5` |

### 9-2. GPU 선택 감

| 규모 | 권장 시작점 |
|---|---|
| 소형 추론 / 빠른 실험 | A10 |
| 70B 전후 / 안정 운영 | A100 80G |
| 초장문맥 / MoE / 대형 reasoning | H100 |
| 매우 큰 multimodal / imported 대형 모델 | H100 ~ H200 |

---

## 10. 출처로 사용한 공식 문서

- Generative AI Regions
- Generative AI Models by Region
- Generative AI Dedicated Cluster Shapes by Region
- Managing Dedicated AI Clusters
- OpenAI gpt-oss-20b
- OpenAI gpt-oss-120b
- Cohere Command A
- Cohere Command A Vision
- Cohere Command A Reasoning
- Cohere Embed 4
- Cohere Rerank 3.5
- Meta Llama 4 Scout
- Meta Llama 4 Maverick
- Google Gemini 2.5 Pro / Flash / Flash-Lite
- xAI Grok Code Fast 1
- About AI Quick Actions
- Supported Compute Shapes (Data Science)
- Compute Shapes (OCI Compute)
- Supported OpenAI Models (Imported Models)
- Supported Meta Models (Imported Models)

---

## 11. 마지막 메모

이 문서는 **리전·배포·모델 비교용 운영 메모**입니다.  
실제 생성 전에 반드시 아래 3가지를 추가 확인하세요.

1. 해당 리전의 현재 host capacity
2. tenancy service limit
3. 모델 카드의 최신 region / mode / retirement 상태
