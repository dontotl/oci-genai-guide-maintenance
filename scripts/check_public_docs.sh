#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

if ! command -v jq >/dev/null 2>&1; then
  echo "jq not found"
  exit 1
fi

json_forbidden='ocid1\.|/home/|/Users/|stdout|stderr|request[ _-]?id|namespace|tenancy|compartment|OCI_CLI_PROFILE|profile'
doc_forbidden='ocid1\.|/home/opc|/Users/|request[ _-]?id|OCI_CLI_PROFILE'

for json_file in docs/data/*.json; do
  [[ -f "$json_file" ]] || continue
  jq empty "$json_file"
  if grep -Eiq "$json_forbidden" "$json_file"; then
    echo "Forbidden internal marker found in public JSON: $json_file"
    grep -Ein "$json_forbidden" "$json_file" || true
    exit 1
  fi
done

if find docs -type f \( -name '*.md' -o -name '*.html' \) -print0 |
  xargs -0 grep -Ein "$doc_forbidden" >/tmp/oci-genai-public-docs-check.out 2>/dev/null; then
  echo "Forbidden internal marker found in public docs:"
  cat /tmp/oci-genai-public-docs-check.out
  exit 1
fi

rm -f /tmp/oci-genai-public-docs-check.out
echo "Public docs check passed."
