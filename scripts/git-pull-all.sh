#!/usr/bin/env bash
# git-pull-all.sh — checkout the default branch and pull every repo to latest.
# Default branch is read from the remote HEAD (main/master/dev/...).
# Pulls from `official` remote if present, otherwise from `origin`.
#
# Usage: ./git-pull-all.sh [base_dir]   (default: ~/gitlocal)

set -u

# Fail fast instead of hanging on any credential/prompt
export GIT_TERMINAL_PROMPT=0

BASE_DIR="${1:-$HOME/gitlocal}"

# Colors
RED=$'\033[0;31m'; GREEN=$'\033[0;32m'; YELLOW=$'\033[0;33m'; CYAN=$'\033[0;36m'; RESET=$'\033[0m'

ok=0; skipped=0; failed=0

for repo in "$BASE_DIR"/*/; do
    repo="${repo%/}"
    name=$(basename "$repo")

    # Only git repos
    [ -e "$repo/.git" ] || continue

    printf '%s==> %s%s\n' "$CYAN" "$name" "$RESET"

    # Skip repos with local modifications (checkout/pull could clobber them)
    if ! git -C "$repo" diff --quiet HEAD 2>/dev/null; then
        printf '    %sskip: dirty working tree%s\n' "$YELLOW" "$RESET"
        skipped=$((skipped+1))
        continue
    fi

    # Pick remote: official if it exists, else origin
    if git -C "$repo" remote | grep -qx official; then
        remote=official
    elif git -C "$repo" remote | grep -qx origin; then
        remote=origin
    else
        printf '    %sskip: no official/origin remote%s\n' "$YELLOW" "$RESET"
        skipped=$((skipped+1))
        continue
    fi

    # Pick branch: the remote's default (HEAD) branch, e.g. main/master/dev.
    # Learn it from the remote if not cached locally, then fall back to
    # whatever exists locally among main/master/dev.
    branch=$(git -C "$repo" symbolic-ref --short "refs/remotes/$remote/HEAD" 2>/dev/null | sed "s|^$remote/||")
    if [ -z "$branch" ]; then
        git -C "$repo" remote set-head "$remote" --auto -q >/dev/null 2>&1
        branch=$(git -C "$repo" symbolic-ref --short "refs/remotes/$remote/HEAD" 2>/dev/null | sed "s|^$remote/||")
    fi
    if [ -z "$branch" ]; then
        for b in main master dev; do
            if git -C "$repo" show-ref --verify --quiet "refs/heads/$b"; then
                branch=$b
                break
            fi
        done
    fi
    if [ -z "$branch" ]; then
        printf '    %sskip: no default branch (main/master/dev)%s\n' "$YELLOW" "$RESET"
        skipped=$((skipped+1))
        continue
    fi

    if git -C "$repo" fetch "$remote" --prune --tags --force -q >/dev/null 2>&1 &&
       git -C "$repo" checkout "$branch" >/dev/null 2>&1 &&
       git -C "$repo" pull "$remote" "$branch" >/dev/null 2>&1; then
        printf '    %sok: %s <- %s/%s%s\n' "$GREEN" "$branch" "$remote" "$branch" "$RESET"
        ok=$((ok+1))
    else
        printf '    %sFAIL: fetch/checkout/pull %s from %s%s\n' "$RED" "$branch" "$remote" "$RESET"
        git -C "$repo" fetch "$remote" --prune --tags --force 2>&1 | sed 's/^/      /'
        git -C "$repo" checkout "$branch" 2>&1 | sed 's/^/      /'
        git -C "$repo" pull "$remote" "$branch" 2>&1 | sed 's/^/      /'
        failed=$((failed+1))
    fi
done

printf '\n%sSummary:%s ok=%d skipped=%d failed=%d\n' "$CYAN" "$RESET" "$ok" "$skipped" "$failed"
[ "$failed" -eq 0 ]
