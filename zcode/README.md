# ZCode Setup Guide

> For the latest updates, always check the official docs — see [References](#references) at the bottom.

## 1. Install ZCode

Download from https://zcode.z.ai (macOS Apple Silicon / Intel, Windows x64 / ARM64, Linux AppImage). The CLI runtime is embedded in the desktop app — there is no separate CLI to install.

Sign in with your Z.ai account and pick a Coding Plan (OAuth, no API keys needed):

> Z.AI Coding Plan: https://z.ai/manage-apikey/account

## 2. Create the MCP config file

ZCode has no auto-configuration — create `~/.zcode/cli/config.json` yourself. All MCP servers share a single `"mcp"` object in it; add the entries from the following steps into `mcp.servers`. Each step shows just the inner server entry, and a complete merged example is shown at the end of step 8.

```jsonc
{
  "mcp": {
    "servers": {
    }
  }
}
```

> **Config format rules:**
>
> - `"type"` is `"stdio"` for local servers and `"http"` (or `"sse"`) for remote ones.
> - `command` is a **string** and arguments go in an `args` array.
> - **No `{env:VAR}` expansion.** Header values must contain the literal token. Restrict the file: `chmod 600 ~/.zcode/cli/config.json`.
> - Remote servers that support OAuth can skip tokens entirely: enable OAuth on the server in **Settings → MCP** and complete the browser flow via its **Open authorization** button (HTTP/SSE only).
> - Stdio environment variables use `env`.
> - Servers are on by default; `"enabled": false` keeps an entry configured without connecting it.
> - Every configured server (user and workspace scope) auto-connects at session start — only open workspaces you trust.

## 3. Add GitHub MCP

Create a [GitHub Personal Access Token](https://github.com/settings/personal-access-tokens/new) with `repo`, `read:org`, and `workflow` scopes, then add to `mcp.servers` in `~/.zcode/cli/config.json` (paste the literal token — see the step 2 note on `{env:VAR}`):

```jsonc
"gh": {
  "type": "http",
  "url": "https://api.githubcopilot.com/mcp/",
  "headers": {
    "Authorization": "Bearer <YOUR_GITHUB_PAT>",
    "X-MCP-Toolsets": "context,issues,pull_requests,repos,actions",
    "X-MCP-Readonly": "true"
  }
}
```

> `X-MCP-Toolsets` limits registered toolsets to reduce context tokens. `X-MCP-Readonly` prevents accidental writes.
>
> https://github.com/github/github-mcp-server

## 4. Add W&B MCP

Get your key at [wandb.ai/authorize](https://wandb.ai/authorize), then add to `mcp.servers` in `~/.zcode/cli/config.json`:

```jsonc
"wandb": {
  "type": "http",
  "url": "https://mcp.withwandb.com/mcp",
  "enabled": false,
  "headers": {
    "Authorization": "Bearer <YOUR_WANDB_KEY>",
    "Accept": "application/json, text/event-stream"
  }
}
```

> Disabled by default: wandb has the largest tool catalog of these servers and ZCode loads connected servers' tools into every session. Enable on demand by removing the `"enabled"` line, then restart ZCode.

> https://github.com/wandb/wandb-mcp-server

## 5. Add Context7 MCP

Get your key at [context7.com/dashboard](https://context7.com/dashboard), then add to `mcp.servers` in `~/.zcode/cli/config.json`:

```jsonc
"context7": {
  "type": "http",
  "url": "https://mcp.context7.com/mcp",
  "headers": {
    "Authorization": "Bearer <YOUR_CONTEXT7_KEY>",
    "Accept": "application/json, text/event-stream"
  }
}
```

> Verified quirk: `resolve-library-id` requires **both** `libraryName` and `query` — passing either one alone fails validation.
>
> https://github.com/upstash/context7

## 6. Websearch and other built-in tools

ZCode bundles its own web and image tools — no MCP entries or API keys needed:

- **WebSearch / WebFetch** — built-in web search and URL fetching.
- **`web_reader`** — Z.ai's hosted URL-to-markdown reader MCP (`https://api.z.ai/api/mcp/web_reader/mcp`) with richer extraction than WebFetch — add it as a regular `http` server when required.

ZCode has no auto-provided MCP servers — context7 and gh_grep need the explicit entries from steps 5 and 7.

## 7. Add GitHub Code Search MCP

No auth required. Add to `mcp.servers` in `~/.zcode/cli/config.json`:

```jsonc
"gh_grep": {
  "type": "http",
  "url": "https://mcp.grep.app"
}
```

> https://grep.app

## 8. Add Hugging Face MCP

Create a read token at [huggingface.co/settings/tokens](https://huggingface.co/settings/tokens), then add to `mcp.servers` in `~/.zcode/cli/config.json` (paste the literal token — see the step 2 note on `{env:VAR}`):

```jsonc
"hf": {
  "type": "http",
  "url": "https://huggingface.co/mcp",
  "headers": {
    "Authorization": "Bearer <YOUR_HF_TOKEN>"
  }
}
```

> The hosted endpoint of the official Hugging Face MCP server — no local process needed. A read token is enough; toggle the exposed tools (Hub search/filesystem, Spaces, papers) at [huggingface.co/settings/mcp](https://huggingface.co/settings/mcp).
>
> https://github.com/huggingface/hf-mcp-server

After all MCP entries are added, the `"mcp"` object should look like:

```jsonc
"mcp": {
  "servers": {
    "gh": {
      "type": "http",
      "url": "https://api.githubcopilot.com/mcp/",
      "headers": {
        "Authorization": "Bearer <YOUR_GITHUB_PAT>",
        "X-MCP-Toolsets": "context,issues,pull_requests,repos,actions",
        "X-MCP-Readonly": "true"
      }
    },
    "wandb": {
      "type": "http",
      "url": "https://mcp.withwandb.com/mcp",
      "enabled": false,
      "headers": {
        "Authorization": "Bearer <YOUR_WANDB_KEY>",
        "Accept": "application/json, text/event-stream"
      }
    },
    "context7": {
      "type": "http",
      "url": "https://mcp.context7.com/mcp",
      "headers": {
        "Authorization": "Bearer <YOUR_CONTEXT7_KEY>",
        "Accept": "application/json, text/event-stream"
      }
    },
    "gh_grep": {
      "type": "http",
      "url": "https://mcp.grep.app"
    },
    "hf": {
      "type": "http",
      "url": "https://huggingface.co/mcp",
      "headers": {
        "Authorization": "Bearer <YOUR_HF_TOKEN>"
      }
    }
  }
}
```

> MCP servers connect at session start — after editing `config.json`, new entries take effect in new sessions (restart ZCode to be safe).

## 9. Add MCP usage guidance to AGENTS.md

ZCode reads `~/.zcode/AGENTS.md` as user-level instructions in every workspace, injected before the repo's own `AGENTS.md` (so a repo can narrow it). Add tool guidance so agents know when to use each MCP server, the order to prefer tools, and the workflow habits to follow:

```markdown
## MCP Tool Guidance

- **GitHub (`mcp__gh__*`):** Use for GitHub operations — listing/searching issues, PRs, repos, commits, code; reading PR diffs/files/reviews; checking CI status and logs. Prefer `mcp__gh__*` tools over raw `gh` CLI commands. Read-only mode is enabled.
- **GitHub Code Search (`mcp__gh_grep__*`):** Use to find real-world code examples across public GitHub repositories. Great for unfamiliar APIs, usage patterns, and implementation examples.
- **W&B (`mcp__wandb__*`):** Weights & Biases observability — runs, metrics, artifacts, Weave traces, evaluations, reports. Server disabled by default — enable on demand (step 4).
- **Context7 (`mcp__context7__*`):** Use to search up-to-date library documentation. Use `resolve-library-id` to find a library, then `query-docs` to fetch its docs.
- **Hugging Face (`mcp__hf__*`):** Use for Hub lookups — searching models, datasets, and Spaces, repo details, trending listings, and HF docs/papers.
- **WebSearch (built-in):** Use for current information and external research when library docs and local sources don't suffice.

### Tool selection order

1. Library/dependency internals → check `~/gitlocal/<name>` before any network search.
2. Library documentation → `context7`.
3. Real-world usage examples → `gh_grep`.
4. GitHub issues/PRs/CI → `gh`.
5. Hugging Face Hub (models, datasets, Spaces, papers) → `hf`.
6. Everything else current/external → WebSearch / WebFetch.

## Workflow Habits

- For big refactors or risky changes, stress-test the plan first (the `grilling`/`grill-me` skills exist for this).
```

## 10. Install mattpocock skills (grill-me, grilling)

> Requires Node.js ≥ 22. If needed: `brew install node` or `nvm install node` (see https://github.com/nvm-sh/nvm).

```bash
npx skills@latest add mattpocock/skills --yes --global -a zcode --skill "grill-me" --skill "grilling"
```

> https://github.com/mattpocock/skills

> `-a zcode` makes the CLI symlink its `~/.agents/skills/` copies into `~/.zcode/skills/` — ZCode scans that directory, not `~/.agents/`.

## 11. Install personal skills (zhtmike/skills)

```bash
mkdir -p ~/gitlocal ~/.zcode/skills
git clone https://github.com/zhtmike/skills ~/gitlocal/skills
ln -sfn ~/gitlocal/skills/code-review ~/.zcode/skills/code-review
ln -sfn ~/gitlocal/skills/coding-style ~/.zcode/skills/coding-style
```

> Symlinks keep a single source of truth: `git pull` in `~/gitlocal/skills` updates both skills everywhere. https://github.com/zhtmike/skills

## 12. Plugins

ZCode ships a plugin store (**Settings → Plugins**, Public/Personal segments; the Claude Code marketplace comes preloaded, and custom marketplaces can be added from GitHub/Git/npm/URL sources). Preinstalled and enabled by default:

- **document-skills** — docx, pdf, pptx, xlsx creation and analysis
- **skill-creator** — authoring and editing your own skills

Also available, unused: **android-emulator** / **ios-simulator** (mobile simulator device testing) and **restore-legacy-sessions**.

I disable the two automation plugins — they grant browser and desktop control:

- **browser-use** — control a browser from the agent
- **computer-use** — desktop computer-use control

Toggle them off in **Settings → Plugins**; the toggle writes to `~/.zcode/cli/config.json` (as a sibling of the `"mcp"` object):

```jsonc
"plugins": {
  "enabledPlugins": {
    "browser-use@zcode-plugins-official": false,
    "computer-use@zcode-plugins-official": false
  }
}
```

## 13. Model and subagent setup

The main model needs no configuration: ZCode runs Z.ai's GLM models through your Coding Plan and you pick the model in the app's model selector.

**Subagent overrides**: run the Explore subagent on the fast model (GLM-5.3-Flash) while the main conversation stays on GLM-5.3 — cheap recon, strong main loop. In **Settings → Subagents**, set:

| Subagent | Model |
|---|---|
| Explore | GLM-5.3-Flash |

Stored in `~/.zcode/v2/agents-state.json`:

```json
{
  "builtInModelOverrides": {
    "Explore": "custom:builtin%3Azai-coding-plan:GLM-5.3-Flash"
  },
  "builtInThoughtLevelOverrides": {},
  "disabledAgentIds": []
}
```

> Internal state file (undocumented — the Settings UI is the supported path). The app adds its own keys alongside (e.g. `builtInModelSelectionOverrides` mirroring the same override in selection form) — leave them alone. Custom subagents (Beta) are separate: `~/.zcode/agents/<name>.md` markdown files with `model`/`thoughtLevel`/`tools` frontmatter.

## 14. Desktop preferences

Enable **auto-update** in Settings so stable releases download and install automatically (keep preview updates off). Everything else works well at its defaults.

## 15. Verify

Restart ZCode, then check MCPs, skills, and tool routing:

1. **Settings → MCP** — all five servers (`gh`, `wandb`, `context7`, `gh_grep`, `hf`) should be listed: four connected, `wandb` disabled by default (step 4). If a server shows no tools, re-check the entry's field names and values.
2. Type `/` in the input box — your skills (`grill-me`, `grilling`, `code-review`, `coding-style`) should be listed.
3. Ask the agent to look up a library's current API — it should route to `context7` first (per step 9 guidance).

## 16. Local state and scope

- **Settings are local-only.** Your Z.ai account covers auth and billing, not configuration. Nothing is synced between machines. The files that matter: `~/.zcode/AGENTS.md`, `~/.zcode/cli/config.json`, `~/.zcode/v2/config.json` (model/provider selection), `~/.zcode/v2/agents-state.json` (subagent overrides), `~/.agents/skills/` (+ `.skill-lock.json`), and optionally `~/.zcode/v2/setting.json` (desktop preferences). Manage them in dotfiles or a sync script across machines; keep `config.json` private (it holds tokens).
- **Secrets are stored in plaintext.** ZCode does not expand `{env:VAR}` in MCP headers, so tokens sit directly in `~/.zcode/cli/config.json`, and provider API keys in `~/.zcode/v2/config.json`. Restrict both with `chmod 600` and rotate tokens if either ever leaks; servers that support OAuth avoid the token entirely (step 2).
- **Scope and precedence.** User scope overrides workspace scope for same-named MCP servers and skills. Workspace-level MCP config (`<repo>/.zcode/config.json`) auto-connects, so only open repos you trust.
- **No LSP execution.** Plugin `lspServers` are recorded but never executed — there is no LSP install step.

## References

- [ZCode](https://zcode.z.ai) — [Install](https://zcode.z.ai/en/docs/install) · [Docs](https://zcode.z.ai/en/docs/welcome)
- [Z.AI Coding Plan](https://z.ai/manage-apikey/account)
- [GitHub MCP Server](https://github.com/github/github-mcp-server) · [W&B MCP Server](https://github.com/wandb/wandb-mcp-server) · [Context7](https://github.com/upstash/context7) · [grep.app MCP](https://grep.app) · [Hugging Face MCP Server](https://github.com/huggingface/hf-mcp-server)
- [skills CLI](https://github.com/vercel-labs/skills) · [mattpocock/skills](https://github.com/mattpocock/skills) · [zhtmike/skills](https://github.com/zhtmike/skills)