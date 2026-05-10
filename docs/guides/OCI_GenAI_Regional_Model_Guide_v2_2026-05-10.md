# OCI Generative AI / DAC / AQUA / IaaS GPU 리전·모델 가이드 v2

최종 업데이트: 2026-05-10 (GMT)  
정리 기준: Oracle 공식 문서 우선 + OCI CLI 실조회 시도 결과

이 문서는 `LATEST.md`로 복사될 수 있음을 고려해, 앞부분 1페이지 안에 핵심 변화와 현재 판정 기준을 먼저 배치했다.

---

## 이번 업데이트 변화 요약

- `2026-05-05` 기준 Oracle release notes에 `UAE Central (Abu Dhabi)` 리전의 OCI Generative AI 가용성이 추가되었다.
- `2026-05-01` 기준 Oracle release notes와 개별 모델 페이지에 `xAI Grok 4.3`가 추가되었다.
- `Models by Region` 기준으로 `UAE Central (Abu Dhabi)`에는 이미 일부 관리형 기본 모델의 dedicated 표기가 보이지만, `Dedicated Cluster Shapes by Region` 쪽에는 아직 Abu Dhabi 전용 A10/A100/H100/H200 하드웨어 표가 명시적으로 보이지 않는다. 따라서 이 문서의 `DAC A10/A100/H100/H200 가시성` 표에서는 Abu Dhabi를 `문서상 미확인`으로 유지했다.
- retirement/deprecation 관련 문서는 이번 기준에서도 계속 중요하다.
  - 신규 설계에서 우선 제외할 대상: `Cohere Command R+`, `Cohere Command R 16K`, `Cohere Command (52B)`, `Cohere Command Light`, `Meta Llama 3.1 70B`, `Meta Llama 3 70B`, `Meta Llama 2 70B`
  - 대체 방향이 명시된 주요 축: `Meta Llama 4 Maverick/Scout`, `Cohere Command A`, `Cohere Embed 4`, `xAI Grok 4.3`
- `xAI Grok 3`, `xAI Grok 3 Mini`, `xAI Grok 3 Fast`, `xAI Grok 3 Mini Fast`는 Oracle의 on-demand retirement 표에서 `xAI Grok 4.3` 대체 대상으로 정리되어 있다.
- CLI 실조회는 이번에도 성공하지 못했다.
  - `region-subscription list`: 실패
  - `compute shape list`: 실패
  - `os ns get`: 실패
  - 공통 관찰: 인증 오류 응답까지 가지 못하고 OCI endpoint GET 재시도만 반복되다가 로컬 `timeout`으로 종료되었다.
  - 따라서 `IaaS/AQUA GPU 재고표`는 실테넌시 live inventory가 아니라 Oracle 문서 기준 해석표로 대체했다.

---

## 0. 먼저 보는 전제

### 0-1. 용어

- `Generative AI`: OCI Generative AI 관리형 서비스
- `DAC`: Dedicated AI Cluster
- `AQUA`: OCI Data Science AI Quick Actions
- `IaaS GPU`: OCI Compute 또는 OCI Data Science에서 직접 쓰는 GPU shape
- `관리형 기본 모델`: Oracle이 제공하는 hosted pretrained foundational model
- `imported model`: 사용자가 Hugging Face 또는 Object Storage에서 가져와 OCI Generative AI에서 OME 기반으로 배포하는 모델
- `custom model`: OCI Generative AI fine-tuning workflow로 생성한 모델

### 0-2. 문서 해석 원칙

- Oracle 공식 문서에 있는 사실만 확정적으로 썼다.
- Oracle 공식 문서에 없는 리전별 실시간 재고는 `없음`, `문서상 고정표 없음`, `문서상 미확인`으로 적었다.
- `관리형 기본 모델용 DAC unit`, `imported model용 DAC unit`, `custom model(fine-tuned)용 cluster`를 구분했다.
- `LARGE_COHERE_*`, `LARGE_GENERIC_*`, `SMALL_GENERIC_*`, `EMBED_COHERE`, `RERANK_COHERE` 같은 일부 DAC unit은 Oracle이 underlying hardware를 공개하지 않으므로 GPU 종류와 GPU 메모리를 단정하지 않았다.
- GPU 메모리 계산은 `A10/A100/H100/H200`처럼 이름 또는 공식 shape 표로 GPU 메모리가 공개된 unit만 계산했다.
- Oracle retirement 문서에는 `Retired Models` 표와 날짜 필드가 함께 제공된다. 표 제목과 날짜가 직관적으로 어긋나 보이는 항목도 있어, 이 문서는 Oracle 표 구분과 날짜를 그대로 병기하고 임의 재해석은 하지 않았다.
- `관리형 기본 모델을 DAC로 돌릴 수 있다`와 `imported model에 같은 GPU를 쓰면 동일 성능이 난다`는 같은 뜻이 아니다.

---

## 1. CLI 조회 상태

### 1-1. 실행 상태 표

| 조회 항목 | 실행 명령 | 상태 | 관찰 |
|---|---|---|---|
| 구독 리전 조회 | `oci iam region-subscription list --all --tenancy-id <tenancy_ocid> --output table` | 실패 | `identity.ap-seoul-1.oci.oraclecloud.com`로 GET 재시도 반복 후 `timeout 15s` 종료 |
| GPU shape 조회 | `oci --region us-ashburn-1 compute shape list --all -c <tenancy_ocid> ...` | 실패 | `iaas.us-ashburn-1.oraclecloud.com`로 GET 재시도 반복 후 `timeout 15s` 종료 |
| 보조 연결 확인 | `oci --region ap-seoul-1 os ns get --output table` | 실패 | `objectstorage.ap-seoul-1.oraclecloud.com`로 GET 재시도 반복 후 `timeout 15s` 종료 |

### 1-2. 실패 이유와 문서 반영 방식

| 항목 | 관찰 내용 | 문서 반영 방식 |
|---|---|---|
| OCI CLI 설치 | `oci --version` 확인됨 | CLI 자체는 설치됨 |
| OCI 설정 | `~/.oci/config`에 `user`, `tenancy`, `region` 값 존재 | 명령 형식 자체는 유효한 환경으로 판단 |
| `region-subscription list` | Identity endpoint 요청 반복, 응답 본문 미수신 | Oracle 리전 문서 기준 표로 대체 |
| `compute shape list` | IaaS endpoint 요청 반복, 응답 본문 미수신 | Compute/Data Science shape 문서 기준 해석표로 대체 |
| `os ns get` | Object Storage endpoint 요청 반복, 응답 본문 미수신 | 인증 성공/실패 판정보다 앞단의 응답 지연 또는 reachability 문제로 취급 |

실무 메모:

- 이번 실행에서는 `NotAuthorizedOrNotFound` 같은 권한 오류를 확인하지 못했다.
- 반대로 `timeout 15s` 안에서 endpoint 요청이 반복되다가 종료되는 패턴은 확인했다.
- 따라서 아래 `IaaS/AQUA GPU 재고표`는 live inventory가 아니라 `문서 기준 해석표`다.

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
| ME | UAE Central (Abu Dhabi) | 지원 | 지원(모델별) | 지원 | `2026-05-05` 추가 |
| ME | UAE East (Dubai) | 지원 | 지원(모델별) | 지원 | 상용 리전 |
| EU | UK South (London) | 지원 | 지원(모델별) | 지원 | 상용 리전 |
| NA | US East (Ashburn) | 지원 | 지원(모델별) | 지원 | 상용 리전 |
| NA | US Midwest (Chicago) | 지원 | 지원(모델별) | 지원 | 상용 리전 |
| NA | US West (Phoenix) | 지원 | 지원(모델별) | 지원 | 상용 리전 |

### 2-2. 정부 / 소버린 리전

| 권역 | 리전 | Generative AI | DAC | AQUA | 비고 |
|---|---|---|---|---|---|
| GOV | UK Gov South (London) | 지원 | 지원(모델별) | 지원 | 정부 리전 |
| SOV | EU Sovereign Central (Frankfurt) | 지원 | 지원(모델별) | Oracle 문서상 명시 확인 못함 | sovereign AQUA 지원 여부는 이번 기준 미확인 |

정리:

- Generative AI 서비스 자체는 `Models by Region`과 release notes 기준으로 위 리전들이 확인된다.
- DAC는 `모델별`이다. 서비스가 있는 리전과 특정 모델의 dedicated hosting 가능 리전은 다를 수 있다.
- AQUA는 Oracle Data Science 문서상 `all commercial and government regions` 지원이다.
- AQUA의 sovereign 리전 지원은 이번 확인 범위에서 Oracle 공식 문서 근거를 찾지 못했다.

---

## 3. 리전별 DAC A10 / A100 / H100 / H200 가시성

판정 기준:

- 이 표는 Oracle의 `OpenAI gpt-oss-20b / 120b` 개별 모델 페이지와 `Dedicated Cluster Shapes by Region` 공개 unit만 사용했다.
- 즉, `Oracle이 GPU 종류를 고객에게 공개한 DAC`만 반영했다.
- `LARGE_COHERE_*`, `LARGE_GENERIC_*`는 Oracle이 GPU 종류를 공개하지 않으므로 이 표의 A/H 계열 판정에 쓰지 않았다.

### 3-1. 상용 리전

| 리전 | A10 | A100 40G | A100 80G | H100 | H200 | 메모 |
|---|---|---|---|---|---|---|
| Brazil East (Sao Paulo) | - | - | - | 예 | - | `gpt-oss`는 H100 계열 |
| Germany Central (Frankfurt) | 예 | - | - | 예 | - | `20b`는 A10 또는 H100 |
| India South (Hyderabad) | - | - | - | 예 | - | H100 계열 |
| Japan Central (Osaka) | - | - | - | 예 | - | H100 계열 |
| Saudi Arabia Central (Riyadh) | - | - | - | - | 예 | `20b/120b` 모두 H200 계열 확인 |
| UAE Central (Abu Dhabi) | 문서상 미확인 | 문서상 미확인 | 문서상 미확인 | 문서상 미확인 | 문서상 미확인 | service/mode는 보이나 GPU family 표는 미확인 |
| UAE East (Dubai) | 예 | 예 | - | - | - | A10 / A100 40G 계열 |
| UK South (London) | - | - | - | 예 | - | H100 계열 |
| US East (Ashburn) | 예 | - | - | 예 | - | `20b`는 A10 또는 H100 |
| US Midwest (Chicago) | 예 | - | 예 | 예 | - | A10 / A100 80G / H100 공존 |
| US West (Phoenix) | - | - | 예 | - | - | A100 80G 계열 |

### 3-2. 정부 / 소버린 리전

| 리전 | A10 | A100 40G | A100 80G | H100 | H200 | 메모 |
|---|---|---|---|---|---|---|
| UK Gov South (London) | - | - | - | 예 | - | `gpt-oss`는 H100 계열만 문서 확인 |
| EU Sovereign Central (Frankfurt) | 예 | - | - | 예 | - | `20b`는 A10 또는 H100, `120b`는 H100 |

요약:

- 관리형 `gpt-oss` 기준으로 가장 넓게 보이는 계열은 `H100`이다.
- `H200`은 이번 기준에서 `Saudi Arabia Central (Riyadh)`의 `gpt-oss` 전용 DAC에서만 공식 확인된다.
- `A100 80G`는 `US Midwest (Chicago)`, `US West (Phoenix)`에서 공식 확인된다.
- `A100 40G`는 `UAE East (Dubai)`에서 공식 확인된다.

---

## 4. IaaS GPU shape 조회 명령과 결과 해석법

### 4-1. 리전 구독 조회 명령

```bash
oci iam region-subscription list --all \
  --tenancy-id <tenancy_ocid> \
  --query 'data[]."region-name"' \
  --raw-output
```

### 4-2. GPU shape 조회 명령

```bash
oci --region <region> compute shape list --all \
  -c <compartment_or_tenancy_ocid> \
  --query 'data[?contains(shape, `GPU`)].{shape:shape,gpus:gpus,"gpu-desc":"gpu-description",memory_gb:"memory-in-gbs",ocpus:ocpus}' \
  --output table
```

### 4-3. 이번 실행 결과 해석

- 명령 형식 자체는 유효하다.
- 이번 환경에서는 `region-subscription list`, `compute shape list`, `os ns get` 모두 OCI endpoint 응답을 받기 전에 로컬 `timeout`으로 종료되었다.
- 따라서 이 문서의 IaaS/AQUA 관련 표는 아래 `shape-to-GPU 매핑`과 Oracle `Compute Shapes` / `Data Science Supported Compute Shapes` 문서로 읽어야 한다.

### 4-4. 결과 해석법

| CLI에 보이는 shape | 해석 |
|---|---|
| `VM.GPU3.*`, `BM.GPU3.8` | V100 계열 |
| `VM.GPU.A10.*`, `BM.GPU.A10.4` 또는 `BM.GPUA10.4` | A10 계열 |
| `BM.GPU4.8` | A100 40GB 계열 |
| `BM.GPU.A100-v2.8` | A100 80GB 계열 |
| `BM.GPU.H100.8` | H100 계열 |
| `BM.GPU.H200.8` | H200 계열 |
| `BM.GPU.L40S.4` 또는 `BM.GPU.L40S-NC.4` | L40S 계열 |

중요:

- Oracle 공식 문서 안에서도 shape 표기 차이가 있다.
- Compute 문서는 `BM.GPU.A10.4`, `BM.GPU.L40S.4`로 보이고, Data Science 문서는 `BM.GPUA10.4`, `BM.GPU.L40S-NC.4`로 보인다.
- 따라서 실제 CLI 결과는 `문자열 자체`를 먼저 믿고, 해석은 GPU family 기준으로 하는 편이 안전하다.

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
| `BM.GPU.A10.4` / `BM.GPUA10.4` | A10 | 4 | 96 GB | 64 | 1024 GB |
| `BM.GPU4.8` | A100 | 8 | 320 GB | 64 | 2048 GB |
| `BM.GPU.A100-v2.8` | A100 | 8 | 640 GB | 64 또는 128 | 2048 GB |
| `BM.GPU.H100.8` | H100 | 8 | 640 GB | 112 | 2048 GB |
| `BM.GPU.H200.8` | H200 | 8 | 1128 GB | 112 | 3072 GB |
| `BM.GPU.L40S.4` / `BM.GPU.L40S-NC.4` | L40S | 4 | 192 GB | 112 | 1024 GB |

주의:

- `BM.GPU.A100-v2.8`의 OCPU 표기는 Compute 문서와 Data Science 문서가 다르게 보인다.
- 이 문서는 `GPU/GPU 메모리` 축을 우선 사용하고, OCPU는 문서 차이가 있음을 인정한다.
- 사용자 요청 범위를 맞추기 위해 `A10/A100/H100/H200` 중심으로 읽고, `MI300X`, `MI355X`, `B200`, `GB200`, `GB300`은 본문 핵심 표에서 제외했다.

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

중요:

- Oracle 공식 문서는 `리전별 실시간 GPU 재고표`를 제공하지 않는다.
- CLI 실조회가 실패했으므로, 아래 표는 `문서상 지원 shape 계열`을 정리한 해석표다.
- 실제 생성 가능 여부는 `service limit`, `host capacity`, `reservation`, `region-specific availability`를 별도 확인해야 한다.

### 6-1. 문서 기준 IaaS / AQUA 지원 GPU 계열

| 계열 | IaaS Compute shape 예 | Data Science / AQUA shape 예 | Oracle의 리전별 고정 재고표 |
|---|---|---|---|
| V100 | `VM.GPU3.*`, `BM.GPU3.8` | 지원 | 없음 |
| A10 | `VM.GPU.A10.*`, `BM.GPU.A10.4` / `BM.GPUA10.4` | 지원 | 없음 |
| A100 40G | `BM.GPU4.8` | 지원 | 없음 |
| A100 80G | `BM.GPU.A100-v2.8` | 지원 | 없음 |
| H100 | `BM.GPU.H100.8` | 지원 | 없음 |
| H200 | `BM.GPU.H200.8` | 지원 | 없음 |
| L40S | `BM.GPU.L40S.4` / `BM.GPU.L40S-NC.4` | 지원 | 없음 |

### 6-2. AQUA / Data Science 해석 규칙

| 항목 | Oracle 문서 상태 | 이 문서의 처리 방식 |
|---|---|---|
| AQUA 리전 지원 | 상용 + 정부 리전 지원 명시 | sovereign은 미확인으로 유지 |
| AQUA per-region GPU 고정표 | 없음 | Data Science 지원 shape + service limit 주의로 해석 |
| Data Science GPU 생성 가능 여부 | 문서만으로 확정 불가 | limit + shape capacity + reservation 필요 여부를 함께 확인 |
| GPU 이전 방식 | Compute 예약 GPU를 Data Science로 이전 가능 문구 존재 | live availability가 아니라 운영 절차 참고용으로만 사용 |

### 6-3. 실무 메모

| 항목 | 해석 |
|---|---|
| A10 | Data Science 문서상 GPU reservation을 이전해서 쓰는 절차가 보인다. |
| A100 | Oracle 문서상 imported model 권장 shape에서 가장 자주 보이는 범용 출발점이다. |
| H100 | 관리형 `gpt-oss`와 imported 대형 모델에서 가장 넓게 보이는 상위 계열이다. |
| H200 | 지원 shape는 문서에 보이지만 per-region 고정표는 없다. |
| AQUA | `all commercial and government regions` 지원이지만 리전별 GPU 재고를 따로 공개하지 않는다. |

---

## 7. 온디맨드 핵심 모델 표

중요:

- 이 표는 `Oracle 개별 모델 페이지에서 핵심 특징이 확인되는 모델` 위주로 정리했다.
- 표 폭을 줄이기 위해 범용/멀티모달/임베딩·재정렬로 분리했다.

### 7-1. 범용 / 추론

| 모델 | 유형 | 컨텍스트 | 온디맨드 | 파인튜닝 | 핵심 강점 |
|---|---|---|---|---|---|
| `cohere.command-a-03-2025` | 범용 chat/agent | 256k | 예 | 불가 | 기업형 RAG, tool use, multilingual |
| `meta.llama-3.3-70b-instruct` | 범용 instruct | 128k | 예 | 가능 | 범용 오픈모델 + OCI fine-tuning 가능 |
| `openai.gpt-oss-20b` | text reasoning | 128k | 예 | 불가 | 빠른 reasoning, 코딩, STEM |
| `openai.gpt-oss-120b` | text reasoning | 128k | 예 | 불가 | production급 reasoning |
| `xai.grok-4.3` | multimodal reasoning | 1M | 예 | 불가 | 고난도 reasoning, structured output, function calling |

### 7-2. 멀티모달 / 장문

| 모델 | 유형 | 컨텍스트 | 온디맨드 | 파인튜닝 | 핵심 강점 |
|---|---|---|---|---|---|
| `cohere.command-a-vision` | 멀티모달 | 128k | 예 | 불가 | 문서·차트·이미지 해석 |
| `cohere.command-a-reasoning` | reasoning | 256k | 예 | 불가 | 대형 문서 분석, agentic workflow |
| `meta.llama-4-scout-17b-16e-instruct` | 멀티모달 | 192k | Chicago | 불가 | 작은 GPU footprint, 긴 문맥 |
| `meta.llama-4-maverick-17b-128e-instruct-fp8` | 멀티모달 | 512k | Chicago | 불가 | 코딩/추론, 초장문 문맥 |
| `google.gemini-2.5-pro` | 멀티모달 reasoning | 1M | 예 | 불가 | 가장 어려운 문제 해결, 대형 입력 |
| `google.gemini-2.5-flash` | 멀티모달 fast reasoning | 1M | 예 | 불가 | 속도/지능 균형 |
| `google.gemini-2.5-flash-lite` | 멀티모달 경량 | 1M | 예 | 불가 | 저비용, 대량 처리 |

### 7-3. 임베딩 / 재정렬 / 코딩 특화

| 모델 | 유형 | 온디맨드 | 파인튜닝 | 핵심 강점 |
|---|---|---|---|---|
| `cohere.embed-v4.0` | 임베딩 | 예 | 불가 | 텍스트 + 이미지 임베딩 |
| `cohere.rerank.v3-5` | 재정렬 | 아니오 | 불가 | 검색 후 재정렬 품질 향상 |
| `xAI Grok Code Fast 1` | 코딩 / external calls | 예 | 불가 | agentic coding, tool-use 중심 |

메모:

- Gemini 계열과 xAI 계열은 Oracle 문서상 on-demand 중심이다.
- Gemini는 on-demand only다.
- xAI Grok 계열도 Oracle 모델 페이지 기준으로 on-demand only다.
- `cohere.rerank.v3-5`는 dedicated only라서 `온디맨드 핵심 모델 표`에서는 재정렬 기준 참고 항목으로만 넣었다.

---

## 8. DAC 중심 모델 표

### 8-1. 현재 설계에서 자주 보는 관리형 DAC 모델

| 모델 ID | 호스팅 DAC unit | 파인튜닝 | 메모 |
|---|---|---|---|
| `cohere.command-a-03-2025` | `LARGE_COHERE_V3 x1` | 불가 | Dubai는 `SMALL_COHERE_4 x1` |
| `cohere.command-a-vision` | `LARGE_COHERE_V3 x1` | 불가 | Dubai는 `SMALL_COHERE_4 x1` |
| `cohere.command-a-reasoning` | `LARGE_COHERE_V2_2 x1` | 불가 | Dubai는 `SMALL_COHERE_4 x1` |
| `cohere.embed-v4.0` | `EMBED_COHERE x1` | 불가 | 리전별 온디맨드/전용 다름 |
| `cohere.rerank.v3-5` | `RERANK_COHERE x1` | 불가 | dedicated only |
| `meta.llama-3.3-70b-instruct` | `Large Generic x1` hosting, `x2` fine-tuning | 가능 | OC1 상용 리전에서 fine-tuning 가능 |
| `meta.llama-3.3-70b-instruct-fp8-dynamic` | `Large Generic x1` | 불가 | Dubai는 `LARGE_GENERIC_V1`, Abu Dhabi는 `LARGE_GENERIC_V4` |
| `meta.llama-4-scout-17b-16e-instruct` | `Large Generic V2 x1` | 불가 | Abu Dhabi는 `LARGE_GENERIC_V4 x1` |
| `meta.llama-4-maverick-17b-128e-instruct-fp8` | `Large Generic 2 x1` | 불가 | Abu Dhabi는 `LARGE_GENERIC_V5 x1` |
| `openai.gpt-oss-20b` | `OAI_A10_X2 / OAI_A100_40G_X1 / OAI_A100_80G_X1 / OAI_H100_X1 / OAI_H200_X1` | 불가 | 공개된 GPU 계열이 가장 명확 |
| `openai.gpt-oss-120b` | `OAI_A100_40G_X4 / OAI_A100_80G_X2 / OAI_H100_X2 / OAI_H200_X1` | 불가 | 대형 reasoning |

### 8-2. DAC 중심에서 특히 눈여겨볼 모델

| 모델 | 왜 DAC 중심인가 | 문서상 주의점 |
|---|---|---|
| `cohere.command-a-reasoning` | 긴 문맥 + reasoning + dedicated 구성이 명확 | 하드웨어 GPU 종류는 비공개 |
| `meta.llama-4-scout` | 작은 GPU footprint 강조 | Chicago만 on-demand, 나머지는 dedicated 비중 큼 |
| `meta.llama-4-maverick` | 512k 컨텍스트, 고급 coding/reasoning | Abu Dhabi 전용 generic variant가 따로 보임 |
| `openai.gpt-oss-20b` | A10/A100/H100/H200 공개형 DAC | 리전별 GPU 편차 큼 |
| `openai.gpt-oss-120b` | 공개형 DAC + 고급 reasoning | 160 GB 또는 141 GB 단일 H200 축이 핵심 |

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
| `LARGE_GENERIC_V1` | 미공개 | 미공개 | same |
| `LARGE_GENERIC_V4` | 미공개 | 미공개 | same |
| `LARGE_GENERIC_V5` | 미공개 | 미공개 | same |
| `LARGE_GENERIC_V2` | 미공개 | 미공개 | same |

---

## 10. import / custom deployment 권장 DAC

중요:

- 이 절은 `관리형 기본 모델`이 아니라 `imported model`과 `custom model hosting` 관점이다.
- Oracle은 `모든 imported model에 대한 단일 정답표`를 주지 않는다.
- 대신 `호환/검증된 모델 family별 권장 Dedicated AI Cluster Unit Shape`를 제공한다.

### 10-1. Oracle validated imported model 기준 권장 DAC

| family / 예시 모델 | Oracle 권장 DAC | 해석 |
|---|---|---|
| `openai/gpt-oss-20b` | `H100_X1` | imported `gpt-oss`의 공식 시작점 |
| `openai/gpt-oss-120b` | `H100_X2` | imported `gpt-oss` 대형 reasoning |
| `deepseek-ai/DeepSeek-R1-Distill-Qwen-32B` | `A100_80G_X2` | 32B reasoning 계열 |
| `meta-llama/Llama-4-Scout-17B-16E-Instruct` | `H100_X4` | 멀티모달 + 장문 |
| `meta-llama/Llama-4-Maverick-17B-128E-Instruct-FP8` | `H100_X8` | 더 큰 MoE / 더 긴 문맥 |
| `meta-llama/Llama-3.3-70B-Instruct` | `A100_80G_X4` | 범용 오픈모델 70B |
| `Qwen/QwQ-32B` | `A100_80G_X2` | reasoning 계열 |
| `Qwen/Qwen3-Embedding-0.6B` | `A10_X1` | 경량 embedding |
| `Qwen/Qwen3-Embedding-4B` | `A10_X2` | 중간 embedding |
| `Qwen/Qwen3-Embedding-8B` | `A100_80G_X1` | 더 큰 embedding |
| `Qwen/Qwen3-235B-A22B-Instruct-2507` | `H100_X8` | 초대형 MoE |
| `Qwen/Qwen3-VL-30B-A3B-Instruct` | `H100_X2` | vision-language |
| `Qwen/Qwen-Image` | `A100_80G_X1` | text-to-image 시작점 |

### 10-2. exact model 문서가 없을 때의 보수적 시작점

| 필요 VRAM 기준 | 권장 시작 DAC | 해석 |
|---|---|---|
| 24 GB 전후 | `A10_X1` | 가장 작은 시작점 |
| 48 GB 전후 | `A10_X2` | 경량 배포 / 테스트 용이 |
| 80 GB 전후 | `A100_80G_X1` 또는 `H100_X1` | 중간급 여유 메모리 |
| 141 GB 전후 | `H200_X1` | 단일 unit 최대 메모리 여유 |
| 160 GB 전후 | `A100_40G_X4`, `A100_80G_X2`, `H100_X2` | 대형 단일 배포의 보편 구간 |
| 320 GB 전후 | `A100_80G_X4` 또는 `H100_X4` | 큰 모델 / 더 긴 컨텍스트 / 여유 버퍼 |
| 564 GB 이상 | `H200_X4` 이상 | 메모리 병목 우선 해소용 |

실무 메모:

- Oracle imported family 페이지에는 `If the compatible unit shape isn't available in the region, select a higher-tier option` 안내가 반복된다.
- 따라서 추천 shape가 그 리전에 없으면 같은 family의 상위 GPU로 올리는 해석은 Oracle 문서와 맞다.
- imported model에서 메모리 병목이 먼저 걱정되면 `H200`이 가장 단순하다.
- 처리량과 생태계 균형을 보려면 `H100`이 무난하다.
- 비용과 범용성의 균형을 먼저 보면 `A100 80G`가 시작점으로 자주 나온다.

---

## 11. 파인튜닝 가능 여부

### 11-1. OCI Generative AI 관리형 기본 모델 기준

| 모델/계열 | 파인튜닝 가능 여부 | 메모 |
|---|---|---|
| `meta.llama-3.3-70b-instruct` | 가능 | LoRA, OC1 상용 리전 중심 |
| `meta.llama-3.3-70b-instruct-fp8-dynamic` | 불가 | 효율형 variant |
| `cohere.command-r-08-2024` | 문서상 가능 표기 존재 | `choose-method`에 있음. retirement 표도 함께 확인 필요 |
| `cohere.command-r-16k` | retired 항목 포함 | `choose-method`에는 남아 있으나 retired 표기 포함 |
| `meta.llama-3.1-70b-instruct` | retired 항목 포함 | `choose-method`에는 남아 있으나 dedicated retirement 표도 확인 필요 |
| `cohere.command-a-03-2025` | 불가 | 모델 문서상 fine-tuning 불가 |
| `cohere.command-a-vision` | 불가 | same |
| `cohere.command-a-reasoning` | 불가 | same |
| `cohere.embed-v4.0` | 불가 | same |
| `cohere.rerank.v3-5` | 불가 | dedicated only |
| `meta.llama-4-scout` | 불가 | hosted model only |
| `meta.llama-4-maverick` | 불가 | hosted model only |
| `openai.gpt-oss-20b` | 불가 | hosted model only |
| `openai.gpt-oss-120b` | 불가 | hosted model only |
| `google.gemini-2.5-*` | 불가 | on-demand only |
| `xAI Grok 계열` | 불가 | on-demand only |

### 11-2. imported model과 혼동하면 안 되는 점

| 항목 | 가능 여부 | 메모 |
|---|---|---|
| imported model 배포 | 가능 | Hugging Face 또는 Object Storage에서 import |
| imported fine-tuned model 배포 | 가능 | compatible base와 transformer version, 파라미터 범위 조건 존재 |
| OCI가 imported model을 대신 fine-tune | 문서상 일반화 불가 | imported hosting과 custom model fine-tuning은 별도 워크플로 |

### 11-3. 신규 설계 관점의 보수적 판단

| 구분 | 권장 판단 |
|---|---|
| 새 custom model 시작 | `meta.llama-3.3-70b-instruct` 우선 |
| Cohere 계열 fine-tuning | `cohere.command-r-08-2024` 문서 표기는 남아 있지만 retirement 표를 함께 확인 |
| retired 표에 이미 올라간 베이스 | 신규 설계에서는 제외 |

---

## 12. A100 / H100 / H200 선택 가이드

| 선택 기준 | A100 80G | H100 | H200 |
|---|---|---|---|
| GPU 메모리 | 80 GB/GPU | 80 GB/GPU | 141 GB/GPU |
| 관리형 `gpt-oss` 가시성 | Chicago, Phoenix 중심 | 가장 넓음 | Riyadh 확인 |
| imported model 시작점 | 가장 흔한 범용 기준 | 성능/처리량 우선 | 메모리 병목 우선 |
| 대형 Qwen / Llama 4 계열 | 중간급까지 자주 등장 | 대형/멀티모달/MoE 권장 | 메모리 우선 대체지 |
| 상위 대체 규칙 | H100로 상향 가능 | H200로 상향 가능 | 메모리 최우선 |
| IaaS/AQUA 주의 | 실재고 표 없음 | 실재고 표 없음 | 실재고 표 없음 |

짧게 정리하면:

- `A100 80G`: 비용과 범용성의 균형이 필요한 imported/custom 시작점
- `H100`: 관리형 DAC 선택지가 넓고 imported 대형 모델 권장 shape로 가장 자주 보임
- `H200`: 한 unit에서 더 큰 메모리 여유가 필요할 때 우선 검토

---

## 13. 모델 강점 요약

| 모델 | 강점 한 줄 요약 |
|---|---|
| `cohere.command-a-03-2025` | 기업형 RAG / tool use / multilingual 범용 챗 |
| `cohere.command-a-vision` | 문서, 차트, 이미지가 섞인 멀티모달 업무 |
| `cohere.command-a-reasoning` | 긴 문서와 복합 reasoning 전용 워크로드 |
| `cohere.embed-v4.0` | 텍스트 + 이미지 임베딩을 하나로 정리 |
| `cohere.rerank.v3-5` | 검색 결과 재정렬 품질 향상 |
| `meta.llama-3.3-70b-instruct` | 범용 오픈모델 + fine-tuning 확장성 |
| `meta.llama-4-scout` | 작은 GPU footprint와 긴 문맥의 균형 |
| `meta.llama-4-maverick` | 더 긴 문맥과 강한 코딩/추론 |
| `openai.gpt-oss-20b` | 빠른 reasoning / coding 반복 |
| `openai.gpt-oss-120b` | 더 높은 reasoning 품질 |
| `google.gemini-2.5-pro` | 가장 어려운 멀티모달 문제 해결 |
| `google.gemini-2.5-flash` | 속도와 지능의 균형 |
| `google.gemini-2.5-flash-lite` | 대량 처리, 저비용 |
| `xai.grok-4.3` | 고난도 reasoning + 1M 컨텍스트 + multimodal |
| `xAI Grok Code Fast 1` | agentic coding, tool-use 중심 |

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
- 재정렬 품질 개선: `cohere.rerank.v3-5`
- 코딩 에이전트: `xAI Grok Code Fast 1` 또는 `openai.gpt-oss-20b`
- imported model을 메모리 우선으로 시작: `H200_X1`
- imported model을 범용적으로 시작: `H100_X1` 또는 `A100_80G_X1`

---

## 15. retired / deprecated 메모

### 15-1. Oracle retirement 표 기준으로 신규 설계에서 우선 제외할 모델

| 모델 | 문서 메모 |
|---|---|
| `Cohere Command R+` | on-demand / dedicated retirement 표에 있음 |
| `Cohere Command R 16K` | on-demand / dedicated retirement 표에 있음 |
| `Cohere Command (52B)` | on-demand / dedicated retirement 표에 있음 |
| `Cohere Command Light` | on-demand / dedicated retirement 표에 있음 |
| `Meta Llama 3.1 70B` | on-demand / dedicated retirement 표에 있음 |
| `Meta Llama 3 70B` | on-demand / dedicated retirement 표에 있음 |
| `Meta Llama 2 70B` | dedicated retirement 표에 있음 |

### 15-2. replacement 방향이 문서에 명시된 주요 항목

| 기존 모델 | Oracle 문서의 replacement 방향 |
|---|---|
| `Cohere Command R(+)` 계열 | `Cohere Command A` |
| `Cohere Embed 3 / Image 3 / Light 3` 계열 | `Cohere Embed 4` |
| `Meta Llama 3.2 / 3.1 / 3` 일부 계열 | `Meta Llama 4 Maverick`, `Meta Llama 4 Scout` |
| `xAI Grok 3*` 계열 | `xAI Grok 4.3` |
| `xAI Grok 4.20` | `xAI Grok 4.3` |
| `xAI Grok 4.1 Fast` | `xAI Grok 4.3` |

---

## 16. 최종 하단 메모

### 16-1. 사용한 주요 공식 문서 범주

- OCI Generative AI release notes
- OCI Generative AI `Models by Region`
- OCI Generative AI `Dedicated Cluster Shapes by Region`
- OCI Generative AI 개별 모델 카드
- OCI Generative AI retirement / fine-tuning 문서
- OCI Generative AI imported model family 문서
- OCI Compute `Compute Shapes`
- OCI Data Science `Supported Compute Shapes` / `AI Quick Actions`
- OCI CLI 실조회 시도 로그

### 16-2. CLI 조회 성공/실패 상태 표

| 조회 항목 | 성공/실패 | 최종 처리 |
|---|---|---|
| `oci iam region-subscription list` | 실패 | Oracle 공식 리전 문서 기준으로 대체 |
| `oci compute shape list` | 실패 | Compute/Data Science shape 문서 기준으로 대체 |
| `oci os ns get` | 실패 | endpoint 응답 지연 확인용 보조 근거로만 사용 |

### 16-3. 이 문서에서 명시적으로 없는 것

- Oracle 공식 문서만으로 확정 가능한 `IaaS GPU 리전별 실시간 재고표`
- Oracle 공식 문서만으로 확정 가능한 `AQUA GPU 리전별 실시간 재고표`
- Oracle 공식 문서만으로 확정 가능한 `LARGE_COHERE_* / LARGE_GENERIC_*`의 실제 GPU 메모리
- Abu Dhabi 전용 `A10/A100/H100/H200` DAC hardware family 공개표

즉:

- `관리형 기본 모델의 리전/모드/DAC unit`은 Oracle 문서로 상당히 명확하게 정리 가능
- `IaaS/AQUA의 리전별 실재고`는 CLI 또는 Console 실조회가 없으면 확정할 수 없음
- `generic/cohere DAC unit의 실제 GPU 메모리`는 Oracle이 숨기므로 단정하면 안 됨

### 16-4. 참고한 주요 Oracle 공식 문서

- OCI Generative AI release notes: `Generative AI` 서비스 릴리스 노트
- Generative AI 모델 리전 표: `Regional availability for Generative AI models`
- DAC 하드웨어 공개표: `Dedicated AI Cluster Shapes by Region`
- imported 모델 안내: `Managing Imported Models`, `Compatible Models for Import`, `Compatible OpenAI/Meta/Alibaba/DeepSeek Models`
- fine-tuning 안내: `Selecting a Fine-Tuning Method in Generative AI`
- retirement 안내: `Model Retirement Dates (On-Demand Mode)`, `Model Retirement Dates (Dedicated Mode)`
- IaaS/AQUA GPU shape 안내: `Compute Shapes`, `Supported Compute Shapes`, `About AI Quick Actions`
