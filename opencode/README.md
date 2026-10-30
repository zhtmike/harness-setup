# OpenCode + oh-my-opencode-slim Setup Guide

> For the latest updates, always check the official docs — see [References](#references) at the bottom.

## 1. Install OpenCode

**macOS:**

```bash
brew install opencode
```

**Linux:**

```bash
curl -fsSL https://opencode.ai/v2/install | bash
```

```bash
opencode --version
```

> https://github.com/anomalyco/opencode · https://opencode.ai/v2/docs

## 2. Install pyright typechecker

**macOS:**

```bash
brew install pyright
```

**Linux:**

```bash
npm install -g pyright
```

> v2 accepts and preserves `lsp` config but has no LSP runtime yet — no built-in servers start, no diagnostics, no LSP tool; record lint/typecheck commands in AGENTS.md instead. `extensions` is optional in custom entries. pyright still serves as the CLI typechecker.

## 3. Configure providers

```bash
opencode auth login          # select DeepSeek
opencode auth login          # select Z.AI Coding Plan
opencode models
```

> DeepSeek: https://platform.deepseek.com/usage
> 
> Z.AI Coding Plan: https://z.ai/manage-apikey/account
> 
> In the TUI, `/connect` is the interactive equivalent of `opencode auth login`.

## 4. Install oh-my-opencode-slim

```bash
npx oh-my-opencode-slim@latest install
```

This generates `opencode.json` (or `opencode.jsonc` if one already exists), `tui.json`, and `oh-my-opencode-slim.json` with stock presets. Replace `~/.config/opencode/oh-my-opencode-slim.json` with the customized version below (step 14).

oh-my-opencode-slim auto-provides **context7** and **gh_grep** — add them to `opencode.jsonc` only for API-key auth (context7) or visibility (gh_grep). **Websearch** is an OpenCode built-in tool (step 8); **gh**, **wandb**, and **hf** always need explicit config.

All MCP servers live under `"mcp"."servers"` in `~/.config/opencode/opencode.json` (or `opencode.jsonc` — either works; the steps below say `opencode.jsonc` for brevity). Each step shows just the inner server entry; a complete merged example is shown at the end of step 10. v2 routes MCP tools through Code Mode by default — the entries here set `"codemode": false` to register tools directly, which the step-11 guidance and the agent `mcps` grants are written against.

## 5. Add GitHub MCP

Create a [fine-grained personal access token](https://github.com/settings/personal-access-tokens/new) with repository access **All repositories** and Contents, Issues, Pull requests, and Actions all set **Read-only** (private repos readable too), then:

Add to your shell rc file (`~/.zshrc` on macOS, `~/.bashrc` on Linux):

```bash
export GITHUB_PERSONAL_ACCESS_TOKEN="your-github-pat"
```

```bash
source ~/.zshrc   # or ~/.bashrc on Linux
```

Add to `"mcp"."servers"` in `~/.config/opencode/opencode.jsonc`:

```jsonc
"gh": {
  "type": "remote",
  "url": "https://api.githubcopilot.com/mcp/",
  "oauth": false,
  "codemode": false,
  "headers": {
    "Authorization": "Bearer {env:GITHUB_PERSONAL_ACCESS_TOKEN}",
    "X-MCP-Toolsets": "context,issues,pull_requests,repos,actions",
    "X-MCP-Readonly": "true"
  }
}
```

> `X-MCP-Toolsets` limits registered toolsets to reduce context tokens. `X-MCP-Readonly` prevents accidental writes.
>
> https://github.com/github/github-mcp-server/blob/main/docs/installation-guides/install-opencode.md

## 6. Add W&B MCP

Get your key at [wandb.ai/authorize](https://wandb.ai/authorize), then add the env var (same pattern as step 5):

```bash
export WANDB_API_KEY="your-wandb-key"
```

Add to `"mcp"."servers"` in `~/.config/opencode/opencode.jsonc`:

```jsonc
"wandb": {
  "type": "remote",
  "url": "https://mcp.withwandb.com/mcp",
  "oauth": false,
  "codemode": false,
  "headers": {
    "Authorization": "Bearer {env:WANDB_API_KEY}",
    "Accept": "application/json, text/event-stream"
  }
}
```

> https://github.com/wandb/wandb-mcp-server

## 7. Add Context7 MCP

Get your key at [context7.com/dashboard](https://context7.com/dashboard), then add the env var:

```bash
export CONTEXT7_API_KEY="your-context7-key"
```

Add to `"mcp"."servers"` in `~/.config/opencode/opencode.jsonc`:

```jsonc
"context7": {
  "type": "remote",
  "url": "https://mcp.context7.com/mcp",
  "oauth": false,
  "codemode": false,
  "headers": {
    "Authorization": "Bearer {env:CONTEXT7_API_KEY}",
    "Accept": "application/json, text/event-stream"
  }
}
```

> https://github.com/upstash/context7

## 8. Websearch (built-in, no MCP)

Websearch is an OpenCode built-in tool, enabled by default — no MCP entry. Providers: Exa, Firecrawl, Parallel, Tavily, TinyFish — to use Exa, export its key in your shell rc file (`~/.zshrc` on macOS, `~/.bashrc` on Linux):

```bash
export EXA_API_KEY="your-exa-key"
```

The first search asks for permission and a provider choice. Restrict it per agent with the `websearch` permission action.

## 9. Add GitHub Code Search MCP

Also auto-provided by oh-my-opencode-slim. Adding it to `opencode.jsonc` is optional — shown here for reference, for explicit control. No auth required.

Add to `"mcp"."servers"` in `~/.config/opencode/opencode.jsonc`:

```jsonc
"gh_grep": {
  "type": "remote",
  "url": "https://mcp.grep.app",
  "oauth": false,
  "codemode": false
}
```

> https://grep.app

## 10. Add Hugging Face MCP

Create a read token at [huggingface.co/settings/tokens](https://huggingface.co/settings/tokens), then add the env var (same pattern as step 5):

```bash
export HF_TOKEN="your-hf-token"
```

Add to `"mcp"."servers"` in `~/.config/opencode/opencode.jsonc`:

```jsonc
"hf": {
  "type": "remote",
  "url": "https://huggingface.co/mcp",
  "oauth": false,
  "codemode": false,
  "headers": {
    "Authorization": "Bearer {env:HF_TOKEN}"
  }
}
```

> The hosted endpoint of the official Hugging Face MCP server — no local process needed. A read token is enough; toggle the exposed tools (Hub search/filesystem, Spaces, papers) at [huggingface.co/settings/mcp](https://huggingface.co/settings/mcp).
>
> https://github.com/huggingface/hf-mcp-server

After all MCP entries are added, the `"mcp"` block should look like:

```jsonc
"mcp": {
  "servers": {
    "gh": {
      "type": "remote",
      "url": "https://api.githubcopilot.com/mcp/",
      "oauth": false,
      "codemode": false,
      "headers": {
        "Authorization": "Bearer {env:GITHUB_PERSONAL_ACCESS_TOKEN}",
        "X-MCP-Toolsets": "context,issues,pull_requests,repos,actions",
        "X-MCP-Readonly": "true"
      }
    },
    "wandb": {
      "type": "remote",
      "url": "https://mcp.withwandb.com/mcp",
      "oauth": false,
      "codemode": false,
      "headers": {
        "Authorization": "Bearer {env:WANDB_API_KEY}",
        "Accept": "application/json, text/event-stream"
      }
    },
    "context7": {
      "type": "remote",
      "url": "https://mcp.context7.com/mcp",
      "oauth": false,
      "codemode": false,
      "headers": {
        "Authorization": "Bearer {env:CONTEXT7_API_KEY}",
        "Accept": "application/json, text/event-stream"
      }
    },
    "gh_grep": {
      "type": "remote",
      "url": "https://mcp.grep.app",
      "oauth": false,
      "codemode": false
    },
    "hf": {
      "type": "remote",
      "url": "https://huggingface.co/mcp",
      "oauth": false,
      "codemode": false,
      "headers": {
        "Authorization": "Bearer {env:HF_TOKEN}"
      }
    }
  }
}
```

## 11. Add MCP usage guidance to AGENTS.md

Add routing policy and session workflow to `~/.config/opencode/AGENTS.md` — MCP-over-CLI precedence, agent delegation, tool selection order, and stage-flow discipline; tool declarations and the preset config self-describe the rest:

```markdown
## Tool Guidance

MCP tools self-describe — read declarations before calling — and take priority over raw CLI. @librarian owns context7 and deeper Hub research — other agents delegate docs lookups to it.

### Tool selection order

1. Local codebase → `rg`/`fd` first, then read.
2. Library/dependency internals → `~/gitlocal/<name>` before any network search (machine profile owns the rule).
3. Library docs → `context7` (via @librarian); usage examples → `gh_grep`.
4. GitHub issues/PRs/CI → `gh`; papers and Hub lookups → `hf`; W&B → `wandb`.
5. Everything else current/external → websearch / webfetch.

## Workflow

- Context gathering: delegate to read-only subagents — @librarian for docs and research, @explorer for repo recon, @oracle for verdicts — findings return to the session's own context, no artifact file, no fresh session; parallel research is fine, implementation keeps one writer.
- Stage flow: one task proceeds through its stages — investigate, design, prove, finish, gate the commit — without asking to continue between stages; the asks are design acceptance, external actions, and genuine unresolvable ambiguity. A subagent returning its findings is a stage boundary, not a stop — the session continues without asking.
- Stage completion is not task wind-down: wind down only when the task is settled — delivered and verified, nothing pending on the session — or when the session ends with it unmet.
- A session ends with its loops closed: every open item is done, blocked with the blocker named, or handed to the user as a decision — agent deferral without a blocker is not a finish.
```

## 12. Install mattpocock skills (grill-me, grilling)

> Requires Node.js ≥ 22. If needed: `brew install node` or `nvm install node` (see https://github.com/nvm-sh/nvm).

```bash
npx skills@latest add mattpocock/skills --yes --global --skill "grill-me" --skill "grilling"
```

> https://github.com/mattpocock/skills

## 13. Install personal skills (zhtmike/skills)

```bash
mkdir -p ~/gitlocal ~/.config/opencode/skills
git clone https://github.com/zhtmike/skills ~/gitlocal/skills
ln -sfn ~/gitlocal/skills/code-review ~/.config/opencode/skills/code-review
ln -sfn ~/gitlocal/skills/coding-style ~/.config/opencode/skills/coding-style
ln -sfn ~/gitlocal/skills/spike ~/.config/opencode/skills/spike
ln -sfn ~/gitlocal/skills/propose ~/.config/opencode/skills/propose
ln -sfn ~/gitlocal/skills/commit-gate ~/.config/opencode/skills/commit-gate
ln -sfn ~/gitlocal/skills/conversation-gate ~/.config/opencode/skills/conversation-gate
ln -sfn ~/gitlocal/skills/survey ~/.config/opencode/skills/survey
ln -sfn ~/gitlocal/skills/self-learn ~/.config/opencode/skills/self-learn
```

> Symlinks keep a single source of truth: `git pull` in `~/gitlocal/skills` updates both skills everywhere. https://github.com/zhtmike/skills

## 14. Apply the customized presets

Replace `~/.config/opencode/oh-my-opencode-slim.json`:

```json
{
  "$schema": "https://unpkg.com/oh-my-opencode-slim@latest/oh-my-opencode-slim.schema.json",
  "preset": "glm",
  "disabled_agents": ["observer"],
  "presets": {
    "deepseek": {
      "orchestrator": { "model": "deepseek/deepseek-v4-pro", "variant": "max", "skills": ["*"], "mcps": ["*", "!context7"] },
      "oracle":       { "model": "deepseek/deepseek-v4-pro", "variant": "max", "skills": ["code-review"], "mcps": ["gh"] },
      "librarian":    { "model": "deepseek/deepseek-flash", "variant": "low", "skills": [], "mcps": ["context7", "gh_grep", "gh", "hf", "wandb"] },
      "explorer":     { "model": "deepseek/deepseek-flash", "variant": "low", "skills": [], "mcps": ["gh", "wandb"] },
      "designer":     { "model": "deepseek/deepseek-flash", "variant": "high", "skills": ["coding-style"], "mcps": [] },
      "fixer":        { "model": "deepseek/deepseek-flash", "variant": "high", "skills": ["coding-style"], "mcps": [] }
    },
    "glm": {
      "orchestrator": { "model": "zai-coding-plan/glm-5.3", "variant": "max", "skills": ["*"], "mcps": ["*", "!context7"] },
      "oracle":       { "model": "zai-coding-plan/glm-5.3", "variant": "max", "skills": ["code-review"], "mcps": ["gh"] },
      "librarian":    { "model": "zai-coding-plan/glm-5.3-flash", "variant": "low", "skills": [], "mcps": ["context7", "gh_grep", "gh", "hf", "wandb"] },
      "explorer":     { "model": "zai-coding-plan/glm-5.3-flash", "variant": "low", "skills": [], "mcps": ["gh", "wandb"] },
      "designer":     { "model": "zai-coding-plan/glm-5.3-flash", "variant": "high", "skills": ["coding-style"], "mcps": [] },
      "fixer":        { "model": "zai-coding-plan/glm-5.3-flash", "variant": "high", "skills": ["coding-style"], "mcps": [] }
    }
  }
}
```

> When omo-slim updates its stock defaults, re-run step 4 then re-apply this config.
>
> `variant` is the model's reasoning effort, and GLM-5.3 / DeepSeek expose exactly `low` / `high` / `max` — there is no `medium`. Variants tier with the job, main session stays `max`: `low` for lookup/recon (librarian, explorer), `high` for substantive-but-bounded work (designer, fixer), `max` for judgment (orchestrator, oracle). omo-slim's preset editor clears a variant the newly picked model doesn't expose — after re-picking models, re-check these values.

## 15. Verify

```bash
source ~/.zshrc   # or ~/.bashrc on Linux
opencode
```

Check providers, MCPs, skills, and preset switching (`/preset deepseek` or `/preset glm`).

Verify MCP servers are connected:

```bash
opencode mcp list              # should show all configured servers connected
```

## References

- [OpenCode docs](https://opencode.ai/v2/docs) — [MCP servers](https://opencode.ai/v2/docs/mcp-servers/) · [skills](https://opencode.ai/v2/docs/skills/) · [CLI](https://opencode.ai/v2/docs/cli/commands)
- [oh-my-opencode-slim](https://github.com/alvinunreal/oh-my-opencode-slim) — [`docs/mcps.md`](https://github.com/alvinunreal/oh-my-opencode-slim/blob/master/docs/mcps.md) · [`docs/skills.md`](https://github.com/alvinunreal/oh-my-opencode-slim/blob/master/docs/skills.md) · [`docs/configuration.md`](https://github.com/alvinunreal/oh-my-opencode-slim/blob/master/docs/configuration.md)