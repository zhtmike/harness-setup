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
  "defaultProvider": "zai",
  "defaultModel": "glm-5.3",
  "defaultThinkingLevel": "max",
  "enabledModels": ["zai/glm-5.3", "zai/glm-5.3-flash"],
  "showCacheMissNotices": true,
  "packages": ["npm:@zhtmike/pi-minimal-dispatch", "git:github.com/zhtmike/pi-kit"]
}
```

> Default glm-5.3, thinking max at startup (`defaultThinkingLevel` — `Shift+Tab` cycles it mid-session). Flash is for recon/speed — complex multi-step work often finishes cheaper on glm-5.3 (fewer turns). Survey lanes pick flash per task except verdict-gating lanes (the default model), always with a thinking level — a lane pinning only a model inherits this `max` (step 12); the main session stays glm-5.3 (mid-session switches re-bill the cache). Image input is flash-only — the `images` column of `pi --list-models` marks glm-5.3 `no` and flash `yes`, so on glm-5.3 a `read` of an image returns only a "model does not support images" note; any session or dispatched lane that must see an image pins flash.

## 3. Install skills

Personal skills (zhtmike/skills):

```bash
mkdir -p ~/gitlocal ~/.agents/skills
git clone https://github.com/zhtmike/skills ~/gitlocal/skills
ln -sfn ~/gitlocal/skills/code-review ~/.agents/skills/code-review
ln -sfn ~/gitlocal/skills/coding-style ~/.agents/skills/coding-style
ln -sfn ~/gitlocal/skills/spike ~/.agents/skills/spike
ln -sfn ~/gitlocal/skills/propose ~/.agents/skills/propose
ln -sfn ~/gitlocal/skills/commit-gate ~/.agents/skills/commit-gate
ln -sfn ~/gitlocal/skills/conversation-gate ~/.agents/skills/conversation-gate
ln -sfn ~/gitlocal/skills/survey ~/.agents/skills/survey
ln -sfn ~/gitlocal/skills/self-learn ~/.agents/skills/self-learn
```

> `~/.agents/skills/` is the cross-agent skills standard dir — pi reads it natively. Symlinks keep `git pull` in `~/gitlocal/skills` as the single source of truth; skip the clone if the directory already exists. `/reload` after any change. `git -C ~/gitlocal/skills pull --ff-only` updates them (symlinks track the clone — they never self-update; extensions ride `pi update --extensions`).
> More skills on demand only when needed: `gh skill search` / `hf skills list` — never pre-installed globally.

## 4. Install CLI tools

CLIs complement the MCP servers (steps 5–9): help output is read on demand — progressive disclosure, zero context overhead. Install priority: homebrew → conda-forge → PyPI/npm.

```bash
brew install gh node ripgrep fd jq fzf tree ast-grep coreutils
conda install -c conda-forge huggingface_hub            # fallback: pip install huggingface_hub
```

> Toolbox: `rg` fast search · `fd` find · `jq` JSON · `fzf` fuzzy filter · `tree` directory overview · `ast-grep` structural search/replace · `timeout` (coreutils) bounds long-running commands.

Login each CLI (env vars are the non-interactive equivalent — enough to put the exports in `~/.zshrc`):

```bash
gh auth login           # or export GH_TOKEN="…"       (browser OAuth, or a read-only fine-grained PAT — see note)
hf auth login           # or export HF_TOKEN="…"        (huggingface.co/settings/tokens)
```

> `gh auth login`'s keyring credential is an OAuth token with account-wide scopes — the machine's write credential, working where organizations block classic PATs. Keep it on personal single-user machines only. Where shared servers and cluster nodes need gh, give it a read-only ceiling instead: `export GH_TOKEN=<YOUR_READONLY_PAT>` with a fine-grained PAT in the same read-only shape as step 5's — reads work, writes fail at the credential.

## 5. Add GitHub MCP

Create a [fine-grained personal access token](https://github.com/settings/personal-access-tokens/new) with repository access **All repositories** and Contents, Issues, Pull requests, and Actions all set **Read-only** (private repos readable too), then add the env var.

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

## 6. Add Context7 MCP

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

## 7. Add Websearch & Z.AI Plan MCPs

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

The Z.AI Coding Plan (step 2) bundles three remote MCPs — no extra keys, they reuse `${ZAI_API_KEY}`, but calls bill against the plan quota:

```json
"zai_search": {
  "url": "https://api.z.ai/api/mcp/web_search_prime/mcp",
  "headers": {
    "Authorization": "Bearer ${ZAI_API_KEY}",
    "Accept": "application/json, text/event-stream"
  },
  "description": "Z.AI web search — current info, CN/regional sources, domain/recency filters"
},
"zai_reader": {
  "url": "https://api.z.ai/api/mcp/web_reader/mcp",
  "headers": {
    "Authorization": "Bearer ${ZAI_API_KEY}",
    "Accept": "application/json, text/event-stream"
  },
  "description": "Z.AI web reader — fetch a URL as clean markdown"
},
"zread": {
  "url": "https://api.z.ai/api/mcp/zread/mcp",
  "headers": {
    "Authorization": "Bearer ${ZAI_API_KEY}",
    "Accept": "application/json, text/event-stream"
  },
  "description": "ZRead — GitHub repo tree, file reader, and repo docs"
}
```

> https://docs.bigmodel.cn/cn/coding-plan/mcp/search-mcp-server (mainland accounts: host is `open.bigmodel.cn`). The `Accept` header is required — omitting it returns HTTP 400. These endpoints rate-limit per account (`1302`/HTTP 429) independently of the quota windows: single lookups only — parallel `survey` fan-out stays on `websearch`.

## 8. Add GitHub Code Search MCP

No auth required:

```json
"gh_grep": {
  "url": "https://mcp.grep.app",
  "description": "GitHub Code Search — real-world code examples across public repositories"
}
```

> https://grep.app

## 9. Add Hugging Face MCP

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
    "zai_search": {
      "url": "https://api.z.ai/api/mcp/web_search_prime/mcp",
      "headers": {
        "Authorization": "Bearer ${ZAI_API_KEY}",
        "Accept": "application/json, text/event-stream"
      },
      "description": "Z.AI web search — current info, CN/regional sources, domain/recency filters"
    },
    "zai_reader": {
      "url": "https://api.z.ai/api/mcp/web_reader/mcp",
      "headers": {
        "Authorization": "Bearer ${ZAI_API_KEY}",
        "Accept": "application/json, text/event-stream"
      },
      "description": "Z.AI web reader — fetch a URL as clean markdown"
    },
    "zread": {
      "url": "https://api.z.ai/api/mcp/zread/mcp",
      "headers": {
        "Authorization": "Bearer ${ZAI_API_KEY}",
        "Accept": "application/json, text/event-stream"
      },
      "description": "ZRead — GitHub repo tree, file reader, and repo docs"
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

Verify all eight connect (exits 1 unless every enabled server connects):

```bash
source ~/.zshrc && pi mcp list
```

## 10. Codemode

MCP, `tool_search`, and codemode are built in. The servers above use the default `codemode` exposure, which activates codemode automatically — no settings entry required (disable with `autoEnableCodemode: false` in `mcp.json`). Tools never enter context; servers appear as one-liners in an `mcp_servers` system-prompt section (fed by the `description` field). Opt a server into `deferred` to get `tool_search` (loaded tools stay declared on that transcript branch); `direct` declares all ~84 tool schemas in every request; `hidden` registers but blocks access. Promote a single hot tool to direct calls with `toolExposure` (a per-server key in `mcp.json`). MCP connections never bust the prompt cache, but each newly declared tool re-bills the prefix once (tool schemas precede messages).
> Codemode runs one model-written JavaScript script (QuickJS sandbox — no fs/network, tools only) whose parallel calls and filtered output are all that reach the context: inside scripts, bash holds up to 1 MiB and MCP results arrive untruncated (direct calls: 50 KB / 20 KB middle-elided). Scripts reach every server's tools via `searchTools()` / `describeNamespace()`.
> In codemode scripts, MCP results arrive as `{content:[{type,text}]}` envelopes with JSON-string text — join the parts and `JSON.parse`.
> Keep `codemode.mode` at the default `"on"` — direct tool calls stay available; scripts are an extra lane for fan-out. `"only"` hides all other tools — avoid with glm-5.3. `codemode.inlineBudget` (default 3000) caps tool declarations in the codemode description.

## 11. Install the dispatch extension

```bash
pi install npm:@zhtmike/pi-minimal-dispatch
cat > ~/.pi/agent/pi-minimal-dispatch.json <<'EOF'
{ "maxDefaultLanes": 3 }
EOF
```

> Writes the `packages` entry into `~/.pi/agent/settings.json` (shown in step 2's payload) and the package into `~/.pi/agent/npm/`. `pi-minimal-dispatch` provides the `dispatch`/`lanes` tools the Dispatch section (step 12) runs on — detached lanes that outlive the session, state derived from their event streams, and a wait/collect/release loop; the package's `docs/api.md` carries the mechanics. Update with `pi update --extensions`, remove with `pi remove npm:@zhtmike/pi-minimal-dispatch`; the git source (`pi install git:github.com/zhtmike/pi-minimal-dispatch`) tracks main between releases. The config write sets `maxDefaultLanes` — the retired ≤-3 clause's rule, now a tool-enforced cap; the package's `docs/api.md` (`#configuration`) carries the semantics. If the tools ever go missing, the retired bash template is recoverable: `git log -S 'nohup sh -c' -- pi/README.md`.

Then the personal gate package (checkout claim, git/gh approval floors, review scaffolds — it replaces the workflow payload's checkout-claim bullet and the commit/conversation gates' mechanical halves, with two tightenings: gh state verbs — merge/close/reopen/delete and review verdicts — are refused outright rather than approval-gated, and `commit` injects the identity trailers itself, so only repo-required trailers ride the `trailers` param). The skills stay tool-agnostic — the wiring lives here: commit-gate's commit/push flows run through `commit`/`bind`/`approve` and the floors, code-review's texts come back from `review`, conversation-gate's PR draft comes from `draft`:

```bash
pi install git:github.com/zhtmike/pi-kit
cat > ~/.pi/agent/pi-kit.json <<'EOF'
{
	"ownerLogins": ["<your-github-login>"],
	"standingAllows": []
}
EOF
```

> Same overlay rules as pi's settings (defaults → agent dir → project `.pi/pi-kit.json`). **`ownerLogins` is yours** — put your own GitHub login there: it gates `git push` (owner-checked under any allow), and a copied login means every push of yours refuses. Keep `standingAllows` empty unless you consciously opt in: an entry like `{ "repo": "*", "shapes": ["commit", "push", "pr", "comment", "tag", "release"] }` pre-approves every ask shape on every repo (this machine's owner runs it — ask-tier dialogs disappear for agent-typed git/gh; every ask shape also offers "Approve for this session"), while destructive and refuse rows stay gated by design either way. Per-repo entries are the tamer form. The shape names are the gate-action vocabulary — same words `approve` records. Semantics: the repo's `docs/api.md`. Update with `pi update --extensions`. A bad config file fences every gated op and aborts the session at startup — fix the file, restart.

## 12. Add usage guidance to AGENTS.md

`~/.pi/agent/AGENTS.md`:

```markdown
# Tool Guidance

MCP tool declarations self-describe — read them before calling (`describeTool` in codemode), and prefer MCP over raw CLI.

When two loaded layers conflict, the nearer-the-work layer's policy wins; a farther layer's machine-capability facts are floors — a nearer layer may tighten them, never loosen; a standing conflict is a defect to fix at its owner.

## Tool selection order

1. Local codebase → `rg`/`fd` first, then read; `ast-grep` for structural queries — scope searches to known paths; global or systematic sweeps (repo roots, home, unscoped globs) are out.
2. Library/dependency internals → local-first — check `~/gitlocal/<name>` first; uncloned → `zread`, else `gh`.
3. Library docs → `context7`; usage examples → `gh_grep`; GitHub issues/PRs/CI → `gh`; papers and Hub lookups → `hf`.
4. Everything else current/external → `websearch` for parallel fan-out, `zai_search`/`zai_reader` for single lookups and CN sources; curl via bash as fallback.

## Dispatch — sub-tasks via fresh pi instances

- Dispatch is the default for self-contained sub-tasks; the main session keeps judgment, small edits, and the gates. Research fans out in parallel lanes; implementation dispatches one lane at a time, eligible when its contract serializes whole — spec, file scope, and acceptance checks fit one brief, decision-complete: the lane makes no decision the brief could have made.
- Briefs carry everything — goal, scope, expected deliverable and format, what not to do — and state that the addressee is a dispatched leaf; a lane running tests gets the covering subset named in its brief; the cheaper the lane, the fuller the brief: fast-model lanes execute plans, not goals — decomposition and judgment calls live in the brief.
- Tier with the job; pin model + thinking together at spawn, never mid-session: mechanical recon on the fast model (the non-default entry of `enabledModels` in `~/.pi/agent/settings.json`) at low thinking, substantive investigation and implementation lanes on fast at high or maximum thinking, judgment and verdict work on the default model at high or maximum thinking. An image-reading task pins a vision-capable model (`pi --list-models`'s `images` column). Never pin the fast model bare.
- A write-capable lane writes data artifacts only, under the dispatcher's claim. An implementation lane edits only inside a dispatcher-assigned worktree and lands only dispatcher-assigned artifact paths (patch + report) named in its final message; the parent applies, verifies, and lands the patch through the normal commit gate — the lane never lands code.
```

`~/.pi/agent/APPEND_SYSTEM.md`:

```markdown
# Workflow

Duties: plan, implement, verify. One session, one coherent change.

- Non-trivial work: write `.pi/work/PLAN.md` first, track in `.pi/work/TODO.md` — both under your session dir `.pi/work/s/$PI_SESSION_ID/` (the full id).
- Artifacts are ephemeral: when the change ships, delete its `.pi/work/` files (`checkout` action `clean` covers the session dir) — yours only: your session dir and your settled waves (`lanes action=release`); another session's artifacts are never yours to delete. Stale plans mislead fresh sessions; a sweep destroys siblings.
- Stage flow: one task proceeds through its stages — investigate, design, prove, finish, gate the commit — without asking to continue between stages; the asks are design acceptance, external actions, and genuine unresolvable ambiguity. A context-gathering artifact handoff is a stage boundary, not a stop — the fresh session resumes without asking.
- Stage completion is not task wind-down: wind down only when the task is settled — delivered and verified, nothing pending on the session — or when the session ends with it unmet.
- A session ends with its loops closed: every open item is done, blocked with the blocker named, or handed to the user as a decision — agent deferral without a blocker is not a finish.
- No preamble, no flattery, honest pushback — verdicts flip only on named new evidence, never on mere pushback; an owner's call gets at most one course-correction, then deference; "no action needed" is terminal — re-asking is not evidence.
```

> pi loads AGENTS.md from `~/.pi/agent/` + cwd + ancestors (AGENTS.md wins over CLAUDE.md).
> Trim payloads from contradicted and duplicated lines first — a line naming a concrete observed failure survives a trim; length alone is not the axis.

> The isolation rules exist because concurrent sessions in one repo share `.pi/work` and the checkout: session dirs namespace scratch (the full session id — a uuidv7 prefix is a ~65 s timestamp window that collides for concurrent sessions), `release` is the only wave cleanup, and pi-kit's `checkout` claim keeps one editor per checkout (a second task takes `checkout`'s worktree). Refusals met there are by design — never worked around.

## 13. Verify

```bash
source ~/.zshrc && pi
```

In pi and the shell:

1. `/model` → zai/glm-5.3; `Shift+Tab` → max; `Ctrl+S` to save.
2. `/mcp` → all eight servers connected (or `pi mcp list` from the shell); `pi list` → `npm:@zhtmike/pi-minimal-dispatch` and `git:github.com/zhtmike/pi-kit` installed (dispatch/lanes + the six pi-kit tools load).
3. "Run `gh auth status`" → authenticated — keyring with `Token scopes: 'repo, …'` (env-token setups show their own scopes). Same for `hf auth whoami`.
4. "List your skills" → code-review, coding-style, spike, propose, commit-gate, conversation-gate, survey, self-learn.
5. Smoke test: `/skill:survey <small topic>` → investigation lanes dispatched per the Dispatch section, one synthesized answer; "review this diff" → a single dispatched reviewer; `checkout` (action `status`) → the claim stamp state.

> Daily: `Ctrl+L` model picker (`Ctrl+P` cycles), `Shift+Tab` thinking, `pi -c` continue, `pi -r` resume, `pi --print "task"` one-shot, `pi --no-mcp --tools read,grep,find,ls` read-only (MCP-free), `!cmd` shell, `/tree` edit earlier message, `/reload` after config changes.
> TUI: fullscreen is the default (`"tuiMode": "regular"` reverts); `"theme"` in settings.json (default `system`; custom themes in `~/.pi/agent/themes/`); keybindings in `~/.pi/agent/keybindings.json` (`/hotkeys` lists current).
> Cost: `CH` in the footer + `/session` (cache hit-rate, re-billed dollars); model/thinking switches re-bill the prefix — avoid them mid-session. Long sessions auto-compact when context nears the window limit (16384 tokens reserved; the last 20000 stay un-summarized); `/compact` forces it.
> pi is YOLO by design — no permission prompts; trust + git are the safety net. A project with pi resources under `.pi/` asks to trust it once on first launch (`/trust`; pre-decide with `defaultProjectTrust` in settings.json).

## References

- [pi](https://github.com/earendil-works/pi) — [Docs](https://pi.dev/docs/latest)
- [Author's design article](https://mariozechner.at/posts/2025-11-30-pi-coding-agent/)
- [Skills](https://github.com/zhtmike/skills)
