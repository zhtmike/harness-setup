# Machine profiles

One payload doc per machine — the machine-scoped agent guidance that every harness on that machine should carry. The payload is harness-agnostic wording and loads into agent context verbatim, so install notes and local state live here, never in the payload.

## MacBook (macOS) — [macbook.md](macbook.md)

pi and OpenCode read `AGENTS.md` from the working directory's ancestors (pi up to the filesystem root, OpenCode up to and including `$HOME`; both merge every level found), so one symlink covers both for any workspace under `$HOME`:

```bash
ln -sfn ~/gitlocal/harness-setup/machines/macbook.md ~/AGENTS.md
```

Non-default local state (default values are never recorded):

- pi `~/.pi/agent/settings.json` carries `hideThinkingBlock: true` beyond the guide payload.
- `~/.zshrc` wraps `pi`: bare `pi --list-models` keeps only the `zai` provider's rows (`awk 'NR==1 || $1=="zai"'` over the full listing) — pi ships a built-in huggingface provider (HF Router) whose ~90 catalog rows print regardless of auth, and the fuzzy search cannot exclude them (`zai` matches `zai-org/*`). `command pi --list-models` or any explicit search arg bypasses.
- `~/.ssh/config` routes `github.com` through `ssh.github.com:443` — this network blocks ssh port 22, so every git push fails without the reroute.

## Support scripts

`scripts/git-pull-all.sh` pulls every git repo directly under a base dir (default `~/gitlocal/`) to its remote default branch, preferring the `official` remote over `origin` and skipping dirty trees. Install so the canonical invocation path keeps working:

```bash
ln -sfn ~/gitlocal/harness-setup/scripts/git-pull-all.sh ~/gitlocal/git-pull-all.sh
```
