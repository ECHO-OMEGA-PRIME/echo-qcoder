# Upstream re-pin review (autonomy tick)

Reviewed: 2026-08-29T21:45:00-05:00 (America/Chicago)
Gate: `scripts/validate-powerpack.mjs --online` (invoked by `scripts/autonomy-tick.mjs` as `upstream-drift`)
Manifest: `config/qcoder-powerpack.json`

## Policy

Do **not** blindly re-pin. Diff pinned → live `HEAD`, review commits and security-sensitive paths, then either:

1. Re-pin the reviewed SHA in the manifest, or
2. Hold and document why (gate stays closed; gate must not be weakened).

License digests were re-fetched for every drifted entry; all matched the existing `licenseSha256` values (no license-text change).

Prompt-reported SHAs had already advanced further by review time. A second online pass also found eight additional drifts beyond the original seven. Re-pins target the live `git ls-remote … HEAD` values at review.

## Decisions (prompt set)

| Id | Posture | Old pin | New HEAD (re-pinned) | Commits | Decision |
| --- | --- | --- | ---: | ---: | --- |
| `qwen-code` | integrated | `55e20db…` | `74e71c5945428e42207edb3f19485c72a2a030ee` | 739 | **re-pin** |
| `ast-grep` | integrated | `e8c70a7…` | `c6b32d74ad12cea690cb331c88f004764df6e985` | 33 | **re-pin** |
| `goose` | reference | `064244e…` | `8ae4e4ba02836529790f47109b8785e8b42843a7` | 272 | **re-pin** |
| `openhands-agent-sdk` | reference | `684ea6a…` | `9d143aac35c2dcec9cbb046ff9f35ac5eb072f6a` | 78 | **re-pin** (security-gated) |
| `spec-kit` | reference | `684b3d8…` | `51e52be6c3b26fed3ff5424c671f4a559519a759` | 137 | **re-pin** |
| `pr-agent` | reference | `064a305…` | `01b7e8344672f5f02b76073334151cf2f4099ebc` | 129 | **re-pin** (security-gated) |
| `nuclei` | sidecar | `dfdfa5f…` | `da279d42a37fa2cee5d320907f24405ab4cbe406` | 24 | **re-pin** (security-gated) |

## Decisions (additional drift discovered at review time)

| Id | Posture | Old pin | New HEAD (re-pinned) | Commits | Decision |
| --- | --- | --- | ---: | ---: | --- |
| `serena` | integrated | `946ad98…` | `7fcbca7e62555ec2287ddb2f083caee805848ea6` | 17 | **re-pin** |
| `mini-swe-agent` | installable | `a83fcae…` | `25941c89cfbc91eb40b3f8756348c91d9977d57e` | 1 | **re-pin** |
| `browser-use` | reference | `3260188…` | `2e32d260341fae39c80bc8529ec174bad91e7672` | 94 | **re-pin** |
| `playwright-mcp` | sidecar | `7e0457a…` | `d0c29a5658b93b6e62435ceaf362a7d7dfc3522d` | 3 | **re-pin** |
| `markitdown` | sidecar | `fd239d5…` | `9dc0d6579b8739c9d0671ff205e071e3053c7df1` | 1 | **re-pin** |
| `superpowers` | reference | `44c9b2d…` | `b36e0829c6d0140e93cfef2ca599b1b07d4a7797` | 1 | **re-pin** |
| `garak` | sidecar | `cafbe99…` | `8ed1543b985a5722adb659584182faf6f7907d4e` | 55 | **re-pin** (security-gated) |
| `promptfoo` | reference/withheld | `49c0f6d…` | `4fb96412eff44ced9c47293238d3db0450a39353` | 151 | **re-pin** (git provenance only; install remains withheld) |

Holds: **none**.

Installed package pins (`@qwen-code/qwen-code@0.21.8`, `@ast-grep/cli@0.45.1`, `serena-agent==1.6.1`, etc.) are unchanged. This review re-aligns git provenance pins only; package upgrades remain a separate exact-version install decision.

## Security-sensitive reviews

### `nuclei` (sidecar)

- Range is small (24 commits): raw HTTP input/parsing fixes, proxy keep-alive stall fix, template clone/reuse across engines, passive export support, routine module bumps.
- Critical path review (`pkg/protocols/http/*`, `pkg/templates/*`, `pkg/tmplexec/*`) shows defensive parsing and isolation fixes, not auth bypass or remote code execution surface expansion for ordinary QCoder sessions.
- Nuclei remains a governed sidecar and is never loaded into ordinary coding sessions.

### `pr-agent` (reference)

- Webhook path hardens rather than relaxes auth: GitLab token verification / 401 paths, Azure Basic-auth missing-credentials 401, fork-safe secret provider usage.
- `.secrets_template.toml` only adds an empty Asana `api_token` placeholder.
- Posture stays **reference** — no automatic public review or merge authority.

### `openhands-agent-sdk` (reference)

- Adds AST-backed shell semantics and fail-safer UNKNOWN risk when destructive verbs cannot be resolved; improves secret-exposure error handling.
- Plugin format refactor is structural (closed schema / loader split), not a trust expansion into QCoder runtime.
- Posture stays **reference** — no second agent runtime embedded.

## Non-security notes

- `qwen-code`: large legitimate upstream advance (web-shell/daemon/review/permissions); includes added `security-checks.yml` and tighter tool-schema permission behavior. Exact installed CLI remains 0.21.8.
- `ast-grep`: dependency bumps, `namedChildren` API, 0.45.2 tag on upstream; local package pin remains 0.45.1 until a separate install review.
- `goose`: reference-only; includes malware-scan hardening for `uvx` selectors.
- `spec-kit`: catalog/extension/auth and bounded HTTP read fixes; reference-only.
- `serena`: language-server crash/race fixes (tsserver, Scala Metals wait, Clojure capabilities); exact installed package remains 1.6.1.
- `mini-swe-agent`: single pre-commit hooks chore.
- `browser-use`: reconnect handling, dependency bumps, sensitive-data tests; reference-only.
- `playwright-mcp` / `markitdown`: GitHub Actions full-SHA pinning / publish pipeline hygiene.
- `superpowers`: v6.3.0 workflow release; reference-only.
- `garak`: detector robustness (including MarkdownExfilContent guards), Ollama auth kwargs; sidecar only.
- `promptfoo`: large dependency/security update stream; remains install-withheld after prior high-severity audit failure — git pin only so the drift gate tracks reviewed HEAD.

## Gate integrity

- No changes to `scripts/validate-powerpack.mjs` or `scripts/autonomy-tick.mjs`.
- Online drift check still requires `commit === HEAD` and matching `licenseSha256`.
