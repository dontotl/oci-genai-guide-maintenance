#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DATE_ARG="${1:-$(date -u +%F)}"
PROMPT_FILE="$ROOT_DIR/runs/${DATE_ARG}-refresh-prompt.md"
RUN_GUIDE="$ROOT_DIR/runs/OCI_GenAI_Regional_Model_Guide_v2_${DATE_ARG}.md"

cd "$ROOT_DIR"

./scripts/new_guide.sh "$DATE_ARG"

if command -v codex >/dev/null 2>&1; then
  if codex exec --help >/dev/null 2>&1; then
    codex exec - < "$PROMPT_FILE" || true
  else
    printf 'codex CLI is present but non-interactive exec mode was not detected.\n'
  fi
else
  printf 'codex CLI not found. Prompt file is ready: %s\n' "$PROMPT_FILE"
fi

if [[ -f "$RUN_GUIDE" ]] && grep -q '^# ' "$RUN_GUIDE" && ! grep -q '빈 문서입니다' "$RUN_GUIDE"; then
  ./scripts/publish_guide.sh "$RUN_GUIDE"

  if git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    git add docs/ README.md OCI_GenAI_Regional_Model_Guide_Prompt.md scripts/ .github/ .gitignore || true
    if ! git diff --cached --quiet; then
      git commit -m "Refresh OCI GenAI regional guide for ${DATE_ARG}" || true
      git push || true
    fi
  fi
else
  printf 'Guide was not published automatically. Review the prompt/output manually.\n'
  printf 'Prompt: %s\n' "$PROMPT_FILE"
  printf 'Draft:  %s\n' "$RUN_GUIDE"
fi
