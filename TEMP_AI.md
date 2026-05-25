# amber — Bootstrap-Brief (aktualisiert)

> Temporäre Instruktionsdatei für den AI-Agent, der dieses Repo aufsetzt. Löschen, sobald das Projekt gebootstrappt ist.
>
> **Hinweis:** Diese Datei ersetzt den ursprünglichen Node-CLI-Brief. In einer Anforderungs-Diskussion hat sich die Produktvision bewusst verschoben — von „headless Node-CLI mit octokit + Filesystem-JSON" hin zu einem **self-hosted Dienst mit Web-Dashboard auf Laravel + Nuxt**. CLAUDE.md/README spiegeln teils noch den alten Stand und müssen beim Bootstrap nachgezogen werden.

## Was amber ist

`amber` ist ein Git/GitHub-Backup-Werkzeug. Es sichert nicht nur die Git-Historie, sondern die volle Forge-Metadaten, die nur auf der Forge leben: Issues, Pull Requests, Releases, Labels, Milestones (Wikis/Discussions als Stretch). Der Differenzierer gegenüber code-only Mirroring (`git clone --mirror`, gickup) ist der Metadaten-Export. Benchmark: rewind.com.

## Nordstern (entschieden)

> amber ist ein **selbst-gehosteter Dienst**, der Git-Repos + Forge-Metadaten **nach Zeitplan** sichert. Sein **Web-Dashboard ist primär eine Kontroll-/Monitoring-Ebene**: läuft alles, ist alles intakt, schlägt Alarm wenn nicht. Späterer Pfad: optionaler Hosted-SaaS-Tier (rewind.com-artig).

**Kernwert:** Verlässlichkeit & Überblick — vertrauenswürdige, geprüfte Backups, die man wirklich „vergessen" kann. _Nicht_ primär: Vollständigkeits-Maximalismus, Offline-Leseprogramm, Restore (alle „später").

## Entschiedene Feature-Entscheidungen

| Achse               | Entscheidung                                                                                                                  |
| :------------------ | :---------------------------------------------------------------------------------------------------------------------------- |
| Produkt-Gestalt     | Self-hosted Dashboard-Dienst (Nordstern: Hosted SaaS später)                                                                  |
| Rolle des UI        | v0 = reine Kontroll-/Monitoring-Ebene; Inhalts-Browser (Issues/PRs lesen/suchen) später; Datenmodell jetzt dafür offen halten |
| Scheduling          | eingebauter Scheduler im Dienst zuerst; externer Trigger (Cron/CI) später                                                     |
| Backup-Einheit      | mehrere Sources via Config (User/Orgs/Tokens); ein Run sichert alle                                                           |
| Retention           | upstream-verschwundene Repos behalten + als „verwaist" markieren; nie automatisch löschen                                     |
| Reliability-Signale | Run-Status & Historie · Heartbeat/Dead-Man-Switch · Integritätsprüfung · Coverage-Report (alle vier)                          |

## Reliability-Kern (Herzstück)

1. **Run-Status & Historie** — pro Source/Repo: letzter Run, Erfolg/Fehler, Dauer, Größe, Diff, Logs.
2. **Heartbeat / Dead-Man-Switch** — Alarm wenn Backups _stillschweigend aufhören_ (kein Run seit X, Token abgelaufen, Platte voll). Das eigentliche Vertrauens-Feature.
3. **Integritätsprüfung** — Manifest + Hashes, `git fsck`; Verify-Status im UI; Warnung bei Korruption.
4. **Coverage-Report** — was existiert upstream vs. was ist gesichert → Lücken sichtbar machen.

## Architektur (geschichtet)

- **Provider-Abstraktion** als Kern: `Source`/`Provider`-Interface; darunter Adapter (GitHub zuerst). Transport unter GitHub austauschbar: `git` (mirror) + API (knplabs/GraphQL). GitLab/Gitea später ohne Kernumbau.
- **Backup-Substrat = Dateisystem** (portabel, überlebt ohne laufenden Dienst): Git-Mirror-Verzeichnisse + Metadaten als JSON.
- **Betriebszustand = DB**: Sources, Runs, Schedules, Status, Coverage, Heartbeat-State.
- **Web-Dashboard** liest Betriebszustand; Inhalts-Browser später als read-only Sicht über einen ableitbaren Index.

## Tech-Stack (entschieden)

- **Backend: Laravel** — Scheduler, Queues/Horizon (Backup-Jobs, Retries), Eloquent+DB, Notifications (Alerts + Heartbeat), Sanctum-Auth (→ SaaS-Pfad). Git via `symfony/process`; GitHub-API via PHP. CLI = Artisan (`php artisan amber:backup`).
- **Frontend: Nuxt-SPA gegen Laravel-JSON-API** (Filament verworfen — zu eng für reiche Ansichten/Diffs). Entkoppelt, skaliert zu „groß & schön" + Inhalts-Browser; dasselbe Frontend bedient self-hosted UND späteren Hosted-Tier.
- **Repo-Layout:** Monorepo (Turborepo) — Backend + Frontend in einem Repo.
- **Meta-Layer:** wie `laravel-pbac` (Pest, Pint, Larastan) **plus** der vorhandene Node-Meta-Layer (oxlint/oxfmt/husky/commitlint/release-please/taze).

## Basis: gildstone (`../../kirchDev/gildstone`)

Bewertet als **sehr gute Basis**. gildstone ist genau dieser Stack, schon verdrahtet:

- Turborepo-Monorepo **Nuxt 4 (Frontend) + Laravel 13 (API)**, Octane/FrankenPHP.
- **Sanctum-SPA-Auth** inkl. 2FA, E-Mail-Verifizierung, Privileged-Verification.
- **UI fertig:** shadcn-vue/reka-ui, Tailwind v4, Dashboard-Layout (Sidebar/Breadcrumbs), `@tanstack/vue-table`, ~197 Komponenten.
- **Daten-Layer:** Pinia Colada + `useApi()` + **Wayfinder** (typsichere Laravel→TS-Routen) + Precognition.
- Identischer Meta-Layer + Pint/Larastan/Pest.
- **Bonus:** `infra/` enthält **Temporal** (durable Workflow-Engine) — potenziell ideal für langlaufende/retrybare/resumebare Backup-Jobs.

Nimmt uns Frontend + Auth + UI + Build-Workflow ab. Übrig bleibt ambers Kern-Domäne: Forge-Abstraktion + Backup-Engine + Monitoring-UI.

Caveats: SaaS-Ballast (i18n, PostHog, Turnstile/CAPTCHA, Multi-Org-PBAC), `private`, v0.0.1. Sauber in Layer getrennt (`ui` → `app-base` → `web`), aber org/member-Annahmen sind verwoben.

## Build vs. Buy (PHP/Laravel)

**Existiert & gut → nutzen:**

- GitHub-API: `knplabs/php-github-api` (REST + GraphQL, gepflegt).
- Git-Ops: `czproject/git-php` (kein natives `--mirror`, aber `execute()` für beliebige git-Befehle → `clone --mirror`, `remote update`, `git fsck`); dünn wrappen.
- Scheduling: Laravel-Scheduler nativ.
- Schedule-Monitoring (Heartbeat-Basis): `spatie/laravel-schedule-monitor` + `spatie/laravel-health`.
- Alerts: Laravel Notifications + Kanäle (Discord, Slack nativ, ntfy via Webhook).
- Ergänzend: `spatie/laravel-activitylog`, `spatie/laravel-settings`, Sanctum.

**Nichts Gutes vorhanden → Eigenbau:**

1. **Forge-Provider-Abstraktion** (Kern). Keine brauchbare unified Multi-Forge-Metadaten-Lib in PHP (`mborne/remote-git` zu „lightweight"; reiches Pendant `git-pkgs/forge` ist Go). → **Zuerst intern in amber bauen, später als eigenständiges Paket extrahieren** (à la laravel-pbac), sobald Interface stabil + zweiter Forge dazukommt.
2. **Backup-/Preservation-Engine** (Discovery → Mirror → Metadaten-Export → inkrementell → Manifest/Integrität → Retention/Orphan-Marking). `spatie/laravel-backup` ist falsche Domäne (sichert eigene App, nicht remote Forges). = ambers Kern-Domäne.
3. **Self-hosted Heartbeat-Notification** — schedule-monitor erkennt „nicht gelaufen", proaktive Benachrichtigung hängt aber an Oh Dear (externer Paid-SaaS). Für self-hosted dünne Eigenschicht nötig.
4. **Coverage-Report & Integritäts-Verify** — domänenspezifisch; klein, Teil der Engine.

## Phasing

**v0 (MVP):** Provider-Layer (GitHub) · Sources via Config · Git-Mirror (alle refs) · Metadaten-Export · Manifest+Hashes · eingebauter Scheduler · Run-Status & Historie · Heartbeat · Integritäts-Verify · Coverage-Report · inkrementell (`updated_at`) · Retention (behalten+markieren) · Kontroll-Dashboard.

**Später:** Inhalts-Browser + Suche · externer Trigger · Alert-Kanäle · GitHub App/OAuth-Onboarding · weitere Forges · Restore/Import · Encryption-at-rest · Remote/S3-Storage · Hosted-SaaS-Tier (Multi-User, Billing).

## Offene Entscheidungen

- **gildstone-Adoption:** Forken & ausdünnen vs. gemeinsame Layer extrahieren vs. nur als Referenz. _(offen — abhängig davon, ob gildstone ein gemeinsames Fundament oder ein konkretes Produkt sein soll)_
- **Temporal:** erst Laravel Queues/Horizon, Temporal optional — vs. Temporal von Anfang an. _(offen — erst klären wofür/ob Temporal in gildstone aktiv ist)_
- **Exaktes Metadaten-Set für v0** — Default-Vorschlag: Issues+Kommentare, PRs+Reviews, Labels, Milestones, Releases, Repo-Settings.
- **Versionierung der Metadaten:** Git-versionierte Snapshots (Historie gratis) vs. nur letzter Stand. _(offen)_
- **Onboarding/Auth:** PAT vs. GitHub App vs. beides. _(offen)_
- **Heartbeat-Notification:** eigene lokale Schicht vs. Oh Dear. _(offen)_

## README-Icon

Hero-Emoji **🔶** (Bernstein/Brand-Farbe). Nie 🪲 (liest sich als „Software-Bug", falsches Signal für ein Backup-Tool).
