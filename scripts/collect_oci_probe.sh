#!/usr/bin/env bash
set -euo pipefail

export PATH="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"
export HOME="${HOME:-/home/opc}"

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DATE_ARG="${1:-$(date -u +%F)}"
OUT_DIR="$ROOT_DIR/runs/${DATE_ARG}-oci-probe"
SUMMARY_FILE="$OUT_DIR/summary.md"
TIMEOUT_SECONDS="${OCI_PROBE_TIMEOUT_SECONDS:-45}"
PROFILE="${OCI_CLI_PROFILE:-DEFAULT}"
REGION_LIST="${OCI_PROBE_REGIONS:-us-ashburn-1 us-phoenix-1 eu-frankfurt-1 uk-london-1 ap-seoul-1 ap-osaka-1 me-dubai-1 me-riyadh-1 me-abudhabi-1}"
CONFIG_FILE="${OCI_CLI_CONFIG_FILE:-$HOME/.oci/config}"

mkdir -p "$OUT_DIR"

read -r -a REGIONS <<< "$REGION_LIST"

read_config_value() {
  local key="$1"
  local section="$PROFILE"

  awk -F= -v section="$section" -v key="$key" '
    BEGIN { in_section = 0 }
    /^\[/ {
      current = $0
      gsub(/^\[/, "", current)
      gsub(/\]$/, "", current)
      in_section = (current == section)
      next
    }
    in_section {
      name = $1
      gsub(/[[:space:]]/, "", name)
      if (name == key) {
        value = $2
        sub(/^[[:space:]]+/, "", value)
        sub(/[[:space:]]+$/, "", value)
        print value
        exit
      }
    }
  ' "$CONFIG_FILE" 2>/dev/null || true
}

TENANCY_ID="${OCI_PROBE_COMPARTMENT_ID:-$(read_config_value tenancy)}"

status_label() {
  local code="$1"
  if [[ "$code" == "0" ]]; then
    printf '성공'
  elif [[ "$code" == "124" ]]; then
    printf '실패 (timeout %ss)' "$TIMEOUT_SECONDS"
  else
    printf '실패 (exit %s)' "$code"
  fi
}

run_probe() {
  local name="$1"
  local description="$2"
  shift 2

  local stdout_file="$OUT_DIR/${name}.out"
  local stderr_file="$OUT_DIR/${name}.err"
  local meta_file="$OUT_DIR/${name}.meta"
  local start end elapsed code

  start="$(date +%s)"
  set +e
  timeout --signal=TERM "$TIMEOUT_SECONDS" "$@" >"$stdout_file" 2>"$stderr_file"
  code="$?"
  set -e
  end="$(date +%s)"
  elapsed="$((end - start))"

  {
    printf 'description=%s\n' "$description"
    printf 'command='
    printf '%q ' "$@"
    printf '\n'
    printf 'exit_code=%s\n' "$code"
    printf 'status=%s\n' "$(status_label "$code")"
    printf 'elapsed_seconds=%s\n' "$elapsed"
    printf 'stdout=%s\n' "$stdout_file"
    printf 'stderr=%s\n' "$stderr_file"
  } > "$meta_file"
}

write_summary() {
  {
    echo "# OCI Probe Summary"
    echo
    echo "작성일: ${DATE_ARG}"
    echo
    echo "이 파일은 Codex 샌드박스가 아니라 VM의 일반 실행 환경에서 미리 수집한 OCI CLI 조회 결과입니다."
    echo
    echo "## 실행 환경"
    echo
    echo "| 항목 | 값 |"
    echo "|---|---|"
    echo "| OCI CLI profile | \`${PROFILE}\` |"
    echo "| OCI config file | \`${CONFIG_FILE}\` |"
    echo "| compartment/tenancy OCID | \`${TENANCY_ID:-미확인}\` |"
    echo "| timeout | \`${TIMEOUT_SECONDS}s\` |"
    echo "| probe directory | \`${OUT_DIR}\` |"
    echo
    echo "## 조회 결과"
    echo
    echo "| 조회 항목 | 상태 | 원본 stdout | 원본 stderr |"
    echo "|---|---|---|---|"

    for meta in "$OUT_DIR"/*.meta; do
      [[ -f "$meta" ]] || continue
      local description status stdout_path stderr_path
      description="$(sed -n 's/^description=//p' "$meta")"
      status="$(sed -n 's/^status=//p' "$meta")"
      stdout_path="$(sed -n 's/^stdout=//p' "$meta")"
      stderr_path="$(sed -n 's/^stderr=//p' "$meta")"
      echo "| ${description} | ${status} | \`${stdout_path#$ROOT_DIR/}\` | \`${stderr_path#$ROOT_DIR/}\` |"
    done

    echo
    echo "## GPU shape 요약"
    echo
    echo "아래 내용은 각 리전의 \`compute shape list\` 결과 중 GPU shape만 추린 원본 출력입니다."
    echo

    for region in "${REGIONS[@]}"; do
      local file="$OUT_DIR/compute-shapes-${region}.out"
      echo "### ${region}"
      echo
      if [[ -s "$file" ]]; then
        echo '```text'
        sed -n '1,80p' "$file"
        echo '```'
      else
        echo "- GPU shape 출력이 없거나 조회에 실패했습니다."
      fi
      echo
    done

    echo "## 사용 지침"
    echo
    echo "- 리포트 생성 시 이 summary와 원본 파일을 우선 근거로 사용합니다."
    echo "- 이 파일에 성공 결과가 있으면 Codex 내부 네트워크 timeout을 OCI 조회 실패로 간주하지 않습니다."
    echo "- 일부 리전만 실패한 경우 성공한 리전은 실조회 결과로, 실패한 리전은 실패 사유와 문서 기준 해석표로 분리해 작성합니다."
  } > "$SUMMARY_FILE"
}

if ! command -v oci >/dev/null 2>&1; then
  {
    echo "# OCI Probe Summary"
    echo
    echo "작성일: ${DATE_ARG}"
    echo
    echo "OCI CLI를 찾지 못해 사전 조회를 수행하지 못했습니다."
  } > "$SUMMARY_FILE"
  printf 'OCI CLI not found. Wrote summary: %s\n' "$SUMMARY_FILE"
  exit 0
fi

run_probe "oci-version" "OCI CLI 버전" oci --version
run_probe "os-ns-get" "Object Storage namespace 확인" oci --region ap-seoul-1 os ns get --output table
run_probe "region-subscription-list" "구독 리전 조회" oci iam region-subscription list --all --output table

if [[ -n "$TENANCY_ID" ]]; then
  for region in "${REGIONS[@]}"; do
    run_probe "compute-shapes-${region}" "GPU shape 조회 (${region})" \
      oci --region "$region" compute shape list --all -c "$TENANCY_ID" \
      --query "data[?contains(shape, 'GPU')].{shape:shape,gpuDescription:\"gpu-description\",processorDescription:\"processor-description\"}" \
      --output table
  done
else
  printf 'tenancy value not found in OCI config profile %s\n' "$PROFILE" > "$OUT_DIR/compute-shapes.err"
fi

write_summary

printf 'Wrote OCI probe summary: %s\n' "$SUMMARY_FILE"
