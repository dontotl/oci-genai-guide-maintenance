OCI 리전별 Generative AI / DAC / AQUA / IaaS GPU 가이드를 한국어 md로 다시 생성해줘.

조건:

- Oracle 공식 문서를 1순위로 사용
- OCI CLI 실조회는 Codex 안에서 직접 재실행하지 말고, 먼저 아래 사전 수집 결과를 확인
- OCI probe summary 경로: `<OCI_PROBE_SUMMARY>`
- OCI probe JSON 경로: `<OCI_PROBE_JSON>`
- 고객용 probe summary 경로: `<OCI_PROBE_CUSTOMER_SUMMARY>`
- AI catalog 공개 JSON 경로: `<AI_CATALOG_JSON>`
- AI catalog 고객용 matrix 경로: `<AI_CATALOG_CUSTOMER_MATRIX>`
- probe JSON과 고객용 summary가 있으면 이를 우선 근거로 사용
- AI catalog JSON과 고객용 matrix가 있으면 리전별 GenAI 모델, Data Science/AQUA shape, IaaS GPU shape 가시성의 우선 근거로 사용
- probe JSON이 없으면 probe summary와 원본 파일의 성공 결과를 사용
- probe JSON, 고객용 summary, probe summary가 없거나 특정 항목이 실패한 경우에만 실패 이유를 적고 문서 기준 해석표로 대체
- Codex 샌드박스의 네트워크 timeout을 실제 OCI CLI 조회 실패로 단정하지 말 것
- 결과 파일명은 `OCI_GenAI_Regional_Model_Guide_v3_<DATE>.md`
- 결과 파일 경로는 `<OUTPUT_FILE>`입니다
- 가로 폭이 너무 길지 않게 표를 여러 개로 나눌 것
- 반드시 최신 날짜를 문서에 명시할 것
- 반드시 한국어로 작성할 것
- 보고서 본문 말투는 `~다`, `~했다`, `~썼다` 체가 아니라 `~습니다`, `~했습니다`, `~썼습니다` 체로 작성할 것
- OCI를 잘 모르는 고객도 이해할 수 있도록 앞부분에 읽는 법과 주요 용어 설명을 넣을 것
- 앞부분에 Mermaid로 `서비스 선택 흐름`과 `워크로드별 추천 아키텍처`를 넣을 것. `서비스 선택 흐름`은 긴 이지선다가 아니라 `On-demand`, `Dedicated AI Cluster`, `AQUA / Data Science`, `IaaS GPU`의 4대 선택 범주로 단순화할 것. `워크로드별 추천 아키텍처`는 워크로드에서 대표 모델/기능 조합을 거쳐 4대 선택 범주로 연결할 것. Mermaid가 보이지 않는 환경을 위해 바로 아래에 짧은 요약 표도 유지할 것
- 내부 운영 로그, 로컬 파일 경로, 보조 연결 확인 값처럼 고객 의사결정에 직접 필요 없는 내용은 본문에서 제외할 것
- `docs/catalog.html`의 리전별 스냅샷 UI와 `docs/appendix/private-endpoint-architecture.md`의 private endpoint 별첨을 안내할 것
- private endpoint는 미지원 리전에 모델이나 GPU capacity를 생성하는 기능이 아니라, 지원 리전에 있는 GenAI endpoint를 private network로 접근하는 패턴이라고 명확히 적을 것

반드시 포함할 항목:

1. 처음 읽는 분을 위한 요약
2. 이번 업데이트 변화 요약
3. 선택 기준과 용어
4. 4대 서비스 선택 가이드
5. On-demand 모델 활용
6. Dedicated AI Cluster 활용
7. AQUA / Data Science 활용
8. IaaS GPU 활용
9. Import / Custom Model 운영
10. Fine-tuning 가능 여부
11. 리전 및 가용성 확인
12. 모델 강점과 빠른 추천
13. 검증 기준과 참고 문서

작성 규칙:

- 추정으로 단정하지 말 것
- Oracle 문서에 없으면 없다고 적을 것
- OCI 조회 상태는 `<OCI_PROBE_SUMMARY>`의 성공/실패 요약을 기준으로 적을 것
- 가능하면 OCI 조회 상태는 `<OCI_PROBE_JSON>`과 `<OCI_PROBE_CUSTOMER_SUMMARY>`의 정규화 결과를 기준으로 적을 것
- 공개 리포트의 CLI 조회 상태 표에는 원본 출력/오류 파일 경로와 보조 연결 확인에서 얻은 내부 식별자 값을 쓰지 말 것
- 공개 리포트에는 OCID, compartment OCID, tenancy OCID, namespace, OCI profile, raw stdout/stderr 경로, request id, raw 오류 전문을 쓰지 말 것
- `CLI에서 보임`, `공식 문서상 지원`, `capacity 확인 필요`를 서로 다른 의미로 구분해서 쓸 것
- probe summary에 성공 결과가 있으면 `region-subscription list`, `compute shape list`, `os ns get`을 실패로 쓰지 말 것
- 문장 종결은 정중한 보고서체로 통일할 것. 예: `작성했다` 대신 `작성했습니다`, `썼다` 대신 `썼습니다`
- deprecated / retired / newly added 모델이 있으면 문서 앞부분의 `이번 업데이트 변화 요약`에 먼저 적을 것
- `LATEST.md`로 복사될 수 있으므로 앞부분 1페이지 안에 핵심 변화가 보이게 쓸 것
- 표가 너무 넓으면 분리할 것
- 관리형 기본 모델과 imported model을 혼동하지 말 것
- `지원`, `shape 가시성`, `DAC hosting`, `fine-tuning`, `AQUA 가능`, `실제 capacity`가 서로 다른 의미임을 친절하게 설명할 것
- `shape가 보임`을 `즉시 생성 가능`으로, `DAC hosting 가능`을 `fine-tuning 가능`으로, `AQUA 지원`을 `리전별 GPU 재고 보장`으로 단정하지 말 것

추가로 해줄 것:

- 최종 문서 하단에 사용한 주요 공식 문서 범주를 짧게 정리
- OCI 조회 성공/실패 상태를 고객용 표현의 별도 표로 적기
