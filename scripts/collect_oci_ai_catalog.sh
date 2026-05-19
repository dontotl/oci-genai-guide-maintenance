#!/usr/bin/env bash
set -euo pipefail

export PATH="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"
export HOME="${HOME:-/home/opc}"

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DATE_ARG="${1:-$(date -u +%F)}"
OUT_DIR="$ROOT_DIR/runs/${DATE_ARG}-ai-catalog"
PUBLIC_DATA_DIR="$ROOT_DIR/docs/data"
PUBLIC_JSON="$PUBLIC_DATA_DIR/catalog-${DATE_ARG}.json"
LATEST_JSON="$PUBLIC_DATA_DIR/latest-catalog.json"
SUMMARY_FILE="$OUT_DIR/summary.md"
CUSTOMER_MATRIX="$OUT_DIR/customer-matrix.md"
TIMEOUT_SECONDS="${OCI_CATALOG_TIMEOUT_SECONDS:-45}"
PARALLELISM="${OCI_CATALOG_PARALLELISM:-8}"
RETENTION_COUNT="${OCI_CATALOG_RETENTION_COUNT:-12}"
PROFILE="${OCI_CLI_PROFILE:-DEFAULT}"
CONFIG_FILE="${OCI_CLI_CONFIG_FILE:-$HOME/.oci/config}"
REGION_ALLOWLIST="${OCI_CATALOG_REGIONS:-}"
USE_EXISTING_RAW="${OCI_CATALOG_USE_EXISTING_RAW:-0}"

mkdir -p "$OUT_DIR" "$PUBLIC_DATA_DIR"

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

COMPARTMENT_ID="${OCI_CATALOG_COMPARTMENT_ID:-${OCI_PROBE_COMPARTMENT_ID:-$(read_config_value tenancy)}}"

status_label() {
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

run_probe() {
  local name="$1"
  local description="$2"
  shift 2

  local stdout_file="$OUT_DIR/${name}.json"
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
  } > "$meta_file"
}

active_jobs=0

wait_for_slot() {
  while (( active_jobs >= PARALLELISM )); do
    wait -n || true
    active_jobs="$((active_jobs - 1))"
  done
}

schedule_probe() {
  wait_for_slot
  run_probe "$@" &
  active_jobs="$((active_jobs + 1))"
}

wait_for_all_probes() {
  while (( active_jobs > 0 )); do
    wait -n || true
    active_jobs="$((active_jobs - 1))"
  done
}

safe_json_file() {
  local file="$1"
  if [[ -s "$file" ]] && jq empty "$file" >/dev/null 2>&1; then
    printf '%s' "$file"
  else
    printf '/dev/null'
  fi
}

safe_status() {
  local name="$1"
  local meta="$OUT_DIR/${name}.meta"
  local code
  code="$(meta_value "$meta" exit_code)"
  status_label "${code:-1}"
}

discover_regions() {
  if [[ -n "$REGION_ALLOWLIST" ]]; then
    tr ' ' '\n' <<< "$REGION_ALLOWLIST" | sed '/^[[:space:]]*$/d'
    return
  fi

  if [[ -s "$OUT_DIR/region-subscription-list.json" ]] && jq empty "$OUT_DIR/region-subscription-list.json" >/dev/null 2>&1; then
    jq -r '.data[]? | select(."status" == "READY") | ."region-name"' "$OUT_DIR/region-subscription-list.json" | sort -u
    return
  fi

  find "$OUT_DIR" -maxdepth 1 -type f -name 'compute-gpu-shapes-*.json' -printf '%f\n' |
    sed -E 's/^compute-gpu-shapes-(.*)\.json$/\1/' |
    sort -u
}

extract_models_json() {
  local file="$1"
  if [[ "$file" == "/dev/null" ]]; then
    printf '[]'
    return
  fi

  jq '
    [
      (
        if (.data | type) == "array" then
          .data[]?
        elif (.data | type) == "object" then
          .data.items[]?
        else
          empty
        end
      )
      | {
          display_name: (."display-name" // .displayName // "unknown"),
          vendor: (.vendor // "unknown"),
          capabilities: (."capabilities" // .capabilities // []),
          lifecycle_state: (."lifecycle-state" // .lifecycleState // "unknown")
        }
    ]
    | unique_by(.display_name, .vendor)
    | sort_by(.vendor, .display_name)
  ' "$file"
}

extract_shapes_json() {
  local file="$1"
  if [[ "$file" == "/dev/null" ]]; then
    printf '[]'
    return
  fi

  jq '
    [
      .. | strings
      | select(test("GPU|A10|A100|H100|H200|P100|V100|MI300|MI355|B200|GB200|GB300"))
      | select(test("^ocid1\\.") | not)
    ]
    | unique
    | sort
  ' "$file"
}

extract_gpu_families_json() {
  jq '
    [
      .[]?
      | capture("(?<family>P100|V100|A10|A100|H100|H200|MI300|MI355|B200|GB200|GB300)")?
      | .family
    ]
    | unique
    | sort
  '
}

write_public_catalog() {
  if ! command -v jq >/dev/null 2>&1; then
    printf 'jq not found. Cannot write public catalog JSON.\n' >&2
    return 1
  fi

  local region_items_file
  region_items_file="$(mktemp)"

  for region in "${REGIONS[@]}"; do
    local genai_file job_file notebook_file deployment_file compute_file
    local genai_status job_status notebook_status deployment_status compute_status
    local models_json job_shapes_json notebook_shapes_json deployment_shapes_json iaas_shapes_json
    local ds_shapes_json ds_families_json iaas_families_json notes_json

    genai_file="$(safe_json_file "$OUT_DIR/genai-models-${region}.json")"
    job_file="$(safe_json_file "$OUT_DIR/ds-job-shapes-${region}.json")"
    notebook_file="$(safe_json_file "$OUT_DIR/ds-notebook-shapes-${region}.json")"
    deployment_file="$(safe_json_file "$OUT_DIR/ds-model-deployment-shapes-${region}.json")"
    compute_file="$(safe_json_file "$OUT_DIR/compute-gpu-shapes-${region}.json")"

    genai_status="$(safe_status "genai-models-${region}")"
    job_status="$(safe_status "ds-job-shapes-${region}")"
    notebook_status="$(safe_status "ds-notebook-shapes-${region}")"
    deployment_status="$(safe_status "ds-model-deployment-shapes-${region}")"
    compute_status="$(safe_status "compute-gpu-shapes-${region}")"

    models_json="$(extract_models_json "$genai_file")"
    job_shapes_json="$(extract_shapes_json "$job_file")"
    notebook_shapes_json="$(extract_shapes_json "$notebook_file")"
    deployment_shapes_json="$(extract_shapes_json "$deployment_file")"
    iaas_shapes_json="$(extract_shapes_json "$compute_file")"
    ds_shapes_json="$(jq -n \
      --argjson job "$job_shapes_json" \
      --argjson notebook "$notebook_shapes_json" \
      --argjson deployment "$deployment_shapes_json" \
      '$job + $notebook + $deployment | unique | sort')"
    ds_families_json="$(printf '%s' "$ds_shapes_json" | extract_gpu_families_json)"
    iaas_families_json="$(printf '%s' "$iaas_shapes_json" | extract_gpu_families_json)"

    notes_json="$(jq -n \
      --arg genai_status "$genai_status" \
      --arg job_status "$job_status" \
      --arg notebook_status "$notebook_status" \
      --arg deployment_status "$deployment_status" \
      --arg compute_status "$compute_status" \
      --argjson models "$models_json" \
      --argjson ds_shapes "$ds_shapes_json" \
      --argjson iaas_shapes "$iaas_shapes_json" \
      '[
        if $genai_status != "success" then "GenAI model list 조회 상태: " + $genai_status else empty end,
        if (($models | length) == 0 and $genai_status == "success") then "GenAI model list는 성공했지만 표시할 모델이 없습니다." else empty end,
        if (($ds_shapes | length) == 0 and (($job_status == "success") or ($notebook_status == "success") or ($deployment_status == "success"))) then "Data Science GPU shape가 보이지 않습니다." else empty end,
        if (($iaas_shapes | length) == 0 and $compute_status == "success") then "IaaS GPU shape 조회는 성공했지만 GPU shape가 보이지 않습니다." else empty end,
        if $compute_status != "success" then "IaaS GPU shape 조회 상태: " + $compute_status else empty end,
        "표시된 모델/shape는 즉시 생성 가능 또는 capacity 보장을 뜻하지 않습니다."
      ]')"

    jq -n \
      --arg region "$region" \
      --arg genai_status "$genai_status" \
      --arg job_status "$job_status" \
      --arg notebook_status "$notebook_status" \
      --arg deployment_status "$deployment_status" \
      --arg compute_status "$compute_status" \
      --argjson models "$models_json" \
      --argjson ds_shapes "$ds_shapes_json" \
      --argjson ds_families "$ds_families_json" \
      --argjson iaas_shapes "$iaas_shapes_json" \
      --argjson iaas_families "$iaas_families_json" \
      --argjson notes "$notes_json" \
      '{
        region: $region,
        statuses: {
          genai_models: $genai_status,
          data_science_job_shapes: $job_status,
          data_science_notebook_shapes: $notebook_status,
          data_science_model_deployment_shapes: $deployment_status,
          iaas_gpu_shapes: $compute_status
        },
        genai: {
          model_count: ($models | length),
          models: $models
        },
        dac: {
          status: "official-reference-required",
          guidance: "DAC availability is model-specific. Use the guide and Oracle Models by Region / Dedicated Cluster Shapes by Region references before design decisions."
        },
        data_science: {
          gpu_families: $ds_families,
          gpu_shapes: $ds_shapes
        },
        iaas: {
          gpu_families: $iaas_families,
          gpu_shapes: $iaas_shapes
        },
        customer_notes: $notes
      }' >> "$region_items_file"
  done

  jq -n \
    --arg date "$DATE_ARG" \
    --arg generated_at "$(date -u +'%FT%TZ')" \
    --arg source "oci-cli-snapshot" \
    --slurpfile regions "$region_items_file" \
    '{
      schema_version: "1.0",
      date: $date,
      generated_at_utc: $generated_at,
      source: $source,
      public_data_policy: {
        includes: ["region", "model display name", "model vendor", "model capabilities", "lifecycle state", "GPU family", "shape name", "normalized query status"],
        excludes: ["internal identifiers", "account scope identifiers", "raw command outputs", "local paths", "raw error details"]
      },
      interpretation_notes: [
        "CLI에서 보이는 모델 또는 shape는 즉시 생성 가능이나 capacity 보장을 뜻하지 않습니다.",
        "Service limit, quota, capacity, availability domain별 가용성은 별도로 확인해야 합니다.",
        "Private endpoint는 미지원 리전에 모델이나 GPU capacity를 생성하지 않습니다."
      ],
      regions: $regions
    }' > "$PUBLIC_JSON"

  cp "$PUBLIC_JSON" "$LATEST_JSON"
  rm -f "$region_items_file"
}

validate_public_catalog() {
  local file="$1"
  local forbidden_pattern='ocid1\.|/home/|/Users/|stdout|stderr|request[ _-]?id|namespace|tenancy|compartment|OCI_CLI_PROFILE|profile'

  if grep -Eiq "$forbidden_pattern" "$file"; then
    printf 'Public catalog contains a forbidden internal marker: %s\n' "$file" >&2
    return 1
  fi
}

prune_old_public_catalogs() {
  if [[ "$RETENTION_COUNT" == "0" ]]; then
    return
  fi

  find "$PUBLIC_DATA_DIR" -maxdepth 1 -type f -name 'catalog-*.json' -printf '%T@ %p\n' |
    sort -rn |
    awk -v keep="$RETENTION_COUNT" 'NR > keep { print $2 }' |
    while IFS= read -r old_file; do
      rm -f "$old_file"
    done
}

write_customer_matrix() {
  {
    echo "# OCI AI Region Catalog Customer Matrix"
    echo
    echo "작성일: ${DATE_ARG}"
    echo
    echo "이 표는 공개 가능한 스냅샷 요약입니다. OCID, compartment, namespace, raw 오류, 로컬 경로는 제외했습니다."
    echo
    echo "| Region | GenAI models | Data Science GPU families | IaaS GPU families | Query status |"
    echo "|---|---:|---|---|---|"
    jq -r '
      .regions[]
      | [
          .region,
          (.genai.model_count | tostring),
          (if (.data_science.gpu_families | length) > 0 then (.data_science.gpu_families | join(", ")) else "없음" end),
          (if (.iaas.gpu_families | length) > 0 then (.iaas.gpu_families | join(", ")) else "없음" end),
          ([.statuses[]] | unique | join(", "))
        ]
      | @tsv
    ' "$PUBLIC_JSON" | while IFS=$'\t' read -r region models ds iaas status; do
      echo "| \`${region}\` | ${models} | ${ds} | ${iaas} | ${status} |"
    done
  } > "$CUSTOMER_MATRIX"
}

write_summary() {
  {
    echo "# OCI AI Catalog Snapshot Summary"
    echo
    echo "작성일: ${DATE_ARG}"
    echo
    echo "## Public outputs"
    echo
    echo "- \`docs/data/catalog-${DATE_ARG}.json\`"
    echo "- \`docs/data/latest-catalog.json\`"
    echo
    echo "## Internal raw directory"
    echo
    echo "- \`${OUT_DIR#$ROOT_DIR/}\`"
    echo
    echo "## Query regions"
    echo
    for region in "${REGIONS[@]}"; do
      echo "- \`${region}\`"
    done
    echo
    echo "## Public-data rule"
    echo
    echo "공개 JSON에는 OCID, namespace, OCI profile, raw stdout/stderr path, request id, raw 오류 전문을 넣지 않습니다."
  } > "$SUMMARY_FILE"
}

if ! command -v jq >/dev/null 2>&1; then
  printf 'jq not found. Cannot collect AI catalog.\n' >&2
  exit 1
fi

if ! [[ "$PARALLELISM" =~ ^[0-9]+$ ]] || (( PARALLELISM < 1 )); then
  printf 'OCI_CATALOG_PARALLELISM must be a positive integer. Got: %s\n' "$PARALLELISM" >&2
  exit 1
fi

if ! [[ "$RETENTION_COUNT" =~ ^[0-9]+$ ]]; then
  printf 'OCI_CATALOG_RETENTION_COUNT must be a non-negative integer. Got: %s\n' "$RETENTION_COUNT" >&2
  exit 1
fi

if ! command -v oci >/dev/null 2>&1; then
  jq -n \
    --arg date "$DATE_ARG" \
    --arg generated_at "$(date -u +'%FT%TZ')" \
    '{
      schema_version: "1.0",
      date: $date,
      generated_at_utc: $generated_at,
      source: "oci-cli-snapshot",
      public_data_policy: {
        includes: ["normalized query status"],
        excludes: ["internal identifiers", "account scope identifiers", "raw command outputs", "local paths", "raw error details"]
      },
      interpretation_notes: ["OCI CLI를 찾지 못해 스냅샷을 수집하지 못했습니다."],
      regions: []
    }' > "$PUBLIC_JSON"
  cp "$PUBLIC_JSON" "$LATEST_JSON"
  printf 'OCI CLI not found. Wrote empty public catalog: %s\n' "$PUBLIC_JSON"
  exit 0
fi

if [[ "$USE_EXISTING_RAW" != "1" ]]; then
  run_probe "region-subscription-list" "Subscribed READY regions" \
    oci iam region-subscription list --all --output json
fi

mapfile -t REGIONS < <(discover_regions)

if [[ ${#REGIONS[@]} -eq 0 ]]; then
  printf 'No READY regions discovered. Writing empty catalog.\n' >&2
  REGIONS=()
fi

if [[ "$USE_EXISTING_RAW" == "1" ]]; then
  printf 'Using existing raw catalog files from: %s\n' "$OUT_DIR"
elif [[ -n "$COMPARTMENT_ID" ]]; then
  for region in "${REGIONS[@]}"; do
    schedule_probe "genai-models-${region}" "Generative AI models (${region})" \
      oci --region "$region" generative-ai model-collection list-models \
      --all -c "$COMPARTMENT_ID" --output json

    schedule_probe "ds-job-shapes-${region}" "Data Science job shapes (${region})" \
      oci --region "$region" data-science job-shape list \
      --all -c "$COMPARTMENT_ID" --output json

    schedule_probe "ds-notebook-shapes-${region}" "Data Science notebook shapes (${region})" \
      oci --region "$region" data-science notebook-session-shape list \
      --all -c "$COMPARTMENT_ID" --output json

    schedule_probe "ds-model-deployment-shapes-${region}" "Data Science model deployment shapes (${region})" \
      oci --region "$region" data-science model-deployment-shape list \
      --all -c "$COMPARTMENT_ID" --output json

    schedule_probe "compute-gpu-shapes-${region}" "IaaS GPU shapes (${region})" \
      oci --region "$region" compute shape list --all -c "$COMPARTMENT_ID" \
      --query "data[?contains(shape, 'GPU')].{shape:shape,gpuDescription:\"gpu-description\",processorDescription:\"processor-description\"}" \
      --output json
  done
  wait_for_all_probes
else
  printf 'Compartment OCID was not found. Region subscription only was collected.\n' >&2
fi

write_public_catalog
validate_public_catalog "$PUBLIC_JSON"
validate_public_catalog "$LATEST_JSON"
prune_old_public_catalogs
write_customer_matrix
write_summary

printf 'Wrote public AI catalog: %s\n' "$PUBLIC_JSON"
printf 'Updated latest public AI catalog: %s\n' "$LATEST_JSON"
printf 'Wrote customer matrix: %s\n' "$CUSTOMER_MATRIX"
printf 'Wrote AI catalog summary: %s\n' "$SUMMARY_FILE"
