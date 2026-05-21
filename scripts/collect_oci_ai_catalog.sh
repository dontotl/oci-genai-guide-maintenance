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
CATALOG_PROFILE="${OCI_CATALOG_PROFILE:-fast}"
case "$CATALOG_PROFILE" in
  fast)
    DEFAULT_TIMEOUT_SECONDS=20
    DEFAULT_PARALLELISM=24
    DEFAULT_ATTEMPTS=1
    DEFAULT_RETRY_DELAY_SECONDS=0
    ;;
  balanced)
    DEFAULT_TIMEOUT_SECONDS=30
    DEFAULT_PARALLELISM=16
    DEFAULT_ATTEMPTS=2
    DEFAULT_RETRY_DELAY_SECONDS=10
    ;;
  deep)
    DEFAULT_TIMEOUT_SECONDS=45
    DEFAULT_PARALLELISM=8
    DEFAULT_ATTEMPTS=3
    DEFAULT_RETRY_DELAY_SECONDS=60
    ;;
  *)
    printf 'OCI_CATALOG_PROFILE must be one of: fast, balanced, deep. Got: %s\n' "$CATALOG_PROFILE" >&2
    exit 1
    ;;
esac
TIMEOUT_SECONDS="${OCI_CATALOG_TIMEOUT_SECONDS:-$DEFAULT_TIMEOUT_SECONDS}"
PARALLELISM="${OCI_CATALOG_PARALLELISM:-$DEFAULT_PARALLELISM}"
RETENTION_COUNT="${OCI_CATALOG_RETENTION_COUNT:-12}"
PROFILE="${OCI_CLI_PROFILE:-DEFAULT}"
CONFIG_FILE="${OCI_CLI_CONFIG_FILE:-$HOME/.oci/config}"
REGION_ALLOWLIST="${OCI_CATALOG_REGIONS:-}"
USE_EXISTING_RAW="${OCI_CATALOG_USE_EXISTING_RAW:-0}"
ATTEMPTS="${OCI_CATALOG_ATTEMPTS:-$DEFAULT_ATTEMPTS}"
RETRY_DELAY_SECONDS="${OCI_CATALOG_RETRY_DELAY_SECONDS:-$DEFAULT_RETRY_DELAY_SECONDS}"
RETRY_ONLY_INCOMPLETE="${OCI_CATALOG_RETRY_ONLY_INCOMPLETE:-1}"
RETRY_EMPTY_RESULTS="${OCI_CATALOG_RETRY_EMPTY_RESULTS:-1}"
PROBE_DIR="$OUT_DIR"

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

  local stdout_file="$PROBE_DIR/${name}.json"
  local stderr_file="$PROBE_DIR/${name}.err"
  local meta_file="$PROBE_DIR/${name}.meta"
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
  local meta="$2"
  local code
  code="$(meta_value "$meta" exit_code)"
  status_label "${code:-1}"
}

probe_file() {
  local name="$1"
  local attempt="$2"
  local suffix="$3"

  if [[ -f "$OUT_DIR/attempt-${attempt}/${name}.${suffix}" ]]; then
    printf '%s/attempt-%s/%s.%s' "$OUT_DIR" "$attempt" "$name" "$suffix"
  elif [[ "$attempt" == "1" && -f "$OUT_DIR/${name}.${suffix}" ]]; then
    printf '%s/%s.%s' "$OUT_DIR" "$name" "$suffix"
  else
    printf '%s/attempt-%s/%s.%s' "$OUT_DIR" "$attempt" "$name" "$suffix"
  fi
}

status_rank() {
  local status="$1"
  local count="${2:-0}"

  if [[ "$status" == "success" && "$count" != "0" ]]; then
    printf '1'
  elif [[ "$status" == "success" ]]; then
    printf '2'
  elif [[ "$status" == "failed" ]]; then
    printf '3'
  elif [[ "$status" == "timeout" ]]; then
    printf '4'
  else
    printf '5'
  fi
}

count_probe_items() {
  local kind="$1"
  local file="$2"
  local safe_file

  safe_file="$(safe_json_file "$file")"
  if [[ "$safe_file" == "/dev/null" ]]; then
    printf '0'
    return
  fi

  if [[ "$kind" == "models" ]]; then
    extract_models_json "$safe_file" | jq 'length'
  else
    extract_shapes_json "$safe_file" | jq 'length'
  fi
}

select_probe_json() {
  local name="$1"
  local kind="$2"
  local best_rank=9
  local best_attempt=0
  local best_status="not-collected"
  local best_count=0
  local best_file="/dev/null"
  local seen_attempts=0
  local attempt meta file status count rank

  for attempt in $(seq 1 "$ATTEMPTS"); do
    meta="$(probe_file "$name" "$attempt" "meta")"
    file="$(probe_file "$name" "$attempt" "json")"
    [[ -f "$meta" ]] || continue
    seen_attempts="$((seen_attempts + 1))"
    status="$(safe_status "$name" "$meta")"
    count="$(count_probe_items "$kind" "$file")"
    rank="$(status_rank "$status" "$count")"
    if (( rank < best_rank )); then
      best_rank="$rank"
      best_attempt="$attempt"
      best_status="$status"
      best_count="$count"
      best_file="$(safe_json_file "$file")"
    fi
  done

  jq -n \
    --arg name "$name" \
    --arg status "$best_status" \
    --argjson attempts "$seen_attempts" \
    --argjson selected_attempt "$best_attempt" \
    --argjson observed_item_count "$best_count" \
    --arg file "$best_file" \
    '{
      name: $name,
      final_status: $status,
      attempts: $attempts,
      selected_attempt: $selected_attempt,
      observed_item_count: $observed_item_count,
      file: $file
    }'
}

probe_complete_after_attempt() {
  local name="$1"
  local kind="$2"
  local attempt="$3"
  local meta file status count

  meta="$(probe_file "$name" "$attempt" "meta")"
  file="$(probe_file "$name" "$attempt" "json")"
  [[ -f "$meta" ]] || return 1

  status="$(safe_status "$name" "$meta")"
  count="$(count_probe_items "$kind" "$file")"

  if [[ "$status" == "success" ]]; then
    if [[ "$RETRY_EMPTY_RESULTS" != "1" || "$count" != "0" ]]; then
      return 0
    fi
  fi
  return 1
}

should_run_probe() {
  local name="$1"
  local kind="$2"
  local attempt="$3"
  local previous_attempt

  if (( attempt == 1 )); then
    return 0
  fi
  if [[ "$RETRY_ONLY_INCOMPLETE" != "1" ]]; then
    return 0
  fi

  for previous_attempt in $(seq 1 "$((attempt - 1))"); do
    if probe_complete_after_attempt "$name" "$kind" "$previous_attempt"; then
      return 1
    fi
  done
  return 0
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

  local fallback_catalog
  fallback_catalog="$(
    find "$PUBLIC_DATA_DIR" -maxdepth 1 -type f -name 'catalog-*.json' -printf '%T@ %p\n' |
      sort -rn |
      cut -d' ' -f2- |
      while IFS= read -r catalog_file; do
        if [[ -s "$catalog_file" ]] && jq -e '(.regions | length) > 0' "$catalog_file" >/dev/null 2>&1; then
          printf '%s\n' "$catalog_file"
          break
        fi
      done
  )"
  if [[ -n "$fallback_catalog" ]]; then
    jq -r '.regions[]?.region' "$fallback_catalog" | sort -u
    return
  fi

  {
    find "$OUT_DIR" -maxdepth 1 -type f -name 'compute-gpu-shapes-*.json' -printf '%f\n'
    find "$OUT_DIR" -maxdepth 2 -type f -path '*/attempt-*/*' -name 'compute-gpu-shapes-*.json' -printf '%f\n'
  } |
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
      | capture("(?<family>GB300|GB200|B200|MI355|MI300|H200|H100|A100|A10|L40S|V100|P100)")?
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
    local genai_probe job_probe notebook_probe deployment_probe compute_probe
    local query_attempts_json

    genai_probe="$(select_probe_json "genai-models-${region}" "models")"
    job_probe="$(select_probe_json "ds-job-shapes-${region}" "shapes")"
    notebook_probe="$(select_probe_json "ds-notebook-shapes-${region}" "shapes")"
    deployment_probe="$(select_probe_json "ds-model-deployment-shapes-${region}" "shapes")"
    compute_probe="$(select_probe_json "compute-gpu-shapes-${region}" "shapes")"

    genai_file="$(jq -r '.file' <<< "$genai_probe")"
    job_file="$(jq -r '.file' <<< "$job_probe")"
    notebook_file="$(jq -r '.file' <<< "$notebook_probe")"
    deployment_file="$(jq -r '.file' <<< "$deployment_probe")"
    compute_file="$(jq -r '.file' <<< "$compute_probe")"

    genai_status="$(jq -r '.final_status' <<< "$genai_probe")"
    job_status="$(jq -r '.final_status' <<< "$job_probe")"
    notebook_status="$(jq -r '.final_status' <<< "$notebook_probe")"
    deployment_status="$(jq -r '.final_status' <<< "$deployment_probe")"
    compute_status="$(jq -r '.final_status' <<< "$compute_probe")"

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

    query_attempts_json="$(jq -n \
      --argjson genai "$genai_probe" \
      --argjson job "$job_probe" \
      --argjson notebook "$notebook_probe" \
      --argjson deployment "$deployment_probe" \
      --argjson compute "$compute_probe" \
      '{
        genai_models: ($genai | del(.file, .name)),
        data_science_job_shapes: ($job | del(.file, .name)),
        data_science_notebook_shapes: ($notebook | del(.file, .name)),
        data_science_model_deployment_shapes: ($deployment | del(.file, .name)),
        iaas_gpu_shapes: ($compute | del(.file, .name))
      }')"

    notes_json="$(jq -n \
      --arg genai_status "$genai_status" \
      --arg job_status "$job_status" \
      --arg notebook_status "$notebook_status" \
      --arg deployment_status "$deployment_status" \
      --arg compute_status "$compute_status" \
      --argjson models "$models_json" \
      --argjson ds_shapes "$ds_shapes_json" \
      --argjson iaas_shapes "$iaas_shapes_json" \
      --argjson query_attempts "$query_attempts_json" \
      '[
        if $genai_status != "success" then "GenAI model list 조회 상태: " + $genai_status + " (" + (($query_attempts.genai_models.attempts // 0) | tostring) + "회 시도)" else empty end,
        if (($models | length) == 0 and $genai_status == "success") then "GenAI model list는 성공했지만 표시할 모델이 없습니다." else empty end,
        if (($ds_shapes | length) == 0 and (($job_status == "success") or ($notebook_status == "success") or ($deployment_status == "success"))) then "Data Science GPU shape가 보이지 않습니다." else empty end,
        if (($iaas_shapes | length) == 0 and $compute_status == "success") then "IaaS GPU shape 조회는 성공했지만 GPU shape가 보이지 않습니다." else empty end,
        if $compute_status != "success" then "IaaS GPU shape 조회 상태: " + $compute_status + " (" + (($query_attempts.iaas_gpu_shapes.attempts // 0) | tostring) + "회 시도)" else empty end,
        if ([$query_attempts[] | select((.selected_attempt // 0) > 1)] | length) > 0 then "일부 조회는 재시도 결과를 사용했습니다." else empty end,
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
      --argjson query_attempts "$query_attempts_json" \
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
        query_attempts: $query_attempts,
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
        includes: ["region", "model display name", "model vendor", "model capabilities", "lifecycle state", "GPU family", "shape name", "normalized query status", "safe query retry summary"],
        excludes: ["internal identifiers", "account scope identifiers", "raw command outputs", "local paths", "raw error details"]
      },
      interpretation_notes: [
        "CLI에서 보이는 모델 또는 shape는 즉시 생성 가능이나 capacity 보장을 뜻하지 않습니다.",
        "Service limit, quota, capacity, availability domain별 가용성은 별도로 확인해야 합니다.",
        "Private endpoint는 미지원 리전에 모델이나 GPU capacity를 생성하지 않습니다."
      ],
      regions: $regions
    }' > "$PUBLIC_JSON"

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

public_catalog_has_successful_query() {
  local file="$1"

  jq -e '
    [
      .regions[]?.statuses[]?
      | select(. == "success")
    ]
    | length > 0
  ' "$file" >/dev/null
}

update_latest_catalog() {
  if public_catalog_has_successful_query "$PUBLIC_JSON" || [[ ! -s "$LATEST_JSON" ]]; then
    cp "$PUBLIC_JSON" "$LATEST_JSON"
    printf 'Updated latest public AI catalog: %s\n' "$LATEST_JSON"
  else
    printf 'Preserved latest public AI catalog because this snapshot has no successful CLI query: %s\n' "$LATEST_JSON" >&2
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
    echo "## Query profile"
    echo
    echo "- profile: \`${CATALOG_PROFILE}\`"
    echo "- timeout seconds: \`${TIMEOUT_SECONDS}\`"
    echo "- parallelism: \`${PARALLELISM}\`"
    echo "- attempts: \`${ATTEMPTS}\`"
    echo "- retry delay seconds: \`${RETRY_DELAY_SECONDS}\`"
    echo
    echo "## Query regions"
    echo
    for region in "${REGIONS[@]}"; do
      echo "- \`${region}\`"
    done
    echo
    echo "## Public-data rule"
    echo
    echo "공개 JSON에는 OCID, namespace, OCI profile, raw stdout/stderr path, 요청 추적값, raw 오류 전문을 넣지 않습니다."
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

if ! [[ "$ATTEMPTS" =~ ^[0-9]+$ ]] || (( ATTEMPTS < 1 )); then
  printf 'OCI_CATALOG_ATTEMPTS must be a positive integer. Got: %s\n' "$ATTEMPTS" >&2
  exit 1
fi

if ! [[ "$RETRY_DELAY_SECONDS" =~ ^[0-9]+$ ]]; then
  printf 'OCI_CATALOG_RETRY_DELAY_SECONDS must be a non-negative integer. Got: %s\n' "$RETRY_DELAY_SECONDS" >&2
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
  for attempt in $(seq 1 "$ATTEMPTS"); do
    PROBE_DIR="$OUT_DIR/attempt-${attempt}"
    mkdir -p "$PROBE_DIR"

    if (( attempt > 1 )) && (( RETRY_DELAY_SECONDS > 0 )); then
      sleep "$RETRY_DELAY_SECONDS"
    fi

    for region in "${REGIONS[@]}"; do
      if should_run_probe "genai-models-${region}" "models" "$attempt"; then
        schedule_probe "genai-models-${region}" "Generative AI models (${region})" \
          oci --region "$region" generative-ai model-collection list-models \
          --all -c "$COMPARTMENT_ID" --output json
      fi

      if should_run_probe "ds-job-shapes-${region}" "shapes" "$attempt"; then
        schedule_probe "ds-job-shapes-${region}" "Data Science job shapes (${region})" \
          oci --region "$region" data-science job-shape list \
          --all -c "$COMPARTMENT_ID" --output json
      fi

      if should_run_probe "ds-notebook-shapes-${region}" "shapes" "$attempt"; then
        schedule_probe "ds-notebook-shapes-${region}" "Data Science notebook shapes (${region})" \
          oci --region "$region" data-science notebook-session-shape list \
          --all -c "$COMPARTMENT_ID" --output json
      fi

      if should_run_probe "ds-model-deployment-shapes-${region}" "shapes" "$attempt"; then
        schedule_probe "ds-model-deployment-shapes-${region}" "Data Science model deployment shapes (${region})" \
          oci --region "$region" data-science model-deployment-shape list \
          --all -c "$COMPARTMENT_ID" --output json
      fi

      if should_run_probe "compute-gpu-shapes-${region}" "shapes" "$attempt"; then
        schedule_probe "compute-gpu-shapes-${region}" "IaaS GPU shapes (${region})" \
          oci --region "$region" compute shape list --all -c "$COMPARTMENT_ID" \
          --query "data[?contains(shape, 'GPU')].{shape:shape,gpuDescription:\"gpu-description\",processorDescription:\"processor-description\"}" \
          --output json
      fi
    done
    wait_for_all_probes
  done
else
  printf 'Compartment OCID was not found. Region subscription only was collected.\n' >&2
fi

write_public_catalog
validate_public_catalog "$PUBLIC_JSON"
update_latest_catalog
validate_public_catalog "$LATEST_JSON"
prune_old_public_catalogs
write_customer_matrix
write_summary

printf 'Wrote public AI catalog: %s\n' "$PUBLIC_JSON"
printf 'Wrote customer matrix: %s\n' "$CUSTOMER_MATRIX"
printf 'Wrote AI catalog summary: %s\n' "$SUMMARY_FILE"
