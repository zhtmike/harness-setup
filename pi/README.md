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

**Terminal (macOS):**

> Not Terminal.app — it has no OSC 52 support, so pi's in-app copy over ssh (`Ctrl+X` last assistant message, selection + `Ctrl+C`) never reaches the Mac clipboard. Use a terminal that supports OSC 52:
>
> ```bash
> brew install --cask ghostty
> ```
>
> Ghostty supports OSC 52 out of the box. Pasting into pi needs no OSC 52 — the terminal's normal paste (`Cmd+V`) types through ssh into pi's editor. Probe from the remote host: `printf '\033]52;c;%s\007' "$(printf 'clipboard-ok' | base64)"` — `clipboard-ok` pasteable on the Mac means pi's copy keys land too.

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
  "$schema": "https://pi.dev/schemas/settings.schema.json",
  "defaultProvider": "zai",
  "defaultModel": "glm-5.3",
  "defaultThinkingLevel": "max",
  "enabledModels": ["zai/glm-5.3", "zai/glm-5.3-flash"],
  "showCacheMissNotices": true,
  "packages": ["npm:pi-minimal-dispatch"]
}
```

> Default glm-5.3, thinking max at startup (`defaultThinkingLevel` — `Shift+Tab` cycles it mid-session). Flash is for recon/speed — complex multi-step work often finishes cheaper on glm-5.3 (fewer turns). Survey lanes pick flash per task, always with a thinking level — a lane pinning only a model inherits this `max` (step 13); the main session stays glm-5.3 (mid-session switches re-bill the cache).

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
ln -sfn ~/gitlocal/skills/spike ~/.agents/skills/spike
ln -sfn ~/gitlocal/skills/propose ~/.agents/skills/propose
ln -sfn ~/gitlocal/skills/commit-gate ~/.agents/skills/commit-gate
ln -sfn ~/gitlocal/skills/survey ~/.agents/skills/survey
ln -sfn ~/gitlocal/skills/self-learn ~/.agents/skills/self-learn
```

> `~/.agents/skills/` is the cross-agent skills standard dir — pi reads it natively. Symlinks keep `git pull` in `~/gitlocal/skills` as the single source of truth; skip the clone if the directory already exists. `/reload` after any change.
> More skills on demand only when needed: `gh skill search` / `hf skills list` — never pre-installed globally.

## 4. Install CLI tools

CLIs complement the MCP servers (steps 5–10): help output is read on demand — progressive disclosure, zero context overhead. Install priority: homebrew → conda-forge → PyPI/npm.

```bash
brew install gh node ripgrep fd jq fzf tree ast-grep coreutils
conda install -c conda-forge wandb huggingface_hub            # fallback: pip install wandb huggingface_hub
```

> Toolbox: `rg` fast search · `fd` find · `jq` JSON · `fzf` fuzzy filter · `tree` directory overview · `ast-grep` structural search/replace · `timeout` (coreutils) bounds long-running commands.

Login each CLI (env vars are the non-interactive equivalent — enough to put the exports in `~/.zshrc`):

```bash
gh auth login           # or export GH_TOKEN="…"       (browser OAuth, or a read-only fine-grained PAT — see note)
wandb login             # or export WANDB_API_KEY="…"   (wandb.ai/authorize)
hf auth login           # or export HF_TOKEN="…"        (huggingface.co/settings/tokens)
```

> `gh auth login`'s keyring credential is an OAuth token with account-wide scopes — the machine's write credential, working where organizations block classic PATs. Keep it on personal single-user machines only: shared servers and cluster nodes top out at read-only GitHub credentials (`GH_TOKEN` with a read-only fine-grained PAT where gh is needed there).

> The `wandb` CLI cannot query runs — use the `wandb` MCP (step 6) or REST API with curl. Web/docs: `websearch` MCP (step 8) or curl.

## 5. Add GitHub MCP

Create a [fine-grained personal access token](https://github.com/settings/personal-access-tokens/new) with repository access **All repositories** and Contents, Issues, and Pull requests all set **Read-only** (private repos readable too), then add the env var.

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

Verify all six connect (exits 1 unless every enabled server connects):

```bash
source ~/.zshrc && pi mcp list
```

## 11. Codemode

MCP, `tool_search`, and codemode are built in. The servers above use the default `codemode` exposure, which activates codemode automatically — no settings entry required (disable with `autoEnableCodemode: false` in `mcp.json`). Tools never enter context; servers appear as one-liners in an `mcp_servers` system-prompt section (fed by the `description` field). Opt a server into `deferred` to get `tool_search` (loaded tools stay declared on that transcript branch); `direct` declares all ~79 tool schemas in every request; `hidden` registers but blocks access. Promote a single hot tool to direct calls with `toolExposure` (a per-server key in `mcp.json`). MCP connections never bust the prompt cache, but each newly declared tool re-bills the prefix once (tool schemas precede messages).
> Codemode runs one model-written JavaScript script (QuickJS sandbox — no fs/network, tools only) whose parallel calls and filtered output are all that reach the context: inside scripts, bash holds up to 1 MiB and MCP results arrive untruncated (direct calls: 50 KB / 20 KB middle-elided). Scripts reach every server's tools via `searchTools()` / `describeNamespace()`.
> Keep `codemode.mode` at the default `"on"` — direct tool calls stay available; scripts are an extra lane for fan-out. `"only"` hides all other tools — avoid with glm-5.3. `codemode.inlineBudget` (default 3000) caps tool declarations in the codemode description.

## 12. Install the dispatch extension

```bash
pi install npm:pi-minimal-dispatch
```

> Writes the `packages` entry into `~/.pi/agent/settings.json` (shown in step 2's payload) and the package into `~/.pi/agent/npm/`. `pi-minimal-dispatch` provides the `dispatch`/`lanes` tools the Dispatch section (next step) runs on: detached lanes that survive the session, derived state, a bounded `lanes wait` action, parentless deadline leash, manifest re-adoption, wave `release` with dispatcher ownership (kill and release refuse a live foreign owner); requires pi ≥ 1.4.0. Update with `pi update --extensions`, remove with `pi remove npm:pi-minimal-dispatch`; the git source (`pi install git:github.com/zhtmike/pi-minimal-dispatch`) tracks main between releases. If the tools ever go missing, the retired bash template is recoverable: `git log -S 'nohup sh -c' -- pi/README.md`.

## 13. Add usage guidance to AGENTS.md

`~/.pi/agent/AGENTS.md`:

```markdown
# Tool Guidance

MCP tool declarations self-describe — read them before calling (`describeTool` in codemode), and prefer MCP over raw CLI. In codemode, MCP results are `{content:[{type,text}]}` envelopes with JSON-string text — join the parts and `JSON.parse`.

## Tool selection order

1. Local codebase → `rg`/`fd` first, then read; `ast-grep` for structural queries.
2. Library/dependency internals → `~/gitlocal/<name>` before any network search (machine profile owns the rule).
3. Library docs → `context7`; usage examples → `gh_grep`; GitHub issues/PRs/CI → `gh`; papers and Hub lookups → `hf`; W&B → `wandb`.
4. Everything else current/external → `websearch`; curl via bash as fallback.

## Dispatch — sub-tasks via fresh pi instances

pi has no sub-agents by design; dispatch spawns independent read-only lanes (the tools describe their mechanics); the policy:

- Dispatch when a sub-task deserves its own context: an independent review, read-only exploration before implementing, parallel investigation lanes, verification of a risky change. Parallel research is the one blessed parallel pattern.
- Briefs carry everything — goal, scope, expected deliverable and format, what not to do — and state that the addressee is a dispatched leaf. Park briefs under your own `.pi/work/s/$PI_SESSION_ID/`: they are written before the wave claim, so bare `.pi/work/` briefs collide across sessions.
- Tier with the job; pin model + thinking together at spawn, never mid-session: fast model (settings' `enabledModels` carries the fast tier) + low thinking for mechanical recon, fast + medium for substantive investigation; judgment/verdict lanes run unpinned on the default model. Never pin the fast model bare — a model-only pin inherits the global default thinking level. Keep concurrent default-model lanes ≤ 3; a rate-limited provider runs lanes sequentially.
- Never delete `.pi/work` while a leash can still be running — the manifest is the only re-adopt record. Otherwise consume — collect artifacts, judge them — then release the settled wave (`lanes action=release`); a hand-sweep of `.pi/work` is how one session destroys another's. Never signal a wave you didn't dispatch, and a write-capable lane edits only under the dispatcher's claim.
```

`~/.pi/agent/APPEND_SYSTEM.md`:

```markdown
# Workflow

Duties: plan, implement, verify. One session, one coherent change.

- Non-trivial work: write `.pi/work/PLAN.md` first, track in `.pi/work/TODO.md` — both under your session dir `.pi/work/s/$PI_SESSION_ID/` (the full id).
- Artifacts are ephemeral: when the change ships, delete its `.pi/work/` files — yours only: your session dir and your settled waves (`lanes action=release`); another session's artifacts are never yours to delete. Stale plans mislead fresh sessions; a sweep destroys siblings.
- Concurrent sessions share the checkout: claim it before the first edit — `.pi/OWNER.json` `{sid,pid,host,lstart}` (pid `ps -o ppid= -p $$`, live iff its start-time string still matches), written noclobber. A live foreign claim ⇒ run the task in a worktree outside `~/gitlocal`, never the shared tree; dead ⇒ replace; yours ⇒ release at wind-down.
- Context gathering: separate read-only session → artifact file → implementation in a fresh session that reads the artifact (never dispatch parallel implementing agents).
- Workflow skills (survey) dispatch parallel investigation lanes; never invoke
  them from inside a dispatched instance. Before finishing risky changes, dispatch
  an independent review (Dispatch section in AGENTS.md).
- Concise answers, no preamble, no flattery, honest pushback.
```

> pi loads AGENTS.md from `~/.pi/agent/` + cwd + ancestors (AGENTS.md wins over CLAUDE.md).

> The isolation rules exist because concurrent sessions in one repo share `.pi/work` and the checkout: session dirs namespace scratch (the full session id — a uuidv7 prefix is a ~65 s timestamp window that collides for concurrent sessions), `release` is the only wave cleanup, and the OWNER claim keeps one editor per checkout (a second task takes a worktree). Refusals met there are by design — never worked around.

## 14. Verify

```bash
source ~/.zshrc && pi
```

Inside pi:

1. `/model` → zai/glm-5.3; `Shift+Tab` → max; `Ctrl+S` to save.
2. `/mcp` → all six servers connected (or `pi mcp list` from the shell); `pi list` → `npm:pi-minimal-dispatch` installed (dispatch/lanes tools load).
3. "Run `gh auth status`" → authenticated — keyring with `Token scopes: 'repo, …'` (env-token setups show their own scopes). Same for `hf auth whoami` and `wandb status`.
4. "List your skills" → grilling, code-review, coding-style, spike, propose, commit-gate, survey, self-learn (grill-me is installed but hidden by design — `disable-model-invocation`).
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
