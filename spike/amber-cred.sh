#!/usr/bin/env bash
#
# amber-cred.sh — git credential helper: wählt einen read-only Token am Repo-Owner.
#
# Löst "git zieht pro Host nur EINE Credential": bei mehreren github.com-PATs
# (einer pro Owner/Org) liefert dieser Helper anhand des Repo-Owners den
# passenden Token zurück. Nötig, sobald die Backup-Box mehrere Orgs spiegelt.
#
# Einrichten (einmalig, auf der Box):
#   git config --global credential.useHttpPath true
#   git config --global credential.helper /root/amber-cred.sh
#
# Tokens kommen aus $AMBER_TOKENS (Default ~/.amber-tokens), chmod 600, Format:
#   # owner=token   ('#'-Kommentare und Leerzeilen erlaubt)
#   TitusKirch=github_pat_xxx
#   kirchDev=github_pat_yyy
#
# Es wird nur die `get`-Operation behandelt; store/erase sind No-Ops.
# Im Skript stehen KEINE Secrets — es ist gefahrlos committebar.

set -uo pipefail

# git ruft Helper mit get|store|erase auf; nur get interessiert uns
[[ "${1:-}" == "get" ]] || exit 0

TOKENS_FILE="${AMBER_TOKENS:-$HOME/.amber-tokens}"
[[ -f "$TOKENS_FILE" ]] || exit 0

# git-Anfrage lesen (key=value-Zeilen, terminiert durch Leerzeile)
host="" path=""
while IFS='=' read -r key value; do
  [[ -z "$key" ]] && break
  case "$key" in
    host) host="$value" ;;
    path) path="$value" ;;
  esac
done

# nur github.com bedienen; sonst aussteigen, damit git andere Wege probiert
[[ "$host" == "github.com" ]] || exit 0

owner="${path%%/*}"
[[ -n "$owner" ]] || exit 0

# Token für diesen Owner suchen (Owner case-insensitive)
token=""
while IFS='=' read -r o t; do
  o="${o%%#*}"                 # Kommentar weg
  o="${o//[[:space:]]/}"       # Whitespace weg
  [[ -z "$o" ]] && continue
  if [[ "${o,,}" == "${owner,,}" ]]; then
    t="${t#"${t%%[![:space:]]*}"}"   # ltrim (auch Leerzeichen um '=')
    t="${t%"${t##*[![:space:]]}"}"   # rtrim (auch CRLF)
    token="$t"
  fi
done <"$TOKENS_FILE"

# kein Token für diesen Owner → nichts ausgeben, git versucht es anders
[[ -n "$token" ]] || exit 0

printf 'username=x-access-token\n'
printf 'password=%s\n' "$token"
