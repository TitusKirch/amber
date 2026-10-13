# amber — git-mirror spike

> [!WARNING]
> Wegwerf-Proof-of-Concept. Pure `git`, kein `gh`, keine Metadaten. Beweist ambers
> Kern-Pipeline (discover → mirror → re-sync) auf dem Dateisystem, bevor sie in den
> echten Laravel/Nuxt-Stack wandert. **Kein App-Code** — bei Bedarf später löschen.

## Skripte

| Datei | Zweck |
| :-- | :-- |
| `amber-clone.sh` | Liste von Remotes → `git clone --mirror` ins Layout `<root>/<forgeDir>/<owner>/<repo>.git`. forgeDir aus Host abgeleitet (`github.com → comGithub`). Idempotent, räumt halbe Clones auf. |
| `amber-sync.sh` | Läuft über alle bare Mirrors unter `<root>` → `git remote update` **ohne `--prune`** → upstream-gelöschte refs bleiben erhalten (Retention). |
| `amber-cred.sh` | Optionaler git-Credential-Helper: wählt bei **mehreren Owner/Org-PATs** den Token am Repo-Owner aus. Nur nötig, wenn die Box mehr als einen Owner spiegelt. |

`sources.txt`: eine Remote pro Zeile (`https://…` empfohlen, damit Token greifen). `#`-Kommentare/Leerzeilen werden ignoriert. Siehe `sources.example.txt`.

## Schnellstart (ein Owner)

```bash
chmod +x amber-clone.sh amber-sync.sh

# read-only fine-grained PAT (Contents: Read + Metadata) über HTTPS hinterlegen
git config --global credential.helper store
printf 'https://x-access-token:%s@github.com\n' "$TOKEN" > ~/.git-credentials
chmod 600 ~/.git-credentials

export AMBER_ROOT=/root/backup
./amber-clone.sh sources.txt          # einmal spiegeln
./amber-sync.sh                       # jederzeit aktualisieren (cron-tauglich)
```

cron (stündlich, Minute 17):
```cron
17 * * * * AMBER_ROOT=/root/backup /root/amber-sync.sh >> /var/log/amber-sync.log 2>&1
```

## Mehrere Owner/Orgs

Ein fine-grained PAT ist auf **genau einen Owner** beschränkt → pro Owner/Org ein eigenes Token.
Da git pro Host (`github.com`) aber nur *eine* Credential zieht, kollidieren mehrere statische
PATs im `store`-Helper. `amber-cred.sh` löst das, indem es den Token am Owner auswählt:

```bash
# Token-Map anlegen (KEINE Secrets ins git-Repo!)
cat > ~/.amber-tokens <<'EOF'
TitusKirch=github_pat_xxx
kirchDev=github_pat_yyy
EOF
chmod 600 ~/.amber-tokens

# alten Single-Token-Store ablösen, eigenen Helper aktivieren
git config --global --unset-all credential.helper
rm -f ~/.git-credentials
git config --global credential.useHttpPath true
git config --global credential.helper /root/amber-cred.sh   # absoluter Pfad
```

Danach nimmt git pro Repo automatisch den richtigen Token. `sources.txt` listet einfach alle
`https://…`-URLs über alle Owner hinweg.

> [!NOTE]
> Skaliert linear: jede neue Org = neues PAT + Zeile in `~/.amber-tokens`. Ab ~4 Orgs ist eine
> **GitHub App** (eine App, auf allen Orgs installiert, kurzlebige Installation-Tokens) der
> sauberere Weg — das gehört aber in die echte Engine, nicht in diesen Bash-Spike.

## Bewusst (noch) nicht

Metadaten-Export (der Differenzierer), Manifest/Hashes, Scheduler, Heartbeat/Dead-Man-Switch,
Coverage-Report, versionierte Snapshots, Orphan-*Markierung*, GitHub-App-Auth. Alles Engine-Sache.
