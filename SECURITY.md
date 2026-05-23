# Security Policy

## Scope

`amber` is a **Git/GitHub backup tool**. It reads from forges using a Personal Access Token and writes git mirrors and metadata to local storage. The most sensitive surfaces are token handling, the scopes amber requests, and the integrity of what it writes to disk.

The supported "version" is always the **tip of `main`** plus the latest tagged release. Fixes are not back-ported to older tags; upgrade to the latest release if a vulnerability is discovered.

## Reporting a Vulnerability

**Please do not file a public GitHub issue for security problems.**

In the context of amber, a "vulnerability" typically means:

- Mishandling of the GitHub token (logging, leaking, or persisting it insecurely).
- Requesting broader token scopes than the backup actually needs.
- A flaw that lets a malicious repository or API response write outside the backup root or corrupt the manifest.
- A dependency in `package.json` that introduces a known CVE.

Use one of the following private channels:

1. **GitHub Private Vulnerability Reporting** (preferred): open a private advisory at <https://github.com/TitusKirch/amber/security/advisories/new>.
2. **Email**: [titus.kirch@kirch.dev](mailto:titus.kirch@kirch.dev). PGP available on request.

Please include:

- A description of the vulnerability and its impact on downstream repositories.
- Steps to reproduce.
- Any suggested fix, if you have one.

### What to expect

| Stage                        | Target timeline                                   |
| :--------------------------- | :------------------------------------------------ |
| Acknowledgement of report    | within **3 business days**                        |
| Initial assessment & triage  | within **7 business days**                        |
| Patch released (if accepted) | depends on severity — critical issues prioritised |
| Public disclosure & advisory | coordinated with reporter after the patch ships   |

## Credit

Reporters who follow this process responsibly are credited in the [CHANGELOG](CHANGELOG.md) and the corresponding GitHub Security Advisory, unless they prefer to remain anonymous.

---

Maintained by [Titus Kirch](https://github.com/TitusKirch/) / [IT-Dienstleistungen Titus Kirch](https://kirch.dev).
