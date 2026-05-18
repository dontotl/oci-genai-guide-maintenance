#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
GUIDE_DIR="$ROOT_DIR/docs/guides"
INDEX_FILE="$ROOT_DIR/docs/INDEX.md"
LATEST_FILE="$ROOT_DIR/docs/LATEST.md"
HISTORY_FILE="$ROOT_DIR/docs/HISTORY.md"
CHANGELOG_FILE="$ROOT_DIR/docs/CHANGELOG.md"

mkdir -p "$GUIDE_DIR"

mapfile -t guides < <(
  find "$GUIDE_DIR" -maxdepth 1 -type f \( -name 'OCI_GenAI_Regional_Model_Guide_v3_*.md' -o -name 'OCI_GenAI_Regional_Model_Guide_v2_*.md' \) |
    while IFS= read -r guide; do
      base="$(basename "$guide")"
      version="$(printf '%s\n' "$base" | sed -n 's/^OCI_GenAI_Regional_Model_Guide_v\([0-9][0-9]*\)_.*/\1/p')"
      date_part="$(printf '%s\n' "$base" | sed -n 's/^OCI_GenAI_Regional_Model_Guide_v[0-9][0-9]*_\(.*\)\.md$/\1/p')"
      printf '%s\t%03d\t%s\n' "$date_part" "$version" "$guide"
    done |
    sort -t $'\t' -k1,1r -k2,2r |
    cut -f3-
)

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

  cat > "$CHANGELOG_FILE" <<'EOF'
# OCI GenAI Regional Guide Changelog

변경 이력이 아직 없습니다.
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
  echo "- [CHANGELOG.md](CHANGELOG.md)"
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
    version_part="$(printf '%s\n' "$base" | sed -n 's/^OCI_GenAI_Regional_Model_Guide_\(v[0-9][0-9]*\)_.*/\1/p')"
    date_part="$(printf '%s\n' "$base" | sed -n 's/^OCI_GenAI_Regional_Model_Guide_v[0-9][0-9]*_\(.*\)\.md$/\1/p')"
    echo "- ${date_part} (${version_part}): [${base}](guides/${base})"
  done
} > "$HISTORY_FILE"

{
  echo "# OCI GenAI Regional Guide Changelog"
  echo
  echo "가이드별 \`이번 업데이트 변화 요약\` 섹션을 최신순으로 모은 자동 생성 파일입니다."
  echo
  for guide in "${guides[@]}"; do
    base="$(basename "$guide")"
    version_part="$(printf '%s\n' "$base" | sed -n 's/^OCI_GenAI_Regional_Model_Guide_\(v[0-9][0-9]*\)_.*/\1/p')"
    date_part="$(printf '%s\n' "$base" | sed -n 's/^OCI_GenAI_Regional_Model_Guide_v[0-9][0-9]*_\(.*\)\.md$/\1/p')"
    echo "## ${date_part} (${version_part})"
    echo
    echo "[${base}](guides/${base})"
    echo

    summary="$(
      awk '
        /^---$/ && in_summary { exit }
        in_summary { print }
        /^## .*이번 업데이트 변화 요약[[:space:]]*$/ { in_summary = 1 }
      ' "$guide" | sed '/^[[:space:]]*$/d'
    )"

    if [[ -n "$summary" ]]; then
      printf '%s\n' "$summary"
    else
      echo "- 변화 요약 섹션을 찾지 못했습니다."
    fi
    echo
  done
} > "$CHANGELOG_FILE"

printf 'Updated latest: %s\n' "$LATEST_FILE"
printf 'Updated index: %s\n' "$INDEX_FILE"
printf 'Updated history: %s\n' "$HISTORY_FILE"
printf 'Updated changelog: %s\n' "$CHANGELOG_FILE"
