# pi Coding Agent Setup Guide

> For the latest updates, always check the official docs — see [References](#references) at the bottom.

## 1. Install pi

**macOS:**

```bash
brew install pi-coding-agent
```

**Linux / any platform:**

```bash
curl -fsSL https://pi.dev/install.sh | sh
# or: npm install -g --ignore-scripts @earendil-works/pi-coding-agent
```

```bash
pi --version
```

> The homebrew-core formula is `pi-coding-agent` (not `pi`) and can lag releases — the curl/npm paths are always current; npm needs Node ≥ 22.19. Update with `brew upgrade pi-coding-agent`. https://github.com/earendil-works/pi

## 2. Configure provider (Z.AI Coding Plan)

Get your key at https://z.ai/manage-apikey/account. Add to your shell rc file (`~/.zshrc` on macOS, `~/.bashrc` on Linux):

```bash
export ZAI_API_KEY="your-zai-coding-plan-key"
```

Check models:

```bash
source ~/.zshrc && pi --list-models zai
```

> `glm-5.3` / `glm-5.3-flash` are in pi's model catalog (refreshed from pi.dev), so no manual model declarations. If a future GLM release outpaces the catalog, declare it in `~/.pi/agent/models.json`.

```bash
mkdir -p ~/.pi/agent
```

`~/.pi/agent/settings.json`:

```json
{
  "defaultProvider": "zai",
  "defaultModel": "glm-5.3",
  "defaultThinkingLevel": "max",
  "enabledModels": ["zai/glm-5.3", "zai/glm-5.3-flash"],
  "showCacheMissNotices": true
}
```

> Default glm-5.3, thinking max at startup (`defaultThinkingLevel`); `Shift+Tab` cycles mid-session. `Ctrl+P` cycles `enabledModels`; `Ctrl+L`/`/model` picker; `Ctrl+S` saves default. Flash is for recon/speed — complex multi-step work often finishes cheaper on glm-5.3 (fewer turns). Survey lanes pick flash per task (step 12); the main session stays glm-5.3 (mid-session switches re-bill the cache).

## 3. Install skills

```bash
npx skills@latest add mattpocock/skills --yes --global -a pi --skill "grill-me" --skill "grilling"
```

> https://github.com/mattpocock/skills

Personal skills (zhtmike/skills):

```bash
mkdir -p ~/gitlocal ~/.agents/skills
git clone https://github.com/zhtmike/skills ~/gitlocal/skills
ln -sfn ~/gitlocal/skills/code-review ~/.agents/skills/code-review
ln -sfn ~/gitlocal/skills/coding-style ~/.agents/skills/coding-style
ln -sfn ~/gitlocal/skills/commit-gate ~/.agents/skills/commit-gate
ln -sfn ~/gitlocal/skills/survey ~/.agents/skills/survey
```

> `~/.agents/skills/` is the cross-agent skills standard dir — pi reads it natively. Symlinks keep `git pull` in `~/gitlocal/skills` as the single source of truth; skip the clone if the directory already exists. `/reload` after any change.
> More skills on demand only when needed: `gh skill search` / `hf skills list` — never pre-installed globally.

## 4. Install CLI tools

CLIs complement the MCP servers (steps 5–10): help output is read on demand — progressive disclosure, zero context overhead. Install priority: homebrew → conda-forge → PyPI/npm.

```bash
brew install gh node ripgrep fd jq fzf tree ast-grep coreutils
conda install -c conda-forge wandb huggingface_hub            # fallback: pip install wandb huggingface_hub
```

> Toolbox: `rg` fast search · `fd` find · `jq` JSON · `fzf` fuzzy filter · `tree` directory overview · `ast-grep` structural search/replace · `timeout` (coreutils) for dispatch lanes (step 12).

Login each CLI (env vars are the non-interactive equivalent — enough to put the exports in `~/.zshrc`):

```bash
gh auth login           # or export GH_TOKEN="…"       (github.com/settings/tokens)
wandb login             # or export WANDB_API_KEY="…"   (wandb.ai/authorize)
hf auth login           # or export HF_TOKEN="…"        (huggingface.co/settings/tokens)
```

> The `wandb` CLI cannot query runs — use the `wandb` MCP (step 6) or REST API with curl. Web/docs: `websearch` MCP (step 8) or curl.

## 5. Add GitHub MCP

Create a [GitHub Personal Access Token](https://github.com/settings/personal-access-tokens/new) with `repo`, `read:org`, and `workflow` scopes, then add the env var.

Add to your shell rc file (`~/.zshrc` on macOS, `~/.bashrc` on Linux):

```bash
export GITHUB_PERSONAL_ACCESS_TOKEN="your-github-pat"
```

```bash
source ~/.zshrc   # or ~/.bashrc on Linux
```

Add to the `mcpServers` object in `~/.pi/agent/mcp.json`:

```json
"gh": {
  "url": "https://api.githubcopilot.com/mcp/",
  "headers": {
    "Authorization": "Bearer ${GITHUB_PERSONAL_ACCESS_TOKEN}",
    "X-MCP-Readonly": "true"
  },
  "description": "GitHub — issues, PRs, repos, commits, CI (read-only)"
}
```

> All toolsets register — with the default `codemode` exposure tools never enter context, so the full tool surface costs nothing upfront. Keep `X-MCP-Readonly`: pi runs without permission prompts, and this keeps the GitHub MCP read-only as a guardrail. A fine-grained read-only PAT makes the credential itself read-only too.
> https://github.com/github/github-mcp-server/blob/main/docs/installation-guides/install-opencode.md

## 6. Add W&B MCP

Get your key at [wandb.ai/authorize](https://wandb.ai/authorize), then add the env var (same pattern as step 5):

```bash
export WANDB_API_KEY="your-wandb-key"
```

```json
"wandb": {
  "url": "https://mcp.withwandb.com/mcp",
  "headers": {
    "Authorization": "Bearer ${WANDB_API_KEY}",
    "Accept": "application/json, text/event-stream"
  },
  "description": "Weights & Biases — runs, metrics, artifacts, Weave traces, evaluations"
}
```

> https://github.com/wandb/wandb-mcp-server

## 7. Add Context7 MCP

Get your key at [context7.com/dashboard](https://context7.com/dashboard), then add the env var (same pattern as step 5):

```bash
export CONTEXT7_API_KEY="your-context7-key"
```

```json
"context7": {
  "url": "https://mcp.context7.com/mcp",
  "headers": {
    "Authorization": "Bearer ${CONTEXT7_API_KEY}",
    "Accept": "application/json, text/event-stream"
  },
  "description": "Up-to-date library documentation search"
}
```

> https://github.com/upstash/context7

## 8. Add Websearch MCP

Get your key at [exa.ai](https://exa.ai), then add the env var (same pattern as step 5):

```bash
export EXA_API_KEY="your-exa-key"
```

```json
"websearch": {
  "url": "https://mcp.exa.ai/mcp",
  "headers": {
    "Authorization": "Bearer ${EXA_API_KEY}"
  },
  "description": "Web search and docs research (Exa)"
}
```

> https://exa.ai
> More tools via URL parameter: `?tools=web_search_exa,web_fetch_exa,web_search_advanced_exa` (advanced adds domain/date filters; `agent_run` multi-step research requires auth). OAuth sign-in is also supported: `https://mcp.exa.ai/mcp?login`.

## 9. Add GitHub Code Search MCP

No auth required:

```json
"gh_grep": {
  "url": "https://mcp.grep.app",
  "description": "GitHub Code Search — real-world code examples across public repositories"
}
```

> https://grep.app

## 10. Add Hugging Face MCP

Create a read token at [huggingface.co/settings/tokens](https://huggingface.co/settings/tokens), then add the env var (same pattern as step 5):

```bash
export HF_TOKEN="your-hf-token"
```

```json
"hf": {
  "url": "https://huggingface.co/mcp",
  "headers": {
    "Authorization": "Bearer ${HF_TOKEN}"
  },
  "description": "Hugging Face Hub — models, datasets, Spaces, papers"
}
```

> https://github.com/huggingface/hf-mcp-server

After all MCP entries are added, `~/.pi/agent/mcp.json` should look like:

```json
{
  "mcpServers": {
    "gh": {
      "url": "https://api.githubcopilot.com/mcp/",
      "headers": {
        "Authorization": "Bearer ${GITHUB_PERSONAL_ACCESS_TOKEN}",
        "X-MCP-Readonly": "true"
      },
      "description": "GitHub — issues, PRs, repos, commits, CI (read-only)"
    },
    "wandb": {
      "url": "https://mcp.withwandb.com/mcp",
      "headers": {
        "Authorization": "Bearer ${WANDB_API_KEY}",
        "Accept": "application/json, text/event-stream"
      },
      "description": "Weights & Biases — runs, metrics, artifacts, Weave traces, evaluations"
    },
    "context7": {
      "url": "https://mcp.context7.com/mcp",
      "headers": {
        "Authorization": "Bearer ${CONTEXT7_API_KEY}",
        "Accept": "application/json, text/event-stream"
      },
      "description": "Up-to-date library documentation search"
    },
    "websearch": {
      "url": "https://mcp.exa.ai/mcp",
      "headers": {
        "Authorization": "Bearer ${EXA_API_KEY}"
      },
      "description": "Web search and docs research (Exa)"
    },
    "gh_grep": {
      "url": "https://mcp.grep.app",
      "description": "GitHub Code Search — real-world code examples across public repositories"
    },
    "hf": {
      "url": "https://huggingface.co/mcp",
      "headers": {
        "Authorization": "Bearer ${HF_TOKEN}"
      },
      "description": "Hugging Face Hub — models, datasets, Spaces, papers"
    }
  }
}
```

> Header and env values expand `${VAR}`. `sse` entries are rejected; SSE-only servers usually expose streamable HTTP at `/mcp`. OAuth servers need no credentials: put the URL in, then `/mcp login <server>`.
> Manage from the shell: `pi mcp add|remove|list|login|logout`; `/mcp` in-session; `/reload` after edits; logs in `~/.pi/agent/mcp.log`.
> MCP, `tool_search`, and codemode are built in. Servers here use the default `codemode` exposure — tools never enter context; codemode scripts reach them via `searchTools()` / `describeNamespace()`, and servers appear as one-liners in an `mcp_servers` system-prompt section (fed by the `description` field). Opt a server into `deferred` to get `tool_search` (loaded tools stay declared on that transcript branch); `direct` declares all ~79 tool schemas in every request; `hidden` registers but blocks access. Promote a single hot tool to direct calls with `toolExposure` (a per-server key in `mcp.json`). MCP connections never bust the prompt cache, but each newly declared tool re-bills the prefix once (tool schemas precede messages).

Verify all six connect (exits 1 unless every enabled server connects):

```bash
source ~/.zshrc && pi mcp list
```

## 11. Codemode

Codemode activates automatically whenever a server uses the default `codemode` exposure — no settings entry required. Disable auto-activation with `autoEnableCodemode: false` in `mcp.json`.
> Codemode runs one model-written JavaScript script (QuickJS sandbox — no fs/network, tools only) whose parallel calls and filtered output are all that reach the context: inside scripts, bash holds up to 1 MiB and MCP results arrive untruncated (direct calls: 50 KB / 20 KB middle-elided). Scripts reach every server's tools via `searchTools()` / `describeNamespace()`.
> Keep `codemode.mode` at the default `"on"` — direct tool calls stay available; scripts are an extra lane for fan-out. `"only"` hides all other tools — avoid with glm-5.3. `codemode.inlineBudget` (default 3000) caps tool declarations in the codemode description.

## 12. Add MCP usage guidance to AGENTS.md

`~/.pi/agent/AGENTS.md`:

```markdown
# Tool Guidance

MCP servers (config: `~/.pi/agent/mcp.json`) expose tools via `codemode`; promote a hot tool to direct calls with `toolExposure` in that config. CLI tools complement them — help output loads on demand.

- **gh:** auth and `gh skill` — GitHub reads go through the `gh` MCP, code examples through `gh_grep`. In codemode its results are `{content:[{type,text}]}` envelopes with JSON-string text — join the parts and `JSON.parse`; `get_review_comments` returns `{review_threads:[...]}`, not a flat array.
- **wandb:** login/sync/artifacts/sweeps — run queries go through the `wandb` MCP.
- **hf:** auth and `hf skills` — Hub lookups go through the `hf` MCP.
- **Toolbox on PATH:** `rg`, `fd`, `jq`, `fzf`, `tree`, `ast-grep` (structural search/replace).

## Tool selection order

1. Local codebase → `rg`/`fd` first, then read; `ast-grep` for structural queries.
2. Library/dependency internals → check `~/gitlocal/<name>` before any network search.
3. Library documentation → `context7`.
4. Real-world usage examples → `gh_grep`.
5. GitHub issues/PRs/CI → `gh`.
6. Papers and Hub lookups → `hf`; W&B → `wandb`.
7. Everything else current/external → `websearch`; curl via bash as fallback.

## Dispatch — sub-tasks via fresh pi instances

pi has no sub-agents by design; dispatch by spawning pi itself. A dispatch is a lane: one brief, one artifact, an independent leaf — own context, read-only, the brief is its whole job; no skills (`-ns`), no workflow duties, no re-dispatch.

Dispatch when a sub-task deserves its own context: an independent review, a read-only exploration before implementing, parallel investigation lanes, or verification of a risky change. Skills route by trigger and say what; dispatch is how a lane runs — the brief carries everything, the lane itself loads nothing. Parallel research lanes are the one blessed parallel pattern; never dispatch parallel implementation.

1. **Brief** per lane → `.pi/work/<task>-brief-<lane>.md` (names are kebab-case slugs, no spaces): goal, scope, expected deliverable and its output format, what not to do; state that the addressee is a dispatched leaf. Check no existing lane already covers the objective. Pass with `@file` — never shell-quoted.
2. **Spawn** each lane under an explicit timeout (pi's bash has no default — a stalled lane hangs the caller). One bash call, one line per lane, PID per lane — N=1 for a review or exploration, N=3–6+ for a parallel investigation:

      timeout <secs> pi --print --no-session -ns [-ne --tools read,grep,find,ls,bash] [--model zai/glm-5.3-flash] @.pi/work/<task>-brief-<lane>.md > .pi/work/<task>-<lane>.md 2> .pi/work/<task>-<lane>.err & pN=$!
      wait $pN; sN=$?   # per lane, for individual exit codes

   Read-only codebase lane: `-ne --tools read,grep,find,ls,bash` (bash stays for `git diff` / `gh` reads — read-only is enforced by the brief, never the tool list). MCP lane: drop `-ne --tools`, read-only via the brief. Scan lane: pin flash; reasoning lane: omit `--model` to inherit glm-5.3 — pin at spawn, never mid-session (switches re-bill the cache).
3. **Check**: non-zero exit or empty output = failed lane — read the `.err`, rerun it alone; rate-limited provider → run lanes sequentially. If the bash call itself timed out, its lanes died with it — keep completed lanes' outputs, rerun the rest longer or sequentially.
4. **Long lanes** outliving sensible timeouts: detach with nohup + per-lane `.exit`/`.pid` control files (clear stale files first), poll from short bash calls — `.exit` present = finished; `kill -0` = running; neither = killed. Kill at twice the expected time or on abandonment:

      rm -f .pi/work/<task>-<lane>.exit .pi/work/<task>-<lane>.pid && nohup sh -c 'timeout <secs> pi --print --no-session -ns --model zai/glm-5.3-flash @.pi/work/<task>-brief-<lane>.md > .pi/work/<task>-<lane>.md 2> .pi/work/<task>-<lane>.err; echo $? > .pi/work/<task>-<lane>.exit' >/dev/null 2>&1 & echo $! > .pi/work/<task>-<lane>.pid

5. **Consume, then clean**: read the artifacts, delete them with the briefs, `.err`s, and control files — `.pi/work/` stays ephemeral.

# Workflow Habits

- For big refactors or risky changes, stress-test the plan first (grilling / grill-me skills).
```

`~/.pi/agent/APPEND_SYSTEM.md`:

```markdown
# Workflow

Duties: plan, implement, verify. One session, one coherent change.

- Non-trivial work: write `.pi/work/PLAN.md` first, track in `.pi/work/TODO.md`.
- Artifacts are ephemeral: when the change ships, delete its `.pi/work/` files — stale plans mislead fresh sessions.
- Context gathering: separate read-only session → artifact file → implementation in a fresh session that reads the artifact (never dispatch parallel implementing agents).
- Workflow skills (survey) dispatch parallel investigation lanes; never invoke
  them from inside a dispatched instance. Before finishing risky changes, dispatch
  an independent review (Dispatch section in AGENTS.md).
- Concise answers, no preamble, no flattery, honest pushback.
```

> pi loads AGENTS.md from `~/.pi/agent/` + cwd + ancestors (AGENTS.md wins over CLAUDE.md).

## 13. Sub-task dispatch & workflow habits

pi has no sub-agents by design — dispatch a sub-task by spawning pi itself via bash (`pi --print`). The general mechanism lives in the `## Dispatch` section of `~/.pi/agent/AGENTS.md` (step 12): a dispatch is a lane, and the `survey` skill (installed from the repo in step 3) is the parallel application — N=1 for reviews and exploration, N=3–6+ for survey lanes. State lives in files; context gathering happens in its own session. (`-ne` = `--no-extensions`: drops built-in extensions including MCP and codemode; `-ns` = `--no-skills`: dispatched lanes are brief-driven leaves — no skills, no re-dispatch.)

- **Explore first, read-only**: write the brief to `.pi/work/NOTES-brief.md`, then `pi --print --no-session -ns -ne --tools read,grep,find,ls @.pi/work/NOTES-brief.md > .pi/work/NOTES.md` — the redirect is the artifact; a fresh session consumes it for implementation.
- **Plan**: non-trivial work gets `.pi/work/PLAN.md` (goal, approach, current step); track progress in `.pi/work/TODO.md` checkboxes.

> Parallel research is the one blessed parallel pattern (the author's words); if the provider rate-limits, run lanes sequentially — parallel implementation dispatches remain an anti-pattern.

## 14. Verify

```bash
source ~/.zshrc && pi
```

Inside pi:

1. `/model` → zai/glm-5.3; `Shift+Tab` → max; `Ctrl+S` to save.
2. `/mcp` → all six servers connected (or `pi mcp list` from the shell).
3. "Run `gh auth status`" → authenticated. Same for `hf auth whoami` and `wandb status`.
4. "List your skills" → grilling, code-review, coding-style, commit-gate, survey (grill-me is installed but hidden by design — `disable-model-invocation`).
5. Smoke test: `/skill:survey <small topic>` → investigation lanes dispatched per the Dispatch section, one synthesized answer; "review this diff" → a single dispatched reviewer.
6. "grill me on plan X" → grilling skill triggers.

> Daily: `Ctrl+L` model picker (`Ctrl+P` cycles), `Shift+Tab` thinking, `pi -c` continue, `pi -r` resume, `pi --print "task"` one-shot, `pi --no-mcp --tools read,grep,find,ls` read-only (MCP-free), `!cmd` shell, `/tree` edit earlier message, `/reload` after config changes.
> TUI: fullscreen is the default (`"tuiMode": "regular"` reverts); `"theme"` in settings.json (default `system`; custom themes in `~/.pi/agent/themes/`); keybindings in `~/.pi/agent/keybindings.json` (`/hotkeys` lists current).
> Cost: `CH` in the footer + `/session` (cache hit-rate, re-billed dollars); model/thinking switches re-bill the prefix — avoid them mid-session. Long sessions auto-compact when context nears the window limit (16384 tokens reserved; the last 20000 stay un-summarized); `/compact` forces it.
> pi is YOLO by design — no permission prompts; trust + git are the safety net. A project with pi resources under `.pi/` asks to trust it once on first launch (`/trust`; pre-decide with `defaultProjectTrust` in settings.json).

## References

- [pi](https://github.com/earendil-works/pi) — [Docs](https://pi.dev/docs/latest)
- [Author's design article](https://mariozechner.at/posts/2025-11-30-pi-coding-agent/)
- [Skills](https://github.com/mattpocock/skills) · [zhtmike/skills](https://github.com/zhtmike/skills)
