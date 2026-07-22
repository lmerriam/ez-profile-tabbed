#!/usr/bin/env bash
#
# publish.sh — publish the current prototypes to the live GitHub Pages site.
#
# What it does:
#   • Snapshots the site files (landing index.html + every variation folder)
#     AS THEY EXIST RIGHT NOW in your working directory — committed or not.
#   • Copies that snapshot onto the `gh-pages` branch and pushes it.
#   • GitHub Pages serves `gh-pages`, so this is the ONLY thing viewers ever see.
#
# What it does NOT do:
#   • It does not touch your current branch, your local edits, or your history on main.
#   • Nothing goes live until you run this. Work locally as long as you like.
#
# Usage:
#   ./publish.sh            # publish current state
#   ./publish.sh "message"  # publish with a custom deploy note
#
set -euo pipefail

BRANCH="gh-pages"
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$ROOT"

# --- sanity checks ---------------------------------------------------------
if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  echo "✖ Not a git repository. Run this from the repo root." >&2
  exit 1
fi
if ! git remote get-url origin >/dev/null 2>&1; then
  echo "✖ No 'origin' remote. Create/link the GitHub repo first." >&2
  exit 1
fi
if [ ! -f "index.html" ]; then
  echo "✖ Expected a landing index.html here." >&2
  exit 1
fi

MSG="${1:-Publish $(date '+%Y-%m-%d %H:%M')}"

# --- warn (don't block) if there are uncommitted changes -------------------
if ! git diff --quiet || ! git diff --cached --quiet; then
  echo "ℹ Publishing your CURRENT working files (including uncommitted edits)."
fi

# --- stage the site into a temp dir ---------------------------------------
# Publish the landing page + every variation folder. Repo-management files
# (README, publish.sh, .gitignore, .git) are intentionally left out.
STAGE="$(mktemp -d)"
trap 'rm -rf "$STAGE"; git worktree prune >/dev/null 2>&1 || true' EXIT

EXCLUDES=(".git" ".gitignore" "README.md" "publish.sh" ".DS_Store")
for entry in * .[!.]*; do
  [ -e "$entry" ] || continue
  skip=false
  for ex in "${EXCLUDES[@]}"; do [ "$entry" = "$ex" ] && skip=true; done
  $skip && continue
  cp -R "$entry" "$STAGE/"
done
touch "$STAGE/.nojekyll"   # stop GitHub Pages from running Jekyll

# --- publish via a detached worktree on gh-pages ---------------------------
WORKTREE="$(mktemp -d)"

# Make sure a gh-pages branch exists (orphan on first run).
if git show-ref --verify --quiet "refs/heads/$BRANCH"; then
  git worktree add --quiet "$WORKTREE" "$BRANCH"
else
  git worktree add --quiet --detach "$WORKTREE"
  git -C "$WORKTREE" checkout --orphan "$BRANCH"
  git -C "$WORKTREE" rm -rf --quiet . >/dev/null 2>&1 || true
fi

# Replace contents with the fresh snapshot.
find "$WORKTREE" -mindepth 1 -maxdepth 1 ! -name '.git' -exec rm -rf {} +
cp -R "$STAGE"/. "$WORKTREE"/

git -C "$WORKTREE" add -A
if git -C "$WORKTREE" diff --cached --quiet; then
  echo "✓ No changes to publish — live site already up to date."
else
  git -C "$WORKTREE" commit --quiet -m "$MSG"
  git -C "$WORKTREE" push --quiet origin "$BRANCH"
  echo "✓ Published: $MSG"
fi

# --- cleanup ---------------------------------------------------------------
git worktree remove --force "$WORKTREE" >/dev/null 2>&1 || true
rm -rf "$WORKTREE"

# --- report the live URL ---------------------------------------------------
ORIGIN_URL="$(git remote get-url origin)"
SLUG="$(echo "$ORIGIN_URL" | sed -E 's#(git@github.com:|https://github.com/)##; s#\.git$##')"
USER="${SLUG%%/*}"
REPO="${SLUG##*/}"
echo "→ Live at: https://${USER}.github.io/${REPO}/"
