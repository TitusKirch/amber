#!/usr/bin/env bash
#
# amber-clone.sh — Spike: bare-mirror jede Remote aus einer Liste ins forgemap-Layout.
#
# Layout (von ../forgemap/ übernommen):
#   <root>/<forgeDir>/<owner>/<repo>.git      (bare git --mirror)
#   forgeDir = reverse-domain, camelCase  →  github.com → comGithub
#
# Nur `git`. Kein gh, keine Metadaten — das ist bewusst ein Wegwerf-PoC.
#
# Usage:
#   ./amber-clone.sh [sources-file] [backup-root]
#
# Defaults: sources-file=./sources.txt, backup-root=$AMBER_ROOT oder ./backup
#
# sources.txt: eine Remote pro Zeile. Akzeptiert:
#   git@github.com:owner/repo.git
#   https://github.com/owner/repo(.git)
#   ssh://git@host/owner/repo.git
#   owner/repo                 (Kurzform → $AMBER_DEFAULT_HOST via ssh)
#   # Kommentare und Leerzeilen werden ignoriert.

set -uo pipefail

SOURCES="${1:-./sources.txt}"
ROOT="${2:-${AMBER_ROOT:-./backup}}"
DEFAULT_HOST="${AMBER_DEFAULT_HOST:-github.com}"

if [[ ! -f "$SOURCES" ]]; then
  echo "error: sources file not found: $SOURCES" >&2
  exit 1
fi

# github.com → comGithub, gitlab.example.com → comExampleGitlab
forge_dir_for_host() {
  local host="$1" IFS=. parts p rev="" i
  read -ra parts <<<"$host"
  for ((i = ${#parts[@]} - 1; i >= 0; i--)); do
    p="${parts[i]}"
    # capitalise first letter of each segment
    rev+="$(printf '%s' "${p:0:1}" | tr '[:lower:]' '[:upper:]')${p:1}"
  done
  # lowercase the very first character
  printf '%s%s\n' "$(printf '%s' "${rev:0:1}" | tr '[:upper:]' '[:lower:]')" "${rev:1}"
}

# parse a remote into HOST / OWNER_PATH / URL
parse_remote() {
  local raw="$1" rest
  URL="" HOST="" OWNER_PATH=""
  case "$raw" in
    git@*:*) # scp-like ssh
      HOST="${raw#git@}"; HOST="${HOST%%:*}"
      rest="${raw#*:}"
      URL="$raw"
      ;;
    ssh://* | https://* | http://* | git://*)
      rest="${raw#*://}"
      rest="${rest#*@}" # strip optional user@
      HOST="${rest%%/*}"
      rest="${rest#*/}"
      URL="$raw"
      ;;
    */*) # shorthand owner/repo
      HOST="$DEFAULT_HOST"
      rest="$raw"
      URL="git@${DEFAULT_HOST}:${raw}.git"
      ;;
    *)
      return 1
      ;;
  esac
  rest="${rest%.git}"
  OWNER_PATH="$rest" # owner[/subgroup...]/repo, preserves gitlab subgroups
  [[ -n "$HOST" && -n "$OWNER_PATH" && "$OWNER_PATH" == */* ]]
}

n_ok=0 n_skip=0 n_fail=0
declare -a failed=()

while IFS= read -r line || [[ -n "$line" ]]; do
  line="${line%%#*}"                       # strip comments
  line="${line#"${line%%[![:space:]]*}"}"  # ltrim
  line="${line%"${line##*[![:space:]]}"}"  # rtrim
  [[ -z "$line" ]] && continue

  if ! parse_remote "$line"; then
    echo "✗ skip (unparseable): $line" >&2
    ((n_fail++)); failed+=("$line"); continue
  fi

  forge_dir="$(forge_dir_for_host "$HOST")"
  target="$ROOT/$forge_dir/$OWNER_PATH.git"

  if [[ -d "$target" ]]; then
    echo "• exists: $forge_dir/$OWNER_PATH.git  (run amber-sync.sh to update)"
    ((n_skip++)); continue
  fi

  echo "↓ clone: $URL → $forge_dir/$OWNER_PATH.git"
  mkdir -p "$(dirname "$target")"
  if git clone --mirror "$URL" "$target"; then
    ((n_ok++))
  else
    echo "✗ clone failed: $URL" >&2
    ((n_fail++)); failed+=("$line")
    rm -rf "$target" # don't leave a half-clone behind
  fi
done <"$SOURCES"

echo
echo "done: $n_ok cloned, $n_skip already present, $n_fail failed  (root: $ROOT)"
if ((n_fail > 0)); then
  printf '  failed: %s\n' "${failed[@]}" >&2
  exit 1
fi
