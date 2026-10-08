# Working in this repo

Personal harness setup guides — one `<harness>/README.md` per harness. A new harness gets a new directory; a retired harness's directory gets deleted, and the commit message says so (outside links may point here).

- Guides document personal machine setup: verify a claim against the harness's official docs before changing it — staleness fixes land in their own commits, never folded into unrelated changes.
- Placeholders only — `<YOUR_TOKEN>` / `${ENV_VAR}` forms. Never a real token, in content or in history.
- The shared spine (install → providers → MCP servers → AGENTS.md guidance → skills → verify) is deliberate; keep new guides on it where it applies.
- Commit messages carry the why — the gists these came from had empty messages; that gap is the reason this repo exists. Content is docs: guide edits use the `docs` type.
- Commit messages describe guide changes only — no quoted user instructions, session habits, node-sync narratives, or local paths beyond the guides' own content; machine wiring is local state.
- Commits go through the fresh-review gate (the global commit-gate skill); draft the full message first.
