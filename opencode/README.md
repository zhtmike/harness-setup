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

## 2. Install pyright LSP

**macOS:**

```bash
brew install pyright
```

**Linux:**

```bash
npm install -g pyright
```

> LSPs and formatters are opt-in — set `"lsp": true` in `opencode.json(c)`. Custom `lsp` entries must declare `extensions`.

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

All MCP servers live under `"mcp"."servers"` in `~/.config/opencode/opencode.json` (or `opencode.jsonc` — either works; the steps below say `opencode.jsonc` for brevity). Each step shows just the inner server entry; a complete merged example is shown at the end of step 10.

## 5. Add GitHub MCP

Create a [GitHub Personal Access Token](https://github.com/settings/personal-access-tokens/new) with `repo`, `read:org`, and `workflow` scopes, then:

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
  "headers": {
    "Authorization": "Bearer {env:CONTEXT7_API_KEY}",
    "Accept": "application/json, text/event-stream"
  }
}
```

> https://github.com/upstash/context7

## 8. Websearch (built-in, no MCP)

Websearch is an OpenCode built-in tool (Exa-backed), enabled by default — no MCP entry. For authenticated search instead of the anonymous tier, export the Exa key in your shell rc file (`~/.zshrc` on macOS, `~/.bashrc` on Linux):

```bash
export EXA_API_KEY="your-exa-key"
```

Restrict it per agent with `permission`.

## 9. Add GitHub Code Search MCP

Also auto-provided by oh-my-opencode-slim. Adding it to `opencode.jsonc` is optional — shown here for reference, for explicit control. No auth required.

Add to `"mcp"."servers"` in `~/.config/opencode/opencode.jsonc`:

```jsonc
"gh_grep": {
  "type": "remote",
  "url": "https://mcp.grep.app",
  "oauth": false
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
      "headers": {
        "Authorization": "Bearer {env:WANDB_API_KEY}",
        "Accept": "application/json, text/event-stream"
      }
    },
    "context7": {
      "type": "remote",
      "url": "https://mcp.context7.com/mcp",
      "oauth": false,
      "headers": {
        "Authorization": "Bearer {env:CONTEXT7_API_KEY}",
        "Accept": "application/json, text/event-stream"
      }
    },
    "gh_grep": {
      "type": "remote",
      "url": "https://mcp.grep.app",
      "oauth": false
    },
    "hf": {
      "type": "remote",
      "url": "https://huggingface.co/mcp",
      "oauth": false,
      "headers": {
        "Authorization": "Bearer {env:HF_TOKEN}"
      }
    }
  }
}
```

## 11. Add MCP usage guidance to AGENTS.md

Add tool guidance to `~/.config/opencode/AGENTS.md` so agents know when to use each MCP server, the order to prefer tools, and the workflow habits to follow:

```markdown
## MCP Tool Guidance

- **GitHub (`gh_*`):** Use for GitHub operations — listing/searching issues, PRs, repos, commits, code; reading PR diffs/files/reviews; checking CI status and logs. Prefer `gh_*` tools over raw `gh` CLI commands.
- **GitHub Code Search (`gh_grep_*`):** Use to find real-world code examples across public GitHub repositories. Great for unfamiliar APIs, usage patterns, and implementation examples.
- **W&B (`wandb_*`):** Use for Weights & Biases observability — querying runs, metrics, artifacts, Weave traces, and evaluations.
- **Websearch (built-in tool):** Use for current information, library docs, and external research.
- **Context7 (`context7_*`):** Use to search up-to-date library documentation. Use `context7_resolve-library-id` to find a library, then `context7_query-docs` to fetch its docs. Librarian owns context7 — other agents delegate docs lookups to @librarian.
- **Hugging Face (`hf_*`):** Use for Hub lookups — searching models, datasets, and Spaces (`hf_fs`, `hub_repo_search`), repo details, trending listings, and HF docs/papers. Deeper Hub research routes through @librarian.

### Tool selection order

1. Library/dependency internals → check `~/gitlocal/<name>` before any network search.
2. Library documentation → `context7` (via @librarian).
3. Real-world usage examples → `gh_grep`.
4. GitHub issues/PRs/CI → `gh`.
5. Hugging Face Hub (models, datasets, Spaces, papers) → `hf`.
6. Everything else current/external → websearch / webfetch.

### Agent MCP Access

Which MCP tools each agent role has (configured in oh-my-opencode-slim.json):

| Agent | gh | wandb | gh_grep | context7 | hf |
|---|---|---|---|---|---|
| orchestrator | ✅ | ✅ | ✅ | — | ✅ |
| oracle | ✅ | — | — | — | — |
| librarian | ✅ | ✅ | ✅ | ✅ | ✅ |
| explorer | ✅ | ✅ | — | — | — |
| designer | — | — | — | — | — |
| fixer | — | — | — | — | — |
| observer | — | — | — | — | — |

✅ = available &nbsp; — = not available

Websearch is a built-in tool, allowed for every agent by default (restrict with `permission`).

## Workflow Habits

- For big refactors or risky changes, stress-test the plan first (the `grilling`/`grill-me` skills exist for this).
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
ln -sfn ~/gitlocal/skills/commit-gate ~/.config/opencode/skills/commit-gate
ln -sfn ~/gitlocal/skills/survey ~/.config/opencode/skills/survey
```

> Symlinks keep a single source of truth: `git pull` in `~/gitlocal/skills` updates both skills everywhere. https://github.com/zhtmike/skills

## 14. Apply the customized presets

Replace `~/.config/opencode/oh-my-opencode-slim.json`:

```json
{
  "$schema": "https://unpkg.com/oh-my-opencode-slim@latest/oh-my-opencode-slim.schema.json",
  "preset": "glm",
  "disabled_agents": [],
  "presets": {
    "deepseek": {
      "orchestrator": { "model": "deepseek/deepseek-v4-pro", "variant": "max", "skills": ["*"], "mcps": ["*", "!context7"] },
      "oracle":       { "model": "deepseek/deepseek-v4-pro", "variant": "max", "skills": ["code-review"], "mcps": ["gh"] },
      "librarian":    { "model": "deepseek/deepseek-flash", "variant": "max", "skills": [], "mcps": ["context7", "gh_grep", "gh", "hf", "wandb"] },
      "explorer":     { "model": "deepseek/deepseek-flash", "variant": "max", "skills": [], "mcps": ["gh", "wandb"] },
      "designer":     { "model": "deepseek/deepseek-flash", "variant": "max", "skills": ["coding-style"], "mcps": [] },
      "fixer":        { "model": "deepseek/deepseek-flash", "variant": "max", "skills": ["coding-style"], "mcps": [] },
      "observer":     { "model": "deepseek/deepseek-flash", "variant": "max", "skills": [], "mcps": [] }
    },
    "glm": {
      "orchestrator": { "model": "zai-coding-plan/glm-5.3", "variant": "max", "skills": ["*"], "mcps": ["*", "!context7"] },
      "oracle":       { "model": "zai-coding-plan/glm-5.3", "variant": "max", "skills": ["code-review"], "mcps": ["gh"] },
      "librarian":    { "model": "zai-coding-plan/glm-5.3-flash", "variant": "max", "skills": [], "mcps": ["context7", "gh_grep", "gh", "hf", "wandb"] },
      "explorer":     { "model": "zai-coding-plan/glm-5.3-flash", "variant": "max", "skills": [], "mcps": ["gh", "wandb"] },
      "designer":     { "model": "zai-coding-plan/glm-5.3-flash", "variant": "max", "skills": ["coding-style"], "mcps": [] },
      "fixer":        { "model": "zai-coding-plan/glm-5.3-flash", "variant": "max", "skills": ["coding-style"], "mcps": [] },
      "observer":     { "model": "zai-coding-plan/glm-5.3-flash", "variant": "max", "skills": [], "mcps": [] }
    }
  }
}
```

> When omo-slim updates its stock defaults, re-run step 4 then re-apply this config.

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