# OCI 리전별 모델 가이드 생성용 운영 MD

작성일: 2026-04-17

이 문서는 `OCI_GenAI_Regional_Model_Guide_v2_YYYY-MM-DD.md` 같은 결과 문서를
주기적으로 다시 생성하거나 업데이트하기 위한 **생성 지침서**입니다.

목표는 다음과 같습니다.

- 같은 형식의 리전별 모델 가이드를 반복 생성할 수 있게 하기
- 최신 Oracle 공식 문서와 가능한 경우 OCI CLI 조회값을 반영하기
- 표 폭이 너무 길어지지 않도록 구조를 고정하기
- 사람이 읽기 좋은 한국어 운영 문서 형태를 유지하기

---

## 1. 최종 산출물

생성 대상 파일명 규칙:

```text
OCI_GenAI_Regional_Model_Guide_v2_YYYY-MM-DD.md
```

예:

```text
OCI_GenAI_Regional_Model_Guide_v2_2026-04-17.md
```

문서는 반드시 한국어로 작성한다.

---

## 2. 생성할 문서의 범위

최종 문서에는 아래 내용을 포함한다.

1. 리전별 `OCI Generative AI / DAC / AQUA` 지원 여부
2. 리전별 `DAC A10 / A100 / H100 / H200` 가시성
3. `IaaS VM / AQUA`의 GPU shape 해석
4. `IaaS GPU shape -> GPU 종류` 매핑
5. 온디맨드 제공 모델 요약
6. 모델 설명
7. 파라미터 또는 컨텍스트 길이
8. DAC 배포 필요 GPU 메모리
9. 권장 DAC 유닛
10. 파인튜닝 가능 여부
11. imported/fine-tuned 모델 관점의 권장 DAC
12. 모델 유형 분류
13. 모델이 잘하는 부분
14. `A100 / H100 / H200` 선택 가이드

문서는 가로 폭이 과도하게 길어지지 않도록 **여러 개의 표로 분리**한다.

---

## 3. 우선 순위 데이터 소스

항상 아래 우선순위를 따른다.

### 3-1. 1순위

Oracle 공식 문서

필수 확인 범주:

- Generative AI Regions
- Generative AI Models by Region
- Generative AI Dedicated Cluster Shapes by Region
- 각 모델 카드
- Data Science AI Quick Actions
- Data Science Supported Compute Shapes
- OCI Compute Shapes
- Imported Models 문서

### 3-2. 2순위

OCI CLI 실제 조회값

사용 목적:

- 리전별 실제 `compute shape list` 결과 확인
- 문서상 shape와 실제 테넌시에서 보이는 shape를 대조

### 3-3. 3순위

릴리즈 노트

사용 목적:

- 신규 리전 추가
- 신규 모델 추가
- deprecated 또는 retired 여부 확인

### 3-4. 금지

- 블로그
- 커뮤니티 게시글
- 출처가 불명확한 정리글

공식 문서와 충돌하면 공식 문서를 우선한다.

---

## 4. OCI CLI 조회 규칙

가능하면 실제 CLI 조회도 시도한다.

### 4-1. 리전 목록 조회

```bash
oci iam region-subscription list --all \
  --query 'data[]."region-name"' \
  --raw-output
```

### 4-2. 리전별 GPU shape 조회

```bash
oci --region <region> compute shape list --all \
  -c <tenancy_or_compartment_ocid> \
  --query 'data[?contains(shape, `GPU`)].{shape:shape,gpus:gpus,"gpu-desc":"gpu-description",memory:"memory-in-gbs",ocpus:ocpus}' \
  --output table
```

### 4-3. CLI 조회 실패 시 처리 규칙

만약 `compute shape list`가 아래 오류로 실패하면:

- `NotAuthorizedOrNotFound`
- `NotAuthorized`
- `Out of host capacity`

최종 문서에는 다음 원칙으로 적는다.

- `CLI 자동 수집 실패`
- 실패 원인이 권한인지 capacity인지 구분해서 메모
- 해당 리전의 IaaS GPU 여부는 **문서 기준 해석표**로 대체
- 거짓 확정 표현을 쓰지 않는다

예:

```text
현재 계정으로 Compute ListShapes 권한이 없어 실제 리전별 GPU shape 자동 수집은 실패했다.
따라서 IaaS GPU 리전 여부는 Oracle 공식 shape 문서와 운영 해석 기준으로 정리했다.
```

---

## 5. Shape 이름 매핑 규칙

아래 매핑은 고정 규칙으로 사용한다.

| Shape 패턴 | GPU 해석 |
|---|---|
| `VM.GPU3.1`, `VM.GPU3.2`, `VM.GPU3.4`, `BM.GPU3.8` | V100 |
| `VM.GPU.A10.1`, `VM.GPU.A10.2`, `BM.GPUA10.4` | A10 |
| `BM.GPU4.8` | A100 40G |
| `BM.GPU.A100-v2.8` | A100 80G |
| `BM.GPU.H100.8` | H100 80G |
| `BM.GPU.H200.8` | H200 141G |
| `BM.GPU.L40S-NC.4` | L40S |

이 매핑은 Oracle의 Data Science/Compute shape 문서 기준으로 유지한다.

---

## 6. 문서 구조 고정안

결과 문서는 아래 순서를 유지한다.

### 0. 먼저 봐야 하는 전제

- 용어
- 중요한 제한사항
- 이번 버전에서 추가한 것

### 1. 리전별 지원 요약

- `Generative AI / DAC / AQUA` 리전 요약
- 리전별 DAC 유닛 가시성
- `IaaS VM / AQUA`의 A100/H100 판정 방법
- 리전별 A100/H100 보유 여부 해석표

### 2. OCI CLI 기준 IaaS GPU shape 조회와 문서 매핑

- 조회 명령
- 현재 테넌시 조회 상태
- shape-to-GPU 매핑
- CLI 결과 해석법

### 3. IaaS VM / AQUA에서 볼 수 있는 GPU 재고

- Data Science/AQUA GPU shape
- IaaS Compute Bare Metal GPU shape

### 4. 온디맨드 + 전용(DAC) 실무 핵심 모델

- 종합 / 멀티모달 / 추론 / 임베딩
- DAC 중심 모델
- DAC 유닛별 배포 필요 GPU 메모리

### 5. 온디맨드/전용 여부 요약

### 6. Import / Custom Deployment 기준 권장 DAC

### 7. 파인튜닝 관점 정리

- 관리형 기본 모델 기준
- AQUA / Data Science 기준
- `A100 / H100 / H200` 선택 가이드

### 8. 모델별 강점 한 줄 정리

### 9. 빠른 추천

### 10. 출처

### 11. 마지막 메모

---

## 7. 표 설계 규칙

표가 너무 넓어지지 않게 아래 규칙을 따른다.

1. 한 표에 7열을 넘기지 않는 것을 기본 원칙으로 한다.
2. `모델 설명`, `잘하는 부분`, `비고`는 짧은 문장으로 적는다.
3. `파라미터`, `컨텍스트`, `FT`, `온디맨드`, `DAC`는 별도 열로 분리한다.
4. 긴 모델 설명은 표 아래 보충 문장으로 빼도 된다.
5. `온디맨드 모델 표`와 `DAC 중심 모델 표`는 분리한다.
6. `GPU shape 표`와 `모델 표`를 섞지 않는다.

---

## 8. 모델 표 작성 규칙

핵심 모델 표는 아래 열 구성을 기본으로 한다.

| 모델 | 유형 | 파라미터 / 컨텍스트 | 온디맨드 | DAC 배포 유닛 | FT | 강한 부분 |
|---|---|---|---|---|---|---|

필요하면 다음 보조 표를 추가한다.

| DAC 유닛 | 대응 GPU | 총 GPU 메모리 | 적합한 용도 |
|---|---|---:|---|

또는

| Hugging Face ID | Capability | 권장 DAC |
|---|---|---|

---

## 9. 파인튜닝 정리 규칙

다음 두 층위로 나눠 적는다.

### 9-1. OCI Generative AI 관리형 기본 모델

- 모델 카드에 `Not available for fine-tuning`인지 확인
- 가능/불가를 명시
- 억지 추정 금지

### 9-2. Imported model / AQUA / Data Science

- imported model fine-tuning 지원 조건 확인
- 권장 DAC가 있으면 표로 제시
- 명시가 없으면 범용 해석으로만 작성

예:

- 작은 모델 또는 LoRA: A10부터 검토
- 70B 전후: A100 80G부터 검토
- 대형 reasoning / multimodal / MoE: H100 이상
- 매우 큰 모델 또는 메모리 병목: H200 검토

---

## 10. 검증 체크리스트

문서 생성 후 반드시 아래를 확인한다.

1. 리전명과 region identifier가 최신인지
2. 모델명이 최신 표기인지
3. retired/deprecated 모델이 들어갔는지
4. `온디맨드 only`, `DAC only`, `둘 다 가능` 구분이 맞는지
5. `A100/H100/H200` 표기가 일관적인지
6. shape와 GPU 모델 매핑이 맞는지
7. imported model 권장 DAC가 최신인지
8. 파인튜닝 가능 여부를 추측으로 쓰지 않았는지
9. 표 가로 폭이 과도하지 않은지
10. 마지막에 주의사항이 들어갔는지

---

## 11. 실제 생성 프롬프트 템플릿

아래 텍스트를 그대로 다음 작업 프롬프트의 기반으로 써도 된다.

```text
OCI 리전별 Generative AI / DAC / AQUA / IaaS GPU 가이드를 한국어 md로 다시 생성해줘.

조건:
- Oracle 공식 문서를 1순위로 사용
- 가능하면 OCI CLI로 region-subscription list와 compute shape list도 조회
- CLI 조회 실패 시 실패 이유를 적고 문서 기준 해석표로 대체
- 결과 파일명은 OCI_GenAI_Regional_Model_Guide_v2_YYYY-MM-DD.md
- 가로 폭이 너무 길지 않게 표를 여러 개로 나눌 것
- 반드시 아래 항목을 포함할 것:
  1. 리전별 Generative AI / DAC / AQUA 지원
  2. 리전별 DAC A10/A100/H100/H200 가시성
  3. IaaS GPU shape 조회 명령과 결과 해석법
  4. shape-to-GPU 매핑
  5. IaaS/AQUA GPU 재고표
  6. 온디맨드 핵심 모델 표
  7. DAC 중심 모델 표
  8. DAC 유닛별 배포 필요 GPU 메모리 표
  9. import/custom deployment 권장 DAC
  10. 파인튜닝 가능 여부
  11. A100/H100/H200 선택 가이드
  12. 모델 강점 요약
  13. 빠른 추천
- 억지 추정은 하지 말고, 문서상 없으면 없다고 적을 것
```

---

## 12. 주기 업데이트 규칙

이 문서는 아래 시점에 다시 돌린다.

- 월 1회
- Oracle Generative AI 릴리즈 노트에 새 모델이 올라왔을 때
- 새 리전 추가 공지가 나왔을 때
- OpenAI/Cohere/Meta/Gemini/xAI 모델 카드 변경이 확인됐을 때
- 내부에서 새 리전 도입 검토가 시작됐을 때

추천 방식:

- `v2` 문서를 새 날짜로 복제
- 이 생성용 MD를 기준으로 다시 수집
- 변경된 모델 / 리전 / DAC만 우선 diff 확인

---

## 13. 운영 팁

- `IaaS GPU 리전 여부`는 문서만으로 단정하지 말고 가능하면 CLI로 교차 확인한다.
- CLI가 안 되면 권한 문제인지, 리전 문제인지, capacity 문제인지 구분해서 적는다.
- `AQUA에서 가능`과 `즉시 GPU 생성 가능`은 같은 의미가 아니다.
- `DAC 지원`과 `온디맨드 지원`은 반드시 분리해서 적는다.
- imported model 권장 DAC는 관리형 기본 모델의 DAC와 혼동하지 않는다.

---

## 14. 이 문서로 생성되는 대표 산출물

- [OCI_GenAI_Regional_Model_Guide_v2_2026-04-17.md](../guides/OCI_GenAI_Regional_Model_Guide_v2_2026-04-17.md)
