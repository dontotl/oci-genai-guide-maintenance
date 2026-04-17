OCI 리전별 Generative AI / DAC / AQUA / IaaS GPU 가이드를 한국어 md로 다시 생성해줘.

조건:

- Oracle 공식 문서를 1순위로 사용
- 가능하면 OCI CLI로 `region-subscription list`와 `compute shape list`도 조회
- CLI 조회 실패 시 실패 이유를 적고 문서 기준 해석표로 대체
- 결과 파일명은 `OCI_GenAI_Regional_Model_Guide_v2_<DATE>.md`
- 결과 파일 경로는 `<OUTPUT_FILE>` 이다
- 가로 폭이 너무 길지 않게 표를 여러 개로 나눌 것
- 반드시 최신 날짜를 문서에 명시할 것
- 반드시 한국어로 작성할 것

반드시 포함할 항목:

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
14. 이번 업데이트 변화 요약

작성 규칙:

- 추정으로 단정하지 말 것
- Oracle 문서에 없으면 없다고 적을 것
- deprecated / retired / newly added 모델이 있으면 문서 앞부분의 `이번 업데이트 변화 요약`에 먼저 적을 것
- `LATEST.md`로 복사될 수 있으므로 앞부분 1페이지 안에 핵심 변화가 보이게 쓸 것
- 표가 너무 넓으면 분리할 것
- 관리형 기본 모델과 imported model을 혼동하지 말 것

추가로 해줄 것:

- 최종 문서 하단에 사용한 주요 공식 문서 범주를 짧게 정리
- CLI 조회 성공/실패 상태를 별도 표로 적기

