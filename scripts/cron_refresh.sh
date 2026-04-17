#!/usr/bin/env bash
set -euo pipefail

export PATH="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"
export HOME="${HOME:-/home/opc}"
umask 022

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DATE_ARG="${1:-$(date -u +%F)}"
PROMPT_FILE="$ROOT_DIR/runs/${DATE_ARG}-refresh-prompt.md"
RUN_GUIDE="$ROOT_DIR/runs/OCI_GenAI_Regional_Model_Guide_v2_${DATE_ARG}.md"
FINAL_GUIDE="$ROOT_DIR/docs/guides/OCI_GenAI_Regional_Model_Guide_v2_${DATE_ARG}.md"
LOG_FILE="$ROOT_DIR/runs/cron.log"
LAST_MSG_FILE="$ROOT_DIR/runs/${DATE_ARG}-codex-last-message.txt"
LOCK_FILE="$ROOT_DIR/runs/cron_refresh.lock"
CODEX_BIN="${CODEX_BIN:-/usr/local/bin/codex}"
CODEX_TIMEOUT_SECONDS="${CODEX_TIMEOUT_SECONDS:-5400}"

mkdir -p "$ROOT_DIR/runs" "$ROOT_DIR/docs/guides"

log() {
  printf '[%s] %s\n' "$(date -u +'%F %T UTC')" "$*" | tee -a "$LOG_FILE"
}

cd "$ROOT_DIR"

exec 9>"$LOCK_FILE"
if ! flock -n 9; then
  log "Another refresh job is already running. Exiting."
  exit 0
fi

if [[ -f "$FINAL_GUIDE" ]]; then
  log "Final guide already exists for ${DATE_ARG}: $FINAL_GUIDE"
  exit 0
fi

./scripts/new_guide.sh "$DATE_ARG"
log "Prepared draft and prompt for ${DATE_ARG}"

if [[ -x "$CODEX_BIN" ]]; then
  if "$CODEX_BIN" exec --help >/dev/null 2>&1; then
    log "Starting Codex non-interactive refresh"
    if command -v timeout >/dev/null 2>&1; then
      timeout --signal=TERM "${CODEX_TIMEOUT_SECONDS}" \
        "$CODEX_BIN" exec --full-auto -C "$ROOT_DIR" -o "$LAST_MSG_FILE" - < "$PROMPT_FILE" || true
    else
      "$CODEX_BIN" exec --full-auto -C "$ROOT_DIR" -o "$LAST_MSG_FILE" - < "$PROMPT_FILE" || true
    fi
  else
    log "codex CLI is present but non-interactive exec mode was not detected."
  fi
else
  log "codex CLI not found. Prompt file is ready: $PROMPT_FILE"
fi

if [[ -f "$RUN_GUIDE" ]] && grep -q '^# ' "$RUN_GUIDE" && ! grep -q '빈 문서입니다' "$RUN_GUIDE"; then
  log "Draft guide looks populated. Publishing."
  ./scripts/publish_guide.sh "$RUN_GUIDE"

  if git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    git add docs/ README.md OCI_GenAI_Regional_Model_Guide_Prompt.md scripts/ templates/ .gitignore || true
    if ! git diff --cached --quiet; then
      git commit -m "Refresh OCI GenAI regional guide for ${DATE_ARG}" || true
      if git remote get-url origin >/dev/null 2>&1; then
        git push || true
      else
        log "No git remote named origin. Skipping push."
      fi
    else
      log "No git changes to commit after publish."
    fi
  fi
  log "Refresh flow completed for ${DATE_ARG}"
else
  log "Guide was not published automatically. Review the prompt/output manually."
  log "Prompt: $PROMPT_FILE"
  log "Draft:  $RUN_GUIDE"
  if [[ -f "$LAST_MSG_FILE" ]]; then
    log "Last Codex message: $LAST_MSG_FILE"
  fi
  exit 1
fi
