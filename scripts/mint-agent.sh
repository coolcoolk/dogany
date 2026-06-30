#!/usr/bin/env bash
# Mint a new agent from agents/.template (DGN-066 + DGN-047).
# Self-contained per-agent model: each agent gets its own bridge + memory engine
# + hooks + routines, with all agent-specific values substituted from placeholders.
#
# Placeholders substituted (the ONLY five the template uses):
#   __PROJECT_ROOT__   absolute agent root            e.g. /Users/x/dogany/dogany-project/agents/foo
#   __AGENT_NAME__     launchd Label slug + filenames e.g. foo
#   __AGENT_LABEL__    Korean assistant speaker label e.g. 메탈
#   __USER_LABEL__     user honorific (default 형님)
#   __HOME__           OS user home (for PATH / HOME / ~/.claude)
#
# This script GENERATES files only. It does NOT load launchd plists or start the
# bridge (those are live ops that require explicit approval). It prints next steps.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"   # dogany-project
TEMPLATE="$ROOT/agents/.template"

usage() {
  cat <<USAGE
mint-agent.sh -- create a new agent from the template

  Usage: mint-agent.sh <agent-name> [options]

  Options:
    --root <path>     project root for the new agent (default: ROOT/agents/<name>)
    --label <text>    Korean assistant speaker label (default: <agent-name>)
    --user  <text>    user honorific label             (default: 형님)
    --token <token>   Telegram bot token to write into .env (default: placeholder)
    --no-venv         skip building the bridge venv (faster dry-run)
    --force           allow minting into an existing non-empty dir (overwrite)
    -h, --help        this help

  Example:
    mint-agent.sh nova --label 노바 --token 123456:ABC...
USAGE
}

[ $# -ge 1 ] || { usage; exit 1; }
case "$1" in -h|--help) usage; exit 0 ;; esac

AGENT_NAME="$1"; shift
PROJECT_ROOT=""
AGENT_LABEL=""
USER_LABEL="형님"
BOT_TOKEN="your_bot_token_here"
BUILD_VENV=1
FORCE=0

while [ $# -gt 0 ]; do
  case "$1" in
    --root)  PROJECT_ROOT="$2"; shift 2 ;;
    --label) AGENT_LABEL="$2"; shift 2 ;;
    --user)  USER_LABEL="$2"; shift 2 ;;
    --token) BOT_TOKEN="$2"; shift 2 ;;
    --no-venv) BUILD_VENV=0; shift ;;
    --force) FORCE=1; shift ;;
    -h|--help) usage; exit 0 ;;
    *) echo "unknown option: $1" >&2; usage; exit 1 ;;
  esac
done

[ -n "$PROJECT_ROOT" ] || PROJECT_ROOT="$ROOT/agents/$AGENT_NAME"
[ -n "$AGENT_LABEL" ]  || AGENT_LABEL="$AGENT_NAME"
HOME_DIR="$HOME"

[ -d "$TEMPLATE" ] || { echo "ERROR: template not found: $TEMPLATE" >&2; exit 1; }
if [ -e "$PROJECT_ROOT" ] && [ "$FORCE" != "1" ]; then
  echo "ERROR: target already exists: $PROJECT_ROOT (use --force to overwrite)" >&2; exit 1
fi

echo "[mint] agent      = $AGENT_NAME"
echo "[mint] root       = $PROJECT_ROOT"
echo "[mint] label      = $AGENT_LABEL   user = $USER_LABEL"
echo "[mint] home       = $HOME_DIR"
echo "[mint] build venv = $BUILD_VENV"

# 1) copy template -> target, excluding runtime/build cruft
mkdir -p "$PROJECT_ROOT"
rsync -a \
  --exclude 'bridge/venv' \
  --exclude '__pycache__' \
  --exclude '*.pyc' \
  --exclude '*.bak.*' \
  --exclude '.DS_Store' \
  "$TEMPLATE/" "$PROJECT_ROOT/"

# 2) substitute placeholders across text files (sed; '#' delimiter since values hold '/')
#    Order is irrelevant: the five tokens are distinct and substituted values never
#    contain another token.
substitute() {
  local f="$1"
  LC_ALL=C sed -i '' \
    -e "s#__PROJECT_ROOT__#${PROJECT_ROOT}#g" \
    -e "s#__AGENT_NAME__#${AGENT_NAME}#g" \
    -e "s#__AGENT_LABEL__#${AGENT_LABEL}#g" \
    -e "s#__USER_LABEL__#${USER_LABEL}#g" \
    -e "s#__HOME__#${HOME_DIR}#g" \
    "$f"
}

# iterate text files only (skip binaries / venv / git)
while IFS= read -r -d '' f; do
  substitute "$f"
done < <(find "$PROJECT_ROOT" -type f \
            \( -name '*.py' -o -name '*.sh' -o -name '*.json' -o -name '*.plist' \
               -o -name '*.md' -o -name '*.example' -o -name '*.txt' -o -name '*.conf' \) \
            -not -path '*/bridge/venv/*' -not -path '*/.git/*' -print0)

# 3) rename agent-specific plists (Label already substituted; filenames stay generic
#    'telegram-agent' -> agent name for clarity)
for p in "$PROJECT_ROOT"/bridge/*.plist "$PROJECT_ROOT"/routines/*.plist; do
  [ -e "$p" ] || continue
  np="${p//telegram-agent/$AGENT_NAME}"
  [ "$np" != "$p" ] && mv "$p" "$np"
done

# 4) create project .env from example (token in, placeholder otherwise)
ENV_SRC="$PROJECT_ROOT/.telegram_bot/.env.example"
ENV_DST="$PROJECT_ROOT/.telegram_bot/.env"
if [ -f "$ENV_SRC" ] && [ ! -f "$ENV_DST" ]; then
  sed "s#^TELEGRAM_BOT_TOKEN=.*#TELEGRAM_BOT_TOKEN=${BOT_TOKEN}#" "$ENV_SRC" > "$ENV_DST"
  chmod 600 "$ENV_DST"
  echo "[mint] wrote $ENV_DST"
fi
mkdir -p "$PROJECT_ROOT/.telegram_bot/logs"

# 5) build bridge venv
if [ "$BUILD_VENV" = "1" ]; then
  echo "[mint] building bridge venv ..."
  python3 -m venv "$PROJECT_ROOT/bridge/venv"
  "$PROJECT_ROOT/bridge/venv/bin/pip" install -q --upgrade pip
  "$PROJECT_ROOT/bridge/venv/bin/pip" install -q -r "$PROJECT_ROOT/bridge/requirements.txt"
  echo "[mint] venv ready"
fi

# 6) sanity: no placeholder survivors in code files
LEFT="$(grep -rlE '__(PROJECT_ROOT|AGENT_NAME|AGENT_LABEL|USER_LABEL|HOME)__' \
          --include='*.py' --include='*.sh' --include='*.json' --include='*.plist' \
          "$PROJECT_ROOT" 2>/dev/null || true)"
if [ -n "$LEFT" ]; then
  echo "[mint][WARN] placeholder survivors in:" >&2; echo "$LEFT" >&2
fi

cat <<DONE

[mint] DONE -> $PROJECT_ROOT

Next steps (manual / require approval):
  1. Set the bot token:  edit $ENV_DST  (TELEGRAM_BOT_TOKEN, ALLOWED_USER_IDS)
  2. Fill identity:      AGENT.md is still the onboarding skeleton; first SessionStart
                         runs onboarding-check.py to set name/emoji/tone.
  3. Load launchd:       cp $PROJECT_ROOT/bridge/*.plist  $PROJECT_ROOT/routines/*.plist \\
                            ~/Library/LaunchAgents/  then launchctl bootstrap.
                         (bridge/launchd is a live op -- get approval first.)
DONE
