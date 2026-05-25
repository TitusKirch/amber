# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this repo is

`amber` is a **Git/GitHub backup tool**. It preserves not just git history but the full forge metadata that lives only on GitHub — issues, pull requests, releases, labels, milestones, and (as a stretch) wikis and discussions. The differentiator versus code-only mirroring (`git clone --mirror`, `gickup`, ad-hoc `gh repo clone` crons) is the metadata export; rewind.com's GitHub backup is the SaaS benchmark to clear.

Positioning: OSS, self-hostable core first; an optional managed tier may follow once the engine is proven. Currently `TitusKirch/amber` while WIP; may move to its own product org later.

> [!IMPORTANT]
> The repo currently carries only the kirchDev scaffold meta layer (tooling, CI, meta docs) — the application code has not been written yet. `TEMP_AI.md` is the bootstrap brief describing the intended product, MVP scope, and the suggested first PRs; read it before adding code. Delete it once the project is bootstrapped.

## Intended architecture (from the bootstrap brief)

- **Stack**: Node 24 + pnpm 11. GitHub access via REST + GraphQL (GraphQL for bulk issues/PRs/discussions); consider `octokit`.
- **Storage**: filesystem-first. Each repo → a directory with the bare git mirror plus JSON exports of metadata. Keep it diffable and forge-agnostic so a future GitLab/Gitea backend can reuse the layout.
- **MVP pipeline**: auth (read PAT, verify scopes) → discover (list visible repos) → mirror code (`git clone --mirror`) → export metadata (issues/PRs/labels/milestones/releases as JSON) → incremental re-run (`updated_at` cursors) → manifest (top-level index with integrity hashes).
- **Out of scope for v0** (architect for, don't build): restore/import back to a forge, encryption at rest, S3/remote storage backends, scheduling daemon.

Keep PRs small; prove the metadata export early — it's the differentiator and the riskiest API surface.

## Commands

| Command           | What it does                                               |
| :---------------- | :--------------------------------------------------------- |
| `pnpm install`    | Install deps and wire husky hooks via the `prepare` script |
| `pnpm lint`       | `oxlint . --deny-warnings`                                 |
| `pnpm format`     | `oxfmt --check .` (note: `format` is the check, not fix)   |
| `pnpm check`      | Runs `lint` + `format` — the CI gate                       |
| `pnpm lint:fix`   | Auto-fix lint                                              |
| `pnpm format:fix` | Auto-fix format                                            |
| `pnpm check:fix`  | Auto-fix lint + format                                     |
| `pnpm taze`       | Interactive dependency upgrade check                       |
| `pnpm taze:w`     | Write upgrade results                                      |

There is no test suite yet. CI runs `pnpm lint` and `pnpm format` on PR. Add a test runner when application code lands.

## Tooling / conventions

- **Node 24, pnpm 11.** Pinned via `.nvmrc`, `engines`, and `packageManager`. `.npmrc` enforces `minimumReleaseAge=4320` (3-day cooldown), `trustPolicy=no-downgrade`, isolated node-linker. Don't loosen these without reason.
- **oxc, not eslint/prettier.** Linting via `oxlint`, formatting via `oxfmt`. Configs live in `.oxlintrc.json` / `.oxfmtrc.json`. `oxlint` uses `unicorn` + `oxc` plugins; rules deliberately minimal.
- **Husky hooks** (`.husky/pre-commit`, `.husky/commit-msg`) run `lint-staged` and `commitlint`. `lint-staged.config.js` excludes `README.md` (free-form prose) and `pnpm-lock.yaml`. `oxlint --fix --deny-warnings` then `oxfmt` on JS; `oxfmt` only on JSON/YAML/MD.
- **Conventional Commits enforced** via `@commitlint/config-conventional`. Don't `--no-verify` unless explicitly asked.
- **release-please** publishes releases. Files: `release-please-config.json`, `.release-please-manifest.json`, `.github/workflows/release-please.yml`. Config uses `release-type: simple`, `include-v-in-tag: true`, starting at `0.0.0`.
- **Workflows** use `actions/checkout@v6`, `actions/setup-node@v6`, `pnpm/action-setup@v6`, `github/codeql-action/{init,analyze}@v4`. Keep pinned to major versions; Dependabot bumps them monthly.
- **CodeQL** scans `actions` + `javascript-typescript` with `security-extended,security-and-quality` queries, gated by path filters.
- **Dependabot** groups all minor/patch updates per ecosystem into a single PR. Majors come as separate PRs.

## House style for READMEs and meta files

The `/write-readme` skill encodes the canonical structure. Key rules: hero block wrapped in `<div align="center">`, prescribed section emojis (✨ Features, 🚀 Setup, 🤝 Contributing, 🛣️ Versioning, 📄 License), license footer always reads `[MIT](LICENSE) © [Titus Kirch](https://github.com/TitusKirch/) / [IT-Dienstleistungen Titus Kirch](https://kirch.dev)`. Use GitHub callouts (`> [!TIP]`, `> [!IMPORTANT]`), never plain blockquotes. The README hero uses the **🔶** emoji (amber gemstone / brand colour) — never 🪲 (reads as "software bug", wrong signal for a backup tool).
