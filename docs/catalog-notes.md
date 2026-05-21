# OCI AI Region Catalog Notes

이 문서는 `catalog.html`과 `docs/data/latest-catalog.json`을 읽을 때의 해석 기준입니다.

## 컬럼별 데이터 기준

| 컬럼 | Source badge | 기반 데이터 | 의미 |
|---|---|---|---|
| Region | `CLI snapshot` | `regions[].region` | 구독 READY 리전 기반 행입니다. |
| GenAI Models | `CLI query` | `regions[].genai.models[]`, `regions[].genai.model_count` | `generative-ai model-collection list-models` 조회에서 관측된 모델입니다. |
| DAC Official Reference | `Oracle docs reference` | `docs/data/dac-reference.json`, fallback `regions[].dac` | Oracle 공식 Models by Region / Dedicated Cluster Shapes by Region 문서에서 확인한 DAC GPU family reference입니다. CLI 조회나 capacity 조회가 아닙니다. |
| Data Science / AQUA GPU | `CLI query` | `regions[].data_science.gpu_families`, `regions[].data_science.gpu_shapes` | Data Science job, notebook, model deployment shape 조회에서 관측된 GPU 문자열입니다. |
| IaaS GPU | `CLI query` | `regions[].iaas.gpu_families`, `regions[].iaas.gpu_shapes` | Compute shape list에서 관측된 GPU family와 shape입니다. |
| Query Details | `CLI query status` | `regions[].statuses`, `regions[].query_attempts` | 조회 항목별 최종 상태, 시도 횟수, 선택된 시도 번호입니다. |

`regions[].customer_notes[]`는 기존 스냅샷 호환성을 위해 JSON에 유지하는 보조 derived metadata입니다. 표 컬럼으로는 표시하지 않고, 서비스별 짧은 note와 `Query Details`를 우선 읽습니다.

## Summary metric 기준

| Metric | 기준 |
|---|---|
| `regions` | 현재 필터 결과에 포함된 리전 수입니다. |
| `GenAI model entries` | 현재 필터 결과의 `regions[].genai.model_count` 합계입니다. 같은 모델이 여러 리전에 있으면 리전별로 각각 세므로 global unique 모델 수가 아닙니다. |
| `DAC reference regions` | 현재 필터 결과 중 Oracle docs reference 기반 DAC reference가 있는 리전 수입니다. |
| `Data Science GPU shapes` | 현재 필터 결과에서 관측된 unique Data Science GPU shape 문자열 수입니다. |
| `IaaS GPU shapes` | 현재 필터 결과에서 관측된 unique Compute GPU shape 문자열 수입니다. |

## 상태 해석

| 상태 | 의미 | 해석 |
|---|---|---|
| `success + 항목 있음` | 조회가 완료됐고 표시할 모델/shape가 관측됨 | 실제 생성 가능, service limit, quota, capacity 보장은 아닙니다. |
| `success + 항목 없음` | 조회는 완료됐지만 표시할 항목이 없음 | 미지원으로 단정하지 말고 공식 문서와 limit/capacity를 함께 확인합니다. |
| `timeout` | 제한 시간 안에 응답을 받지 못함 | 미지원이 아닙니다. 재조회하면 결과가 달라질 수 있습니다. |
| `failed` | 조회 명령이 실패함 | 권한, endpoint, 일시 오류 가능성이 있으므로 원인 확인이 필요합니다. |
| `not-collected` | 공개 스냅샷이 없거나 fallback 행임 | DAC reference 같은 제한된 보조 정보만 볼 수 있습니다. |

## 재시도와 취합

AI catalog 수집은 기본적으로 `fast` profile을 사용합니다. 긴 재시도는 `balanced` 또는 `deep` profile을 명시한 수동 점검에서만 사용합니다.

- `OCI_CATALOG_PROFILE`: 기본값 `fast`
- `fast`: timeout `20`, attempts `1`, retry delay `0`, parallelism `24`
- `balanced`: timeout `30`, attempts `2`, retry delay `10`, parallelism `16`
- `deep`: timeout `45`, attempts `3`, retry delay `60`, parallelism `8`
- `OCI_CATALOG_ATTEMPTS`: profile 기본값 override
- `OCI_CATALOG_RETRY_DELAY_SECONDS`: profile 기본값 override
- `OCI_CATALOG_RETRY_ONLY_INCOMPLETE`: 기본값 `1`
- `OCI_CATALOG_RETRY_EMPTY_RESULTS`: 기본값 `1`

최종 공개 JSON에는 raw 경로, raw 오류, command, 계정/요청 식별자를 넣지 않습니다. 대신 `query_attempts`에 아래 공개 가능한 값만 넣습니다.

- `final_status`
- `attempts`
- `selected_attempt`
- `observed_item_count`

Best result 선택 기준은 다음 순서입니다.

1. `success + 항목 있음`
2. `success + 항목 없음`
3. `failed`
4. `timeout`

같은 우선순위에서는 먼저 성공한 시도를 사용합니다. 여러 success attempt의 결과를 병합하지 않고, 선택된 한 시도의 스냅샷을 사용합니다.

## Latest 스냅샷 갱신 기준

`docs/data/catalog-<date>.json`은 해당 실행 결과를 항상 보존합니다. 단, 실행 결과에 성공한 CLI 조회가 하나도 없으면 `docs/data/latest-catalog.json`은 덮어쓰지 않습니다.

이 기준은 일시적인 timeout-only 실행으로 GitHub Pages catalog가 빈 표처럼 보이는 일을 막기 위한 운영 정책입니다. timeout-only 결과도 날짜별 스냅샷과 `runs/<date>-ai-catalog/summary.md`에 남기며, 이후 네트워크나 OCI API 상태가 회복된 뒤 재실행하면 `latest-catalog.json`이 갱신됩니다.

## 주의

- `CLI query`는 실시간 inventory나 capacity 보장이 아니라 수집 시점의 API 조회 결과입니다.
- `Oracle docs reference`는 Oracle 공식 문서에서 확인한 DAC reference를 현재 가이드 기준으로 정리한 보조 reference입니다.
- `DAC Official Reference`는 리전 전체의 DAC 가능/불가능 판정이 아닙니다. 모델별 Oracle 문서와 capacity 확인이 필요합니다.
- Private endpoint는 미지원 리전에 모델이나 GPU capacity를 생성하지 않습니다.
