#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TARGET="${1:-}"
GUIDE_DIR="$ROOT_DIR/docs/guides"

if [[ -z "$TARGET" ]]; then
  echo "usage: $0 <guide-file>"
  exit 1
fi

if [[ ! -f "$TARGET" ]]; then
  echo "guide file not found: $TARGET"
  exit 1
fi

mkdir -p "$GUIDE_DIR"

base_name="$(basename "$TARGET")"
final_target="$GUIDE_DIR/$base_name"
cp "$TARGET" "$final_target"

"$ROOT_DIR/scripts/refresh_index.sh"

printf 'Published guide: %s\n' "$final_target"
