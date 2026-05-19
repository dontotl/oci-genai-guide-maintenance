#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DATE_ARG="${1:-$(date -u +%F)}"
RUN_DIR="$ROOT_DIR/runs"
PROMPT_TEMPLATE="$ROOT_DIR/OCI_GenAI_Regional_Model_Guide_Prompt.md"
OUT_FILE="$RUN_DIR/OCI_GenAI_Regional_Model_Guide_v3_${DATE_ARG}.md"
RUN_PROMPT="$RUN_DIR/${DATE_ARG}-refresh-prompt.md"
OCI_PROBE_SUMMARY="$RUN_DIR/${DATE_ARG}-oci-probe/summary.md"
OCI_PROBE_JSON="$RUN_DIR/${DATE_ARG}-oci-probe/probe.json"
OCI_PROBE_CUSTOMER_SUMMARY="$RUN_DIR/${DATE_ARG}-oci-probe/customer-summary.md"
AI_CATALOG_JSON="$ROOT_DIR/docs/data/latest-catalog.json"
AI_CATALOG_CUSTOMER_MATRIX="$RUN_DIR/${DATE_ARG}-ai-catalog/customer-matrix.md"

mkdir -p "$RUN_DIR"

if [[ ! -f "$OUT_FILE" ]]; then
  cat > "$OUT_FILE" <<EOF
# OCI Generative AI / DAC / AQUA / IaaS GPU 리전·모델 정리 v3

작성일: ${DATE_ARG}

이 파일은 생성용 스크립트로 먼저 만들어진 빈 문서입니다.
프롬프트를 실행해 내용을 채운 뒤 \`publish_guide.sh\`로 발행합니다.
EOF
fi

sed \
  -e "s|<DATE>|${DATE_ARG}|g" \
  -e "s|<OUTPUT_FILE>|${OUT_FILE}|g" \
  -e "s|<OCI_PROBE_SUMMARY>|${OCI_PROBE_SUMMARY}|g" \
  -e "s|<OCI_PROBE_JSON>|${OCI_PROBE_JSON}|g" \
  -e "s|<OCI_PROBE_CUSTOMER_SUMMARY>|${OCI_PROBE_CUSTOMER_SUMMARY}|g" \
  -e "s|<AI_CATALOG_JSON>|${AI_CATALOG_JSON}|g" \
  -e "s|<AI_CATALOG_CUSTOMER_MATRIX>|${AI_CATALOG_CUSTOMER_MATRIX}|g" \
  "$PROMPT_TEMPLATE" > "$RUN_PROMPT"

printf 'Created guide stub: %s\n' "$OUT_FILE"
printf 'Created refresh prompt: %s\n' "$RUN_PROMPT"
