# OCI Generative AI / DAC / AQUA / IaaS GPU 리전·모델 가이드 v2

최종 업데이트: 2026-05-17 (GMT)  
Oracle 공식 문서 확인 기준일: 2026-05-17 (GMT)  
산출물 경로: `/home/opc/oci-genai-guide-maintenance/runs/OCI_GenAI_Regional_Model_Guide_v2_2026-05-17.md`

이 문서는 `LATEST.md`로 복사될 수 있음을 전제로, 앞 1페이지 안에 이번 변경점과 판정 기준을 먼저 배치했다.

---

## 이번 업데이트 변화 요약

- `2026-05-11` 기준, OCI Generative AI의 import 호환 모델이 추가되었다.
  - Alibaba Qwen: `Qwen/Qwen3.6-35B-A3B`, `Qwen/Qwen3.5-9B`
  - Google Gemma: `google/gemma-4-31B-it`
- `2026-05-09` 기준, `Cohere Rerank 4`가 OCI Generative AI에 추가되었다.
  - `Pro`와 `Fast` 두 변형이 문서에 분리되어 있으며, 지원 리전과 DAC 하드웨어도 공개되었다.
- `2026-05-09` 기준, `Cohere Embed 4`는 가변 임베딩 차원(`256/512/1024/1536`)과 텍스트+이미지 혼합 입력을 지원하도록 문서가 확장되었다.
- `2026-05-05` 기준, `UAE Central (Abu Dhabi)`가 OCI Generative AI 리전에 추가되었다.
- `2026-05-01` 기준, `xAI Grok 4.3`가 추가되었다.
- 현재 retirement/deprecation 문서 기준으로 앞에서 먼저 주의할 모델은 다음과 같다.
  - `Cohere Command R (08-2024)`, `Cohere Command R+ (08-2024)`: on-demand/dedicated 모두 `2026-09-30`
  - `Cohere Embed 3` 계열과 `Cohere Embed Image 3` 계열: `2026-09-30`
  - `Meta Llama 3.2 90B Vision`, `Meta Llama 3.2 11B`, `Meta Llama 3.1 405B`: `2026-09-30`
  - 구세대 xAI Grok 다수(`Grok 4`, `Grok 4 Fast`, `Grok 4.1 Fast`, `Grok Code Fast 1`, `Grok 3` 계열): on-demand retirement가 `2026-08-15`
- 이번 문서 생성 시 OCI CLI 실조회는 성공하지 못했다.
  - `region-subscription list`와 `compute shape list`는 모두 이 환경에서 시간 초과로 끝났다.
  - 추가 확인용 `getent hosts identity.ap-seoul-1.oci.oraclecloud.com` 및 `getent hosts iaas.us-chicago-1.oraclecloud.com`는 둘 다 빈 결과(`exit 2`)였다.
  - 따라서 `IaaS/AQUA GPU 재고표`는 실시간 재고표가 아니라 Oracle 문서 기준 해석표로 대체했다.

---

## 0. 전제와 판정 원칙

### 0-1. 용어

- `Generative AI`: OCI Generative AI 관리형 서비스
- `DAC`: Dedicated AI Cluster
- `AQUA`: OCI Data Science AI Quick Actions
- `IaaS GPU`: OCI Compute / OCI Data Science에서 직접 쓰는 GPU shape
- `관리형 기본 모델`: Oracle이 호스팅하는 pretrained foundation model
- `imported model`: Hugging Face 또는 Object Storage에서 가져와 DAC에 배포하는 모델
- `custom model`: Oracle이 제공한 base model을 fine-tuning해서 만든 모델

### 0-2. 작성 규칙

- Oracle 공식 문서에 있는 사실만 확정적으로 적었다.
- Oracle 문서에 없으면 `문서상 명시 없음`, `미공개`, `실시간 재고표 없음`으로 적었다.
- `관리형 기본 모델`, `imported model`, `custom model`은 서로 혼동하지 않았다.
- `리전별 DAC A10/A100/H100/H200 가시성`은 Oracle이 하드웨어 unit을 직접 공개한 `OpenAI gpt-oss` 관리형 모델 문서를 기준으로 판정했다.
- `Large Generic`, `LARGE_COHERE_*`, `SMALL_COHERE_*`, `Embed Cohere`, `RERANK_COHERE`의 실제 GPU 종류와 GPU 메모리는 Oracle이 공개하지 않았으므로 단정하지 않았다.
- `AQUA 지원`과 `즉시 GPU 할당 가능`은 같은 뜻이 아니다.
- `지원 shape 존재`와 `실시간 재고 존재`도 같은 뜻이 아니다.

---

## 1. CLI 조회 성공/실패 상태

### 1-1. 실행 상태 표

| 항목 | 실행 명령 | 상태 | 관찰 결과 |
|---|---|---|---|
| CLI 버전 | `oci --version` | 성공 | `3.81.1` |
| 기본 CLI region 확인 | `awk -F= '/^region=/{print $2; exit}' ~/.oci/config` | 성공 | `ap-seoul-1` |
| 구독 리전 조회 | `oci iam region-subscription list --all` | 실패 | 8초/12초 제한 재시도에서 응답 없이 종료 |
| GPU shape 조회 | `oci compute shape list --all -c <tenancy_ocid> --region us-chicago-1` | 실패 | 8초/12초 제한 재시도에서 응답 없이 종료 |
| identity endpoint 해석 | `getent hosts identity.ap-seoul-1.oci.oraclecloud.com` | 실패 | 빈 결과, `exit 2` |
| iaas endpoint 해석 | `getent hosts iaas.us-chicago-1.oraclecloud.com` | 실패 | 빈 결과, `exit 2` |

### 1-2. 실패 이유 해석

| 항목 | 확인 내용 | 문서 반영 방식 |
|---|---|---|
| `region-subscription list` | `oci --debug` 로그상 `https://identity.ap-seoul-1.oci.oraclecloud.com/.../regionSubscriptions`로 반복 GET 시도 후 시간 초과 | Oracle `Generative AI Regions` 문서 기준 표로 대체 |
| `compute shape list` | `oci --debug` 로그상 `https://iaas.us-chicago-1.oraclecloud.com/20160918/shapes`로 반복 GET 시도 후 시간 초과 | Oracle `Compute Shapes` / `Supported Compute Shapes` 문서 기준 표로 대체 |
| 추가 진단 | 두 endpoint 모두 `getent hosts`가 빈 결과였다 | 본 환경에서는 DNS/egress/endpoint reachability 문제 가능성이 높다고 표시하고, 실시간 재고판정은 하지 않음 |

정리:

- 이 환경에서는 CLI 자격증명 파일과 요청 URL 생성까지는 진행되었다.
- 그러나 실제 endpoint 응답을 받지 못했다.
- 따라서 아래 `IaaS / AQUA GPU 재고표`는 실측 재고가 아니라 Oracle 문서 기반 해석표다.

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

짧은 해석:

- `Generative AI Regions` 문서는 상용 11개, 정부 1개, 소버린 1개 리전을 공개한다.
- `About AI Quick Actions` 문서는 AQUA를 `all commercial and government regions`로 명시한다.
- EU Sovereign에 대한 AQUA 지원은 이번 확인 문서에서 명시를 찾지 못했다.

---

## 3. 리전별 DAC A10 / A100 / H100 / H200 가시성

판정 기준:

- 이 표는 `OpenAI gpt-oss-20b` 및 `OpenAI gpt-oss-120b` 관리형 모델 문서에 공개된 `OAI_*` hardware unit만 사용했다.
- `Large Generic`, `Large Cohere`, `Small Cohere`는 underlying GPU가 공개되지 않아 이 표에 쓰지 않았다.

### 3-1. 북미 / 남미

| 리전 | A10 | A100 40G | A100 80G | H100 | H200 | 근거 메모 |
|---|---|---|---|---|---|---|
| Brazil East (Sao Paulo) | - | - | - | 예 | - | `gpt-oss-20b: OAI_H100_X1`, `120b: OAI_H100_X2` |
| US East (Ashburn) | 예 | - | - | 예 | - | `20b: OAI_A10_X2 / OAI_H100_X1`, `120b: OAI_H100_X2` |
| US Midwest (Chicago) | 예 | - | 예 | 예 | - | `A10 / A100_80G / H100` 모두 공개 |
| US West (Phoenix) | - | - | 예 | - | - | `20b: OAI_A100_80G_X1`, `120b: OAI_A100_80G_X2` |

### 3-2. 유럽 / 중동 / 아시아

| 리전 | A10 | A100 40G | A100 80G | H100 | H200 | 근거 메모 |
|---|---|---|---|---|---|---|
| Germany Central (Frankfurt) | 예 | - | - | 예 | - | `20b: A10 또는 H100`, `120b: H100` |
| India South (Hyderabad) | - | - | - | 예 | - | `20b/120b` 모두 `H100` 공개 |
| Japan Central (Osaka) | - | - | - | 예 | - | `20b/120b` 모두 `H100` 공개 |
| Saudi Arabia Central (Riyadh) | - | - | - | - | 예 | `20b: OAI_H200_X1`, `120b: OAI_H200_X1` |
| UAE East (Dubai) | 예 | 예 | - | - | - | `20b: A10 또는 A100 40G`, `120b: A100 40G` |
| UAE Central (Abu Dhabi) | - | - | - | - | - | Generative AI 리전 문서에는 있으나 `gpt-oss` hardware row는 미공개 |
| UK South (London) | - | - | - | 예 | - | `20b/120b` 모두 `H100` 공개 |

### 3-3. 정부 / 소버린

| 리전 | A10 | A100 40G | A100 80G | H100 | H200 | 메모 |
|---|---|---|---|---|---|---|
| UK Gov South (London) | 문서상 미확인 | 문서상 미확인 | 문서상 미확인 | 문서상 미확인 | 문서상 미확인 | 이번 확인 범위의 `gpt-oss` 관리형 문서에서 hardware row 미확인 |
| EU Sovereign Central (Frankfurt) | 문서상 미확인 | 문서상 미확인 | 문서상 미확인 | 문서상 미확인 | 문서상 미확인 | 이번 확인 범위의 `gpt-oss` 관리형 문서에서 hardware row 미확인 |

짧은 해석:

- 관리형 `gpt-oss` 기준으로 가장 넓게 공개된 계열은 `H100`이다.
- `H200`은 이번 확인 기준에서 `Riyadh`만 Oracle 문서상 공개된다.
- `A100 80G`는 `Chicago`, `Phoenix`에서 공개된다.
- `A100 40G`는 `Dubai`에서 공개된다.
- `Abu Dhabi`는 서비스 리전에는 포함되지만, 공개된 `OAI_*` hardware 가시성은 아직 확인되지 않았다.

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

- 명령 자체는 유효한 OCI CLI 명령이다.
- 하지만 이번 환경에서는 두 명령 모두 endpoint 응답을 받지 못해 시간 초과로 종료되었다.
- 추가로 같은 호스트를 `getent hosts`로 조회했을 때도 결과가 없었다.
- 따라서 아래 GPU 표들은 Oracle 문서상 지원 shape와 unit 표로 대체했다.

### 4-3. 결과 해석 규칙

| CLI에 보이는 shape | 해석 |
|---|---|
| `VM.GPU3.*`, `BM.GPU3.8` | V100 계열 |
| `VM.GPU.A10.*`, `BM.GPUA10.4` | A10 계열 |
| `BM.GPU4.8` | A100 40GB 계열 |
| `BM.GPU.A100-v2.8` | A100 80GB 계열 |
| `BM.GPU.H100.8` | H100 계열 |
| `BM.GPU.H200.8` | H200 계열 |

---

## 5. shape-to-GPU 매핑

### 5-1. OCI Compute VM GPU shapes

| Shape | GPU | GPU 수 | 총 GPU 메모리 | OCPU | CPU 메모리 |
|---|---|---:|---:|---:|---:|
| `VM.GPU3.1` | V100 | 1 | 16 GB | 6 | 90 GB |
| `VM.GPU3.2` | V100 | 2 | 32 GB | 12 | 180 GB |
| `VM.GPU3.4` | V100 | 4 | 64 GB | 24 | 360 GB |
| `VM.GPU.A10.1` | A10 | 1 | 24 GB | 15 | 240 GB |
| `VM.GPU.A10.2` | A10 | 2 | 48 GB | 30 | 480 GB |

### 5-2. OCI Compute bare metal GPU shapes

| Shape | GPU | GPU 수 | 총 GPU 메모리 | OCPU | CPU 메모리 |
|---|---|---:|---:|---:|---:|
| `BM.GPU3.8` | V100 | 8 | 128 GB | 52 | 768 GB |
| `BM.GPU4.8` | A100 40GB | 8 | 320 GB | 64 | 2048 GB |
| `BM.GPUA10.4` | A10 | 4 | 96 GB | 64 | 1024 GB |
| `BM.GPU.A100-v2.8` | A100 80GB | 8 | 640 GB | 128 | 2048 GB |
| `BM.GPU.H100.8` | H100 | 8 | 640 GB | 112 | 2048 GB |
| `BM.GPU.H200.8` | H200 | 8 | 1128 GB | 112 | 3072 GB |

### 5-3. OCI Data Science / AQUA에서 문서상 지원하는 GPU shapes

| Shape | GPU | GPU 수 | 총 GPU 메모리 | 메모 |
|---|---|---:|---:|---|
| `VM.GPU.A10.1` | A10 | 1 | 24 GB | 지원 |
| `VM.GPU.A10.2` | A10 | 2 | 48 GB | 지원 |
| `BM.GPUA10.4` | A10 | 4 | 96 GB | 지원 |
| `BM.GPU4.8` | A100 | 8 | 320 GB | 지원 |
| `BM.GPU.A100-v2.8` | A100 | 8 | 640 GB | 지원 |
| `BM.GPU.H100.8` | H100 | 8 | 640 GB | 지원 |
| `BM.GPU.H200.8` | H200 | 8 | 1128 GB | 지원 |

메모:

- Oracle Compute 문서와 Data Science 문서는 핵심 A10/A100/H100/H200 계열에서 수치가 일관된다.
- L40S 계열은 Compute 문서와 Data Science 문서에서 shape 명칭 표기가 다르므로 본 문서의 핵심 비교에서는 제외했다.

---

## 6. IaaS / AQUA GPU 재고표

중요:

- Oracle 공식 문서는 `리전별 실시간 GPU 재고 수량표`를 제공하지 않는다.
- 따라서 이 절은 `재고 수량표`가 아니라 `문서상 지원 여부와 확보 난이도 해석표`다.

### 6-1. 문서상 지원 / 확보 해석표

| GPU 계열 | Compute 문서상 shape | Data Science / AQUA 문서상 지원 | 확보 해석 |
|---|---|---|---|
| A10 | `VM.GPU.A10.*`, `BM.GPUA10.4` | 지원 | 일부 리전에서는 reservation 없이 가능한 경우가 있다고 문서에 명시 |
| A100 40G | `BM.GPU4.8` | 지원 | Data Science 문서상 A100은 종종 Compute reservation 경유 필요 |
| A100 80G | `BM.GPU.A100-v2.8` | 지원 | Data Science 문서상 A100은 종종 Compute reservation 경유 필요 |
| H100 | `BM.GPU.H100.8` | 지원 | Data Science 문서상 H100은 종종 Compute reservation 경유 필요 |
| H200 | `BM.GPU.H200.8` | 지원 | 지원 shape는 문서에 있으나 reservation/재고 관행은 이번 확인 범위에서 명시 없음 |

### 6-2. 운영 해석 메모

| 항목 | 문서 기준 해석 |
|---|---|
| AQUA 접근 자체 | CPU notebook만으로도 가능 |
| AQUA 내부 배포/파인튜닝 | 모델에 따라 GPU shape가 필요 |
| Data Science limit | shape capacity와 동일 개념이 아님 |
| `Out of host capacity` | limit가 있어도 실제 shape availability가 없으면 발생 가능 |
| A10 | 일부 리전에서 reservation 없이 가능 |
| A100 / H100 / L40S | Data Science 문서상 종종 Compute reservation이 필요 |

---

## 7. 온디맨드 핵심 모델 표

### 7-1. 주력 chat / multimodal / reasoning 모델

| 모델 | OCI 모델명 | 모드 | 컨텍스트 | 입력/출력 | 핵심 포인트 |
|---|---|---|---|---|---|
| Google Gemini 2.5 Pro | `google.gemini-2.5-pro` | on-demand only | 1M | 텍스트/코드/이미지/문서/오디오/비디오 → 텍스트 | 복잡한 추론, 과학/코드, 대형 문서/멀티모달 |
| Google Gemini 2.5 Flash | `google.gemini-2.5-flash` | on-demand only | 1M | 텍스트/코드/이미지/문서/오디오/비디오 → 텍스트 | 속도/성능 균형, 일반 사용자 앱 |
| Google Gemini 2.5 Flash-Lite | `google.gemini-2.5-flash-lite` | on-demand only | 1M | 텍스트/코드/이미지/문서/오디오/비디오 → 텍스트 | 저비용, 고처리량, 분류/요약/라우팅 |
| xAI Grok 4.3 | `xai.grok-4.3` | on-demand only | 1M | 텍스트+이미지 → 텍스트 | 정확도 중심 reasoning, 수학/과학/다단계 조사 |
| xAI Grok 4.20 | `xai.grok-4.20-0309-reasoning` / `...-non-reasoning` | on-demand only | 2M | 텍스트+이미지 → 텍스트 | reasoning / non-reasoning 이원화, agentic tool-calling |
| xAI Grok 4.20 Multi-Agent | `xai.grok-4.20-multi-agent` | on-demand only(API 전용) | 2M | 텍스트+이미지 → 텍스트 | 다중 에이전트 리서치 orchestration |
| OpenAI gpt-oss-20b | `openai.gpt-oss-20b` | on-demand + dedicated | 128K | 텍스트 → 텍스트 | 저지연 reasoning, STEM/코딩, 작은 footprint |
| OpenAI gpt-oss-120b | `openai.gpt-oss-120b` | on-demand + dedicated | 128K | 텍스트 → 텍스트 | 생산형 reasoning, STEM/코딩, 더 큰 추론량 |
| Meta Llama 3.3 70B (Standard) | `meta.llama-3.3-70b-instruct` | on-demand + dedicated + fine-tuning | 128K | 텍스트 → 텍스트 | reasoning/coding/math 개선, fine-tuning 가능 |
| Meta Llama 4 Scout | `meta.llama-4-scout-17b-16e-instruct` | on-demand(Chicago) + dedicated | 192K | 텍스트+이미지 → 텍스트 | 작은 GPU footprint, 멀티모달 |
| Meta Llama 4 Maverick | `meta.llama-4-maverick-17b-128e-instruct-fp8` | on-demand(Chicago) + dedicated | 512K | 텍스트+이미지 → 텍스트 | 멀티모달, 대형 컨텍스트, 코딩/추론 |
| Cohere Command A | `cohere.command-a-03-2025` | on-demand 및 dedicated(리전별) | 256K | 텍스트 → 텍스트 | tool use, agents, RAG, multilingual |
| Cohere Command A Vision | `cohere.command-a-vision` | on-demand 및 dedicated(리전별) | 128K | 텍스트+이미지 → 텍스트 | 문서/차트/이미지 해석 |
| Cohere Command A Reasoning | `cohere.command-a-reasoning` | on-demand 및 dedicated(리전별, 일부 dedicated only) | 256K | 텍스트+이미지 → 텍스트 | 고급 reasoning, agentic workflow, grounded citation |

### 7-2. 임베딩 / 리랭크

| 모델 | OCI 모델명 | 모드 | 파인튜닝 | 핵심 포인트 |
|---|---|---|---|---|
| Cohere Embed 4 | `cohere.embed-v4.0` | on-demand + dedicated | 불가 | 가변 차원, 텍스트/이미지 멀티모달 임베딩 |
| Cohere Rerank 4 Pro | `cohere.rerank-v4.0-pro` | on-demand 일부 + dedicated 일부 | 불가 | 품질 우선 리랭크 |
| Cohere Rerank 4 Fast | `cohere.rerank-v4.0-fast` | on-demand 일부 + dedicated 일부 | 불가 | 지연/처리량 우선 리랭크 |

---

## 8. DAC 중심 모델 표

### 8-1. 관리형 기본 모델 DAC 요약

| 모델 | Hosting DAC unit | 파인튜닝 | 메모 |
|---|---|---|---|
| Cohere Command A | `LARGE_COHERE_V3` | 불가 | Dubai만 `SMALL_COHERE_4` 대체 |
| Cohere Command A Vision | `LARGE_COHERE_V3` | 불가 | Dubai만 `SMALL_COHERE_4` |
| Cohere Command A Reasoning | `LARGE_COHERE_V2_2` | 불가 | Dubai만 `SMALL_COHERE_4`; 일부 리전 dedicated only |
| Cohere Embed 4 | `Embed Cohere` | 불가 | hosting 1 unit |
| Cohere Rerank 4 Pro | `COHERE_A100_80G_X1` 또는 `COHERE_H100_X1` | 불가 | 리전별 unit 다름 |
| Cohere Rerank 4 Fast | `COHERE_A100_80G_X1` 또는 `COHERE_H100_X1` | 불가 | 리전별 unit 다름 |
| Meta Llama 4 Scout | `Large Generic V2` | 불가 | Abu Dhabi만 `LARGE_GENERIC_V4` |
| Meta Llama 4 Maverick | `Large Generic 2` | 불가 | Abu Dhabi만 `LARGE_GENERIC_V5` |
| Meta Llama 3.3 70B (Standard) | `Large Generic` | 가능 | fine-tuning cluster는 `Large Generic` 2 units |
| Meta Llama 3.3 70B (Dynamic FP8) | `Large Generic` | 불가 | Dubai는 `LARGE_GENERIC_V1`, Abu Dhabi는 `LARGE_GENERIC_V4` |
| OpenAI gpt-oss-20b | `OAI_A10_X2` / `OAI_A100_40G_X1` / `OAI_A100_80G_X1` / `OAI_H100_X1` / `OAI_H200_X1` | 불가 | 리전별 공개 hardware 상이 |
| OpenAI gpt-oss-120b | `OAI_A100_40G_X4` / `OAI_A100_80G_X2` / `OAI_H100_X2` / `OAI_H200_X1` | 불가 | 리전별 공개 hardware 상이 |

### 8-2. DAC 관점에서 눈에 띄는 포인트

| 주제 | 해석 |
|---|---|
| 가장 투명한 하드웨어 공개 | `gpt-oss` 계열 |
| Oracle 전용 opaque unit 다수 | `Large Generic`, `Large Cohere`, `Embed Cohere`, `Rerank Cohere` |
| fine-tuning 가능한 현행 핵심 모델 | `Meta Llama 3.3 70B (Standard)` |
| deprecated지만 아직 fine-tuning 문맥에 남아 있는 모델 | `Cohere Command R (08-2024)` |

---

## 9. DAC 유닛별 배포 필요 GPU 메모리 표

중요:

- 아래 메모리는 `하드웨어가 공개된 unit`만 계산했다.
- `Large Generic`, `Large Cohere`, `Small Cohere`, `Embed Cohere`, `RERANK_COHERE`는 Oracle이 실제 GPU를 공개하지 않으므로 `미공개`로 적었다.

### 9-1. 하드웨어 공개형 unit

| DAC unit | GPU 환산 | 추정 총 GPU 메모리 | 주 사용 예 |
|---|---|---:|---|
| `A10_X1` | A10 x1 | 24 GB | import 소형 embedding/chat |
| `A10_X2` | A10 x2 | 48 GB | import embedding/Qwen embedding |
| `A10_X4` | A10 x4 | 96 GB | import 확장형 A10 |
| `A100_40G_X1` | A100 40GB x1 | 40 GB | import 또는 `gpt-oss-20b` 일부 리전 |
| `A100_40G_X2` | A100 40GB x2 | 80 GB | import |
| `A100_40G_X4` | A100 40GB x4 | 160 GB | `gpt-oss-120b` Dubai |
| `A100_40G_X8` | A100 40GB x8 | 320 GB | import |
| `A100_80G_X1` | A100 80GB x1 | 80 GB | import/chat/vision, `gpt-oss-20b` 일부 |
| `A100_80G_X2` | A100 80GB x2 | 160 GB | import 30B~35B, `gpt-oss-120b` 일부 |
| `A100_80G_X4` | A100 80GB x4 | 320 GB | import 70B class |
| `A100_80G_X8` | A100 80GB x8 | 640 GB | import 200B class 일부 |
| `H100_X1` | H100 x1 | 80 GB | import gpt-oss-20b, Phi vision |
| `H100_X2` | H100 x2 | 160 GB | import gpt-oss-120b, Gemma 4 31B, Qwen 3.6 |
| `H100_X4` | H100 x4 | 320 GB | import Llama 4 Scout |
| `H100_X8` | H100 x8 | 640 GB | import Llama 4 Maverick, Qwen 235B |
| `H200_X1` | H200 x1 | 141 GB | managed `gpt-oss` Riyadh |
| `H200_X2` | H200 x2 | 282 GB | import용 unit table에 존재 |
| `H200_X4` | H200 x4 | 564 GB | import용 unit table에 존재 |
| `H200_X8` | H200 x8 | 1128 GB | import용 unit table에 존재 |

### 9-2. Oracle 문서상 GPU 미공개 unit

| DAC unit | 공개 상태 | 비고 |
|---|---|---|
| `Large Generic` / `Large Generic V2` / `Large Generic 2` / `LARGE_GENERIC_V1` / `LARGE_GENERIC_V4` / `LARGE_GENERIC_V5` | GPU 종류 미공개 | Meta 계열 관리형 DAC에서 사용 |
| `LARGE_COHERE_V2_2` / `LARGE_COHERE_V3` / `SMALL_COHERE_4` | GPU 종류 미공개 | Cohere chat 계열 DAC에서 사용 |
| `Embed Cohere` | GPU 종류 미공개 | Cohere Embed 4 |
| `COHERE_A100_80G_X1` / `COHERE_H100_X1` | 메모리는 이름상 유추 가능하나 Oracle이 별도 GPU 메모리표를 주지 않음 | Rerank 4 전용 표기 |

---

## 10. import / custom deployment 권장 DAC

### 10-1. imported model 권장 DAC

| 시나리오 | 예시 모델 | Oracle 권장 DAC | 대체 해석 |
|---|---|---|---|
| OpenAI open-weight reasoning | `openai/gpt-oss-20b` | `H100_X1` | 해당 region에 H100이 없으면 상위 tier 또는 동일 급 대체 고려 |
| OpenAI open-weight reasoning(대형) | `openai/gpt-oss-120b` | `H100_X2` | A100 80G x2는 차선책 |
| Google Gemma 최신 대형 | `google/gemma-4-31B-it` | `H100_X2` | 문서상 새로 추가된 import 호환 모델 |
| Meta Llama 4 Scout import | `meta-llama/Llama-4-Scout-17B-16E-Instruct` | `H100_X4` | multimodal, 더 큰 GPU footprint |
| Meta Llama 4 Maverick import | `meta-llama/Llama-4-Maverick-17B-128E-Instruct-FP8` | `H100_X8` | 대형 MoE |
| Qwen 3.6 multimodal | `Qwen/Qwen3.6-35B-A3B` | `H100_X2` | 2026-05-11 신규 |
| Qwen 3.5 multimodal | `Qwen/Qwen3.5-9B` | `H100_X1` | 2026-05-11 신규 |
| DeepSeek reasoning 계열 | `deepseek-ai/DeepSeek-R1-Distill-Qwen-32B` | `A100_80G_X2` | 문서상 H100이 있으면 H100 선호라고 별도 안내 |
| Phi 소형/중형 | `microsoft/phi-4`, `Phi-3-*` | `A100_80G_X1` | 경제성 우선 |
| 임베딩 전용 | `Qwen3-Embedding-0.6B`, `intfloat/e5-mistral-7b-instruct` | `A10_X1` | 가장 저렴한 축 |
| 이미지 생성/편집 | `Qwen/Qwen-Image*` | `A100_80G_X1` | 관리형 기본 모델과 별개 |

### 10-2. custom model 권장 DAC

| 시나리오 | 기준 모델 | 권장 DAC | 메모 |
|---|---|---|---|
| 현행 관리형 custom model | `meta.llama-3.3-70b-instruct` | Fine-tuning: `Large Generic` 2 units / Hosting: `Large Generic` 1 unit | 표준 variant만 fine-tuning 가능 |
| 정부/소버린 custom model | `meta.llama-3.3-70b-instruct` | 문서상 fine-tuning 불가 | OC4, OC19 fine-tuning 불가 명시 |
| imported fine-tuned model | compatible base와 transformer version/parameter 범위 일치 필요 | family별 import 권장 DAC 사용 | imported models는 744 unit-hour 최소 hosting commitment 불필요 |

짧은 해석:

- `imported model`은 family 문서에 적힌 `recommended dedicated AI cluster unit shape`를 우선 따르는 것이 Oracle 문서 기준 정답이다.
- Oracle import 문서는 대체 규칙으로 `A100`과 `H100`이 둘 다 있으면 `H100`을 더 나은 성능 선택지로 본다.
- `H200`은 unit table에는 존재하지만, family별 권장 shape에서 1순위로 자주 등장하지는 않는다.

---

## 11. 파인튜닝 가능 여부

| 모델 / 계열 | 파인튜닝 가능 여부 | 근거 메모 |
|---|---|---|
| Meta Llama 3.3 70B (Standard) | 가능 | commercial(OC1)에서 가능, OC4/OC19는 불가 |
| Meta Llama 3.3 70B (Dynamic FP8) | 불가 | 모델 문서에 `Not available for fine-tuning` |
| Meta Llama 4 Scout / Maverick | 불가 | 모델 문서에 `Not available for fine-tuning` |
| OpenAI gpt-oss-20b / 120b | 불가 | 모델 문서에 `This model isn't available for fine-tuning` |
| Cohere Command A / Vision / Reasoning | 불가 | 각 모델 문서에 `Not available for fine-tuning` |
| Cohere Embed 4 / Rerank 4 | 불가 | 모델 문서에 `Not available for fine-tuning` |
| Google Gemini 2.5 Pro / Flash / Flash-Lite | OCI Generative AI 기준 불가 | 모델 문서가 on-demand only이며 tuning은 `No` |
| xAI Grok 4.3 / 4.20 / Multi-Agent | 불가 | Grok 계열은 on-demand only |
| Cohere Command R (08-2024) | 가능했으나 deprecated | `Selecting a Fine-Tuning Method`에 base model로 남아 있으나 retirement `2026-09-30` 주의 |

---

## 12. A100 / H100 / H200 선택 가이드

| 선택 기준 | A100 80G | H100 | H200 |
|---|---|---|---|
| Oracle 문서상 추천 빈도 | 높음 | 매우 높음 | 낮음 |
| import family 권장 shape | 다수의 Qwen / Meta / Phi / Gemma에서 사용 | gpt-oss, Gemma 4, Qwen 3.6, Llama 4에서 자주 사용 | family별 1순위 표시는 드묾 |
| 관리형 gpt-oss DAC 공개 | Chicago/Phoenix에서 강함 | 여러 상용 리전에 폭넓게 공개 | Riyadh 중심으로 공개 |
| 선택 해석 | 범용성과 비용 균형 | 성능 우선, Oracle 문서가 가장 자주 권장 | 특정 리전/특정 요구에서만 고려 |

권장 판단:

- `A100 80G`: import 모델을 넓게 수용하면서도 H100보다 보수적인 선택이 필요할 때.
- `H100`: Oracle 문서 기준에서 가장 안전한 고성능 기본값.
- `H200`: Oracle이 unit은 제공하지만, 이번 확인 범위의 family-level 권장 문서에서는 1순위 빈도가 낮다. `Riyadh`의 관리형 `gpt-oss`처럼 명시된 경우에 우선 고려.

---

## 13. 모델 강점 요약

| 모델/계열 | 강점 요약 |
|---|---|
| Gemini 2.5 Pro | 복잡한 reasoning, 과학/코드, 대형 멀티모달 입력 |
| Gemini 2.5 Flash | 속도와 지능의 균형, 범용 앱 기본값 |
| Gemini 2.5 Flash-Lite | 저비용 고처리량, 분류/요약/라우팅 |
| Grok 4.3 | 정확도 중심 reasoning, 긴 컨텍스트 |
| Grok 4.20 | reasoning / non-reasoning 분리, agentic tool-calling |
| Grok 4.20 Multi-Agent | 깊은 조사형 multi-agent orchestration |
| Cohere Command A | enterprise chat, tool use, RAG, multilingual |
| Cohere Command A Vision | 문서/차트/이미지 이해 |
| Cohere Command A Reasoning | agentic workflow, 고급 reasoning, grounded citation |
| Meta Llama 3.3 70B | self-hosted 성격이 강한 텍스트 생성 + fine-tuning |
| Meta Llama 4 Scout | 작은 footprint의 멀티모달 |
| Meta Llama 4 Maverick | 더 큰 context와 coding/reasoning 성향의 멀티모달 |
| OpenAI gpt-oss-20b | 작은 footprint reasoning, 로컬/전용 배포 친화 |
| OpenAI gpt-oss-120b | 더 강한 reasoning과 production-grade use case |
| Cohere Embed 4 | 멀티모달 임베딩, 가변 차원 |
| Cohere Rerank 4 Pro/Fast | 검색 후단 relevance 개선, Pro는 품질, Fast는 처리량 |

---

## 14. 빠른 추천

| 질문 | 추천 |
|---|---|
| 가장 쉬운 최신 reasoning on-demand | `Google Gemini 2.5 Pro` 또는 `xAI Grok 4.3` |
| 속도/비용 균형 on-demand | `Google Gemini 2.5 Flash` |
| 대량 요청용 저비용 on-demand | `Google Gemini 2.5 Flash-Lite` |
| 관리형 DAC에서 하드웨어까지 명확히 보고 싶음 | `OpenAI gpt-oss-20b/120b` |
| 관리형 fine-tuning이 꼭 필요함 | `Meta Llama 3.3 70B (Standard)` |
| 멀티모달 open model을 import하고 싶음 | `Gemma 4`, `Qwen 3.6`, `Llama 4` 계열 + `H100` 우선 |
| 임베딩만 필요함 | 관리형은 `Cohere Embed 4`, import는 소형이면 `A10_X1` 계열 |
| 리랭크만 필요함 | `Cohere Rerank 4 Fast`, 품질 우선이면 `Pro` |
| 중동 리전에서 H200을 명시적으로 쓰고 싶음 | 관리형 `gpt-oss` 기준 `Riyadh` 우선 검토 |

---

## 15. 사용한 주요 공식 문서 범주

- 리전/서비스 지원: `Generative AI Regions`, `Generative AI Dedicated Cluster Shapes by Region`, `About AI Quick Actions`
- 관리형 모델/은퇴: `Offered Pretrained Foundational Models`, `Model Retirement Dates (On-Demand)`, `Model Retirement Dates (Dedicated)`
- IaaS/AQUA GPU: `Compute Shapes`, `Supported Compute Shapes`, `Using GPUs`, `GPUs`
- import/custom deployment: `Managing Imported Models`, `Compatible Models for Import`, family별 compatible model 문서
- 최신 변경점: `Generative AI` release notes index와 개별 release note

### 참고 문서 링크

- Generative AI Regions  
  `https://docs.oracle.com/en-us/iaas/Content/generative-ai/regions.htm`
- Generative AI Dedicated Cluster Shapes by Region  
  `https://docs.oracle.com/en-us/iaas/Content/generative-ai/model-dac-endpoint-regions.htm`
- About AI Quick Actions  
  `https://docs.oracle.com/en-us/iaas/Content/data-science/using/ai-quick-actions-about.htm`
- Compute Shapes  
  `https://docs.oracle.com/en-us/iaas/Content/Compute/References/computeshapes.htm`
- Supported Compute Shapes  
  `https://docs.oracle.com/en-us/iaas/Content/data-science/using/supported-shapes.htm`
- Using GPUs / GPUs troubleshooting  
  `https://docs.oracle.com/en-us/iaas/data-science/using/gpu-using.htm`  
  `https://docs.oracle.com/en-us/iaas/data-science/using/tshoot-gpu.htm`
- Offered Pretrained Foundational Models in Generative AI  
  `https://docs.oracle.com/en-us/iaas/Content/generative-ai/pretrained-models.htm`
- Model Retirement Dates (On-Demand Mode)  
  `https://docs.oracle.com/en-us/iaas/Content/generative-ai/deprecating-on-demand.htm`
- Model Retirement Dates (Dedicated Mode)  
  `https://docs.oracle.com/en-us/iaas/Content/generative-ai/deprecating-dedicated.htm`
- Managing Imported Models  
  `https://docs.oracle.com/en-us/iaas/Content/generative-ai/manage-imported-models.htm`
- Compatible Models for Import  
  `https://docs.oracle.com/en-us/iaas/Content/generative-ai/imported-models.htm`
- Generative AI Release Notes Index  
  `https://docs.oracle.com/en-us/iaas/releasenotes/services/generative-ai/index.htm`
