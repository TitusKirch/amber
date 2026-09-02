#!/usr/bin/env bash
#
# amber-sync.sh — Spike: läuft über alle bare Mirrors unter <root> und holt alle refs neu.
#
# Findet jedes <root>/.../<repo>.git (bare, --mirror) und macht `git remote update`.
# Bei einem --mirror-Clone refresht das alle refs (+refs/*:refs/*). Bewusst OHNE --prune:
# upstream-gelöschte Branches/Tags bleiben lokal erhalten (Retention "behalten, nie löschen").
#
# Nur `git`. Kein gh.
#
# Usage:
#   ./amber-sync.sh [backup-root]
#
# Default: backup-root=$AMBER_ROOT oder ./backup

set -uo pipefail

ROOT="${1:-${AMBER_ROOT:-./backup}}"

if [[ ! -d "$ROOT" ]]; then
  echo "error: backup root not found: $ROOT" >&2
  exit 1
fi

n_ok=0 n_fail=0
declare -a failed=()

# bare mirrors are the *.git directories that actually contain a git repo
while IFS= read -r -d '' dir; do
  [[ -f "$dir/HEAD" && -d "$dir/objects" ]] || continue
  rel="${dir#"$ROOT"/}"
  echo "⟳ $rel"
  if git -C "$dir" remote update; then
    ((n_ok++))
  else
    echo "✗ update failed: $rel" >&2
    ((n_fail++)); failed+=("$rel")
  fi
done < <(find "$ROOT" -type d -name '*.git' -print0)

echo
echo "done: $n_ok updated, $n_fail failed  (root: $ROOT)"
if ((n_fail > 0)); then
  printf '  failed: %s\n' "${failed[@]}" >&2
  exit 1
fi
