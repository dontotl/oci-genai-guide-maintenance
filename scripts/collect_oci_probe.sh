#!/usr/bin/env bash
set -euo pipefail

export PATH="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"
export HOME="${HOME:-/home/opc}"

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DATE_ARG="${1:-$(date -u +%F)}"
OUT_DIR="$ROOT_DIR/runs/${DATE_ARG}-oci-probe"
SUMMARY_FILE="$OUT_DIR/summary.md"
CUSTOMER_SUMMARY_FILE="$OUT_DIR/customer-summary.md"
PROBE_JSON_FILE="$OUT_DIR/probe.json"
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

status_code_label() {
  local code="$1"
  if [[ "$code" == "0" ]]; then
    printf 'success'
  elif [[ "$code" == "124" ]]; then
    printf 'timeout'
  else
    printf 'failed'
  fi
}

meta_value() {
  local meta_file="$1"
  local key="$2"
  sed -n "s/^${key}=//p" "$meta_file" 2>/dev/null | head -n 1
}

table_cell_trim() {
  sed 's/^[[:space:]]*//; s/[[:space:]]*$//'
}

extract_region_count() {
  local file="$OUT_DIR/region-subscription-list.out"
  if [[ ! -f "$file" ]]; then
    printf '0'
    return
  fi

  awk -F'|' '
    $0 ~ /^\|/ {
      status = $5
      gsub(/^[[:space:]]+|[[:space:]]+$/, "", status)
      if (status == "READY") count++
    }
    END { print count + 0 }
  ' "$file"
}

extract_home_region() {
  local file="$OUT_DIR/region-subscription-list.out"
  if [[ ! -f "$file" ]]; then
    return
  fi

  awk -F'|' '
    $0 ~ /^\|/ {
      is_home = $2
      region = $4
      status = $5
      gsub(/^[[:space:]]+|[[:space:]]+$/, "", is_home)
      gsub(/^[[:space:]]+|[[:space:]]+$/, "", region)
      gsub(/^[[:space:]]+|[[:space:]]+$/, "", status)
      if (is_home == "True" && status == "READY") {
        print region
        exit
      }
    }
  ' "$file"
}

extract_region_names_json() {
  local file="$OUT_DIR/region-subscription-list.out"
  if [[ ! -f "$file" ]]; then
    printf '[]'
    return
  fi

  awk -F'|' '
    $0 ~ /^\|/ {
      region = $4
      status = $5
      gsub(/^[[:space:]]+|[[:space:]]+$/, "", region)
      gsub(/^[[:space:]]+|[[:space:]]+$/, "", status)
      if (status == "READY" && region != "region-name") print region
    }
  ' "$file" | sort -u | jq -R . | jq -s .
}

extract_shapes_json() {
  local file="$1"
  if [[ ! -f "$file" ]]; then
    printf '[]'
    return
  fi

  awk -F'|' '
    $0 ~ /^\|/ {
      shape = $4
      gsub(/^[[:space:]]+|[[:space:]]+$/, "", shape)
      if (shape ~ /GPU/) print shape
    }
  ' "$file" | sort -u | jq -R . | jq -s .
}

extract_families_json() {
  local file="$1"
  if [[ ! -f "$file" ]]; then
    printf '[]'
    return
  fi

  (grep -Eo 'P100|V100|A100|A10|H100|H200' "$file" 2>/dev/null || true) | sort -u | jq -R . | jq -s .
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

write_probe_json() {
  if ! command -v jq >/dev/null 2>&1; then
    printf 'jq not found. Skipping normalized probe JSON: %s\n' "$PROBE_JSON_FILE" >&2
    return
  fi

  local region_count home_region regions_json oci_version
  local region_items_file failures_file

  region_count="$(extract_region_count)"
  home_region="$(extract_home_region)"
  regions_json="$(extract_region_names_json)"
  oci_version="$(sed -n '1p' "$OUT_DIR/oci-version.out" 2>/dev/null | table_cell_trim)"
  region_items_file="$(mktemp)"
  failures_file="$(mktemp)"

  for region in "${REGIONS[@]}"; do
    local meta_file stdout_file code status shapes_json families_json shape_count has_gpu_shapes
    meta_file="$OUT_DIR/compute-shapes-${region}.meta"
    stdout_file="$OUT_DIR/compute-shapes-${region}.out"
    code="$(meta_value "$meta_file" exit_code)"
    code="${code:-1}"
    status="$(status_code_label "$code")"
    shapes_json="$(extract_shapes_json "$stdout_file")"
    families_json="$(extract_families_json "$stdout_file")"
    shape_count="$(printf '%s' "$shapes_json" | jq 'length')"
    has_gpu_shapes=false
    if [[ "$shape_count" != "0" ]]; then
      has_gpu_shapes=true
    fi

    jq -n \
      --arg region "$region" \
      --arg status "$status" \
      --argjson exit_code "$code" \
      --argjson has_gpu_shapes "$has_gpu_shapes" \
      --argjson gpu_families "$families_json" \
      --argjson shapes "$shapes_json" \
      '{
        region: $region,
        status: $status,
        exit_code: $exit_code,
        has_gpu_shapes: $has_gpu_shapes,
        gpu_families: $gpu_families,
        shapes: $shapes
      }' >> "$region_items_file"

    if [[ "$status" != "success" ]]; then
      jq -n \
        --arg item "compute-shapes-${region}" \
        --arg status "$status" \
        --argjson exit_code "$code" \
        '{item: $item, status: $status, exit_code: $exit_code}' >> "$failures_file"
    fi
  done

  for meta in "$OUT_DIR"/*.meta; do
    [[ -f "$meta" ]] || continue
    local name code status
    name="$(basename "$meta" .meta)"
    [[ "$name" == compute-shapes-* ]] && continue
    [[ "$name" != "region-subscription-list" ]] && continue
    code="$(meta_value "$meta" exit_code)"
    code="${code:-1}"
    status="$(status_code_label "$code")"
    if [[ "$status" != "success" ]]; then
      jq -n \
        --arg item "$name" \
        --arg status "$status" \
        --argjson exit_code "$code" \
        '{item: $item, status: $status, exit_code: $exit_code}' >> "$failures_file"
    fi
  done

  jq -n \
    --arg date "$DATE_ARG" \
    --arg profile "$PROFILE" \
    --arg timeout_seconds "$TIMEOUT_SECONDS" \
    --arg oci_version "$oci_version" \
    --arg home_region "$home_region" \
    --argjson subscribed_count "$region_count" \
    --argjson subscribed_regions "$regions_json" \
    --slurpfile gpu_shape_probe "$region_items_file" \
    --slurpfile failures "$failures_file" \
    '{
      schema_version: "1.0",
      date: $date,
      source: "oci-cli-preflight",
      profile: $profile,
      timeout_seconds: ($timeout_seconds | tonumber),
      oci_version: $oci_version,
      subscribed_regions: {
        count: $subscribed_count,
        home_region: $home_region,
        regions: $subscribed_regions
      },
      gpu_shape_probe: $gpu_shape_probe,
      failures: $failures,
      report_guidance: [
        "Do not expose raw stdout/stderr paths in customer reports.",
        "Do not expose tenancy OCID, namespace, local paths, or Codex runtime details in customer reports.",
        "Shape visibility does not guarantee immediate resource creation.",
        "AQUA region support does not guarantee region-specific GPU capacity."
      ]
    }' > "$PROBE_JSON_FILE"

  rm -f "$region_items_file" "$failures_file"
}

write_customer_summary() {
  if ! command -v jq >/dev/null 2>&1 || [[ ! -f "$PROBE_JSON_FILE" ]]; then
    return
  fi

  {
    echo "# OCI Probe Customer Summary"
    echo
    echo "작성일: ${DATE_ARG}"
    echo
    echo "이 파일은 고객용 리포트에 직접 반영할 수 있는 조회 요약입니다. raw 출력 경로, 내부 식별자, 보조 연결 확인 값은 제외했습니다."
    echo
    echo "## 조회 결과 요약"
    echo
    echo "| 조회 항목 | 결과 | 고객 관점의 의미 |"
    echo "|---|---|---|"

    local region_count failures_count region_subscription_failed
    region_count="$(jq -r '.subscribed_regions.count' "$PROBE_JSON_FILE")"
    failures_count="$(jq -r '.failures | length' "$PROBE_JSON_FILE")"
    region_subscription_failed="$(jq -r 'any(.failures[]?; .item == "region-subscription-list")' "$PROBE_JSON_FILE")"

    if [[ "$region_subscription_failed" == "true" ]]; then
      echo "| 구독 리전 | 조회 실패 | 문서 기준 리전 해석표로 대체해야 합니다. |"
    elif [[ "$region_count" != "0" ]]; then
      echo "| 구독 리전 | ${region_count}개 READY 리전 확인 | 이 테넌시에서 여러 글로벌 리전을 사용할 수 있습니다. |"
    else
      echo "| 구독 리전 | ${region_count}개 READY 리전 확인 | 이 테넌시에서 사용할 수 있는 READY 리전 수입니다. |"
    fi

    if [[ "$failures_count" == "0" ]]; then
      echo "| 대표 리전 IaaS GPU shape | 조회 성공 | 대표 리전의 GPU shape 가시성을 확인했습니다. |"
      echo "| 실패 항목 | 없음 | 이번 대표 리전 조회에서는 실패로 처리한 항목이 없습니다. |"
    else
      echo "| 대표 리전 IaaS GPU shape | 일부 실패 | 성공한 리전과 실패한 리전을 분리해 해석해야 합니다. |"
      echo "| 실패 항목 | ${failures_count}개 | 실패 항목은 고객용 리포트에서 원인과 대체 해석을 별도로 설명해야 합니다. |"
    fi

    echo
    echo "## 대표 리전 GPU shape 가시성"
    echo
    echo "| 리전 | 조회 상태 | 보인 GPU 계열 | 보인 shape |"
    echo "|---|---|---|---|"

    jq -r '
      .gpu_shape_probe[]
      | [
          .region,
          (if .status == "success" then "성공" elif .status == "timeout" then "실패 (timeout)" else "실패" end),
          (if (.gpu_families | length) > 0 then (.gpu_families | join(", ")) else "없음" end),
          (if (.shapes | length) > 0 then (.shapes | join(", ")) else "없음" end)
        ]
      | @tsv
    ' "$PROBE_JSON_FILE" | while IFS=$'\t' read -r region status families shapes; do
      echo "| \`${region}\` | ${status} | ${families} | ${shapes} |"
    done

    echo
    echo "## 해석 기준"
    echo
    echo "- 이 요약은 대표 리전의 shape 가시성 확인 결과입니다."
    echo "- shape가 보인다는 것은 해당 리전에서 즉시 생성 가능하다는 뜻이 아닙니다."
    echo "- 실제 생성 가능 여부는 service limit, quota, capacity, AD별 가용성을 별도로 확인해야 합니다."
    echo "- AQUA 지원은 리전별 GPU 재고 보장을 뜻하지 않습니다."
  } > "$CUSTOMER_SUMMARY_FILE"
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

write_probe_json
write_customer_summary
write_summary

printf 'Wrote OCI probe summary: %s\n' "$SUMMARY_FILE"
if [[ -f "$PROBE_JSON_FILE" ]]; then
  printf 'Wrote normalized OCI probe JSON: %s\n' "$PROBE_JSON_FILE"
fi
if [[ -f "$CUSTOMER_SUMMARY_FILE" ]]; then
  printf 'Wrote customer-safe OCI probe summary: %s\n' "$CUSTOMER_SUMMARY_FILE"
fi
