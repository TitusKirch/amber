<div align="center">

# 🔶 amber

**Back up Git repositories the way they actually live — not just the history, but the issues, PRs, releases and labels that only exist on the forge**

[![Tests](https://img.shields.io/github/actions/workflow/status/TitusKirch/amber/ci.yml?branch=main&style=flat-square&label=tests)](https://github.com/TitusKirch/amber/actions/workflows/ci.yml)
[![License: MIT](https://img.shields.io/github/license/TitusKirch/amber.svg?style=flat-square&color=10b981)](LICENSE)

</div>

---

```bash
amber backup --token $GITHUB_TOKEN --out ./backups
```

That's it. Every repository the token can see — bare git mirror plus a diffable JSON export of its issues, pull requests, releases, labels and milestones — preserved on your own disk.

> [!IMPORTANT]
> amber is early WIP. The MVP scope below is the current target; expect the CLI surface to change before the first tagged release.

## ✨ Features

- **💾 Full git mirror** — every repo is captured with `git clone --mirror`, so all branches, tags and refs come along, not just the default branch.
- **🗂️ Forge metadata, not just code** — issues, pull requests (with comments), labels, milestones and releases are exported as JSON. The stuff that vanishes when an account is suspended or an org is deleted.
- **🔁 Incremental re-runs** — second and later runs use `updated_at` cursors to fetch only what changed.
- **📋 Verifiable manifest** — a top-level index records what was backed up, when, and integrity hashes for each artifact.
- **🤖 GitHub REST + GraphQL** — bulk issue/PR/discussion pulls via GraphQL through octokit; just point it at a PAT and verify the scopes.
- **🧩 Forge-agnostic layout** — filesystem-first storage kept diffable so a future GitLab/Gitea backend can reuse the same on-disk shape.

## 📦 Stack

- **Node 24 + pnpm 11** — pinned via `.nvmrc`, `engines` and `packageManager`.
- **GitHub REST + GraphQL** via [octokit](https://github.com/octokit) — GraphQL for bulk issues/PRs/discussions.
- **Filesystem-first storage** — each repo becomes a directory holding the bare git mirror plus JSON metadata exports.
- **oxc toolchain** — `oxlint` + `oxfmt`, with husky + commitlint enforcing Conventional Commits.

## 🚀 Setup

Requirements: Node **24+**, **pnpm 11**, and `git`.

```bash
git clone https://github.com/TitusKirch/amber.git
cd amber
pnpm install
```

Provide a GitHub Personal Access Token with read access to the repositories you want to preserve, then run a backup into a target directory:

```bash
amber backup --token $GITHUB_TOKEN --out ./backups
```

## 🗂️ Backup layout

Each backup root holds one directory per repository plus a top-level manifest:

```text
backups/
├── manifest.json              # what was backed up, when, integrity hashes
└── <owner>/
    └── <repo>/
        ├── git/               # bare `--mirror` clone (all refs)
        └── metadata/
            ├── issues.json
            ├── pull-requests.json
            ├── labels.json
            ├── milestones.json
            └── releases.json
```

The layout is forge-agnostic on purpose — diffable JSON and a bare mirror, nothing tied to GitHub's wire format.

## 🗺️ Roadmap

The MVP focuses on a reliable read-only backup pipeline:

1. **Auth** — read a PAT from env / config and verify scopes.
2. **Discover** — list every repo a user/org token can see.
3. **Mirror code** — `git clone --mirror` each repo.
4. **Export metadata** — issues, PRs, labels, milestones, releases (wikis + discussions as a stretch).
5. **Incremental** — change detection via `updated_at` cursors.
6. **Manifest** — top-level index with integrity hashes.

Out of scope for now (but architected to slot in later): restore/import back to a forge, encryption at rest, S3/remote storage backends, and a scheduling daemon. A hosted "set and forget" tier may follow once the self-hostable core is proven.

## 🤝 Contributing

PRs welcome. Conventional Commits required (enforced via commitlint). Husky runs the project's linters/formatters on `git commit`.

> [!TIP]
> Run `pnpm check:fix` before pushing — CI will catch what husky missed.

See [CONTRIBUTING.md](CONTRIBUTING.md) for the full workflow.

## 🛣️ Versioning

[Semantic Versioning](https://semver.org/) via [release-please](https://github.com/googleapis/release-please) — see [CHANGELOG.md](CHANGELOG.md).

## 📄 License

[MIT](LICENSE) © [Titus Kirch](https://github.com/TitusKirch/) / [IT-Dienstleistungen Titus Kirch](https://kirch.dev)
