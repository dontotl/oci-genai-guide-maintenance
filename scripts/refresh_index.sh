#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
GUIDE_DIR="$ROOT_DIR/docs/guides"
INDEX_FILE="$ROOT_DIR/docs/INDEX.md"
LATEST_FILE="$ROOT_DIR/docs/LATEST.md"
HISTORY_FILE="$ROOT_DIR/docs/HISTORY.md"

mkdir -p "$GUIDE_DIR"

mapfile -t guides < <(find "$GUIDE_DIR" -maxdepth 1 -type f -name 'OCI_GenAI_Regional_Model_Guide_v2_*.md' | sort -r)

if [[ ${#guides[@]} -eq 0 ]]; then
  cat > "$INDEX_FILE" <<'EOF'
# OCI GenAI Regional Guide Index

가이드가 아직 발행되지 않았습니다.
EOF

  cat > "$LATEST_FILE" <<'EOF'
# OCI GenAI Regional Guide Latest

최신 가이드가 아직 발행되지 않았습니다.
EOF

  cat > "$HISTORY_FILE" <<'EOF'
# OCI GenAI Regional Guide History

이력이 아직 없습니다.
EOF
  exit 0
fi

latest="${guides[0]}"
cp "$latest" "$LATEST_FILE"

{
  echo "# OCI GenAI Regional Guide Index"
  echo
  echo "최신 가이드: \`$(basename "$latest")\`"
  echo
  echo "## Guides"
  echo
  for guide in "${guides[@]}"; do
    base="$(basename "$guide")"
    echo "- [${base}](guides/${base})"
  done
} > "$INDEX_FILE"

{
  echo "# OCI GenAI Regional Guide History"
  echo
  echo "최신순 목록입니다."
  echo
  for guide in "${guides[@]}"; do
    base="$(basename "$guide")"
    date_part="${base#OCI_GenAI_Regional_Model_Guide_v2_}"
    date_part="${date_part%.md}"
    echo "- ${date_part}: [${base}](guides/${base})"
  done
} > "$HISTORY_FILE"

printf 'Updated latest: %s\n' "$LATEST_FILE"
printf 'Updated index: %s\n' "$INDEX_FILE"
printf 'Updated history: %s\n' "$HISTORY_FILE"

