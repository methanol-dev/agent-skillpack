#!/usr/bin/env bash
# Install the agent skillpack (.agent + CLAUDE.md) into a project.
# macOS / Linux / WSL. Works from a local clone OR straight from the internet.
#
# Remote one-liner (run from the ROOT of the target project):
#   curl -fsSL https://raw.githubusercontent.com/methanol-dev/agent-skillpack/main/install.sh | bash
#
# With options when piped:
#   curl -fsSL .../install.sh | bash -s -- --force
#   curl -fsSL .../install.sh | bash -s -- --project ~/code/app
#   curl -fsSL .../install.sh | bash -s -- --update
#
# What it does:
#   1. Ensures the pack exists in a central dir ($HOME/.agent-skillpack):
#      clone on first run, `git pull --ff-only` afterwards.
#   2. .agent    : symlink from the project to the central pack.
#   3. CLAUDE.md : copied into the project (kept unless --force).
#   4. .gitignore: adds '.agent/' and 'ERRORS.md' if missing.
#
# Env overrides: SKILLPACK_PROJECT, SKILLPACK_FORCE=1, SKILLPACK_REPO, SKILLPACK_DIR

set -euo pipefail

PROJECT="${SKILLPACK_PROJECT:-$PWD}"
FORCE="${SKILLPACK_FORCE:-0}"
UPDATE=0
REPO="${SKILLPACK_REPO:-https://github.com/methanol-dev/agent-skillpack.git}"
PACK_DIR="${SKILLPACK_DIR:-$HOME/.agent-skillpack}"

while [ $# -gt 0 ]; do
  case "$1" in
    -p|--project) PROJECT="$2"; shift 2 ;;
    -f|--force)   FORCE=1; shift ;;
    -u|--update)  UPDATE=1; shift ;;
    --repo)       REPO="$2"; shift 2 ;;
    --pack-dir)   PACK_DIR="$2"; shift 2 ;;
    -h|--help)    sed -n '2,20p' "$0" 2>/dev/null || true; exit 0 ;;
    *) echo "Unknown option: $1" >&2; exit 2 ;;
  esac
done

step() { printf '[%-11s] %s\n' "$1" "$2"; }

# Create a directory link. On Git Bash / MSYS, `ln -s` silently COPIES the
# directory (42MB) unless native symlinks are enabled, so use an NTFS junction
# there (no admin rights needed). Bash still sees a junction as a symlink (-L).
link_dir() { # $1 = link path, $2 = target path
  case "${OSTYPE:-}" in
    msys*|cygwin*)
      MSYS_NO_PATHCONV=1 cmd /c mklink /J "$(cygpath -w "$1")" "$(cygpath -w "$2")" >/dev/null ;;
    *) ln -s "$2" "$1" ;;
  esac
}

# ---------------------------------------------------------------------------
# 0) Resolve pack dir: local clone (script next to .agent) or central dir.
# ---------------------------------------------------------------------------
SCRIPT_DIR=""
if [ -n "${BASH_SOURCE[0]:-}" ] && [ -f "${BASH_SOURCE[0]}" ]; then
  SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
fi

if [ -n "$SCRIPT_DIR" ] && [ -d "$SCRIPT_DIR/.agent" ]; then
  PACK="$SCRIPT_DIR"; MODE="local"
else
  PACK="$PACK_DIR"; MODE="remote"
fi

echo "==> Mode    : $MODE"
echo "==> Pack    : $PACK"

# ---------------------------------------------------------------------------
# 1) Ensure the pack exists and is fresh
# ---------------------------------------------------------------------------
if [ "$MODE" = "remote" ] || [ "$UPDATE" = "1" ]; then
  command -v git >/dev/null 2>&1 || { echo "git is required but not found in PATH." >&2; exit 1; }

  if [ -d "$PACK/.git" ]; then
    step "pack" "updating ($REPO) ..."
    if ! git -C "$PACK" pull --ff-only --quiet; then
      step "pack" "WARN: git pull failed, using the existing copy."
    else
      step "pack" "up to date."
    fi
  elif [ -e "$PACK" ]; then
    echo "$PACK exists but is not a git clone. Remove it or set --pack-dir elsewhere." >&2; exit 1
  else
    step "pack" "cloning $REPO ..."
    git clone --depth 1 --quiet "$REPO" "$PACK"
    step "pack" "cloned."
  fi
fi

if [ "$UPDATE" = "1" ]; then
  echo; echo "DONE. Pack updated. Projects linked via symlink already see the changes."; exit 0
fi

[ -d "$PACK/.agent" ] || { echo "Pack at $PACK has no .agent directory. Corrupted clone?" >&2; exit 1; }

# ---------------------------------------------------------------------------
# 2) Target project
# ---------------------------------------------------------------------------
PROJECT="$(cd "$PROJECT" && pwd)"
echo "==> Project : $PROJECT"
echo

# ---------------------------------------------------------------------------
# 3) .agent via symlink
# ---------------------------------------------------------------------------
LINK="$PROJECT/.agent"
SRC="$PACK/.agent"
if [ -L "$LINK" ]; then
  if [ "$FORCE" = "1" ]; then
    # rm on a symlink/junction removes only the link, never the target contents.
    rm "$LINK"; link_dir "$LINK" "$SRC"; step ".agent" "link re-created -> $SRC"
  else
    step ".agent" "link exists -> $(readlink "$LINK"). Use --force to re-point."
  fi
elif [ -e "$LINK" ]; then
  step ".agent" "real directory exists, left untouched."
else
  link_dir "$LINK" "$SRC"; step ".agent" "link -> $SRC"
fi

# ---------------------------------------------------------------------------
# 4) CLAUDE.md
# ---------------------------------------------------------------------------
if [ -f "$PROJECT/CLAUDE.md" ] && [ "$FORCE" != "1" ]; then
  step "CLAUDE.md" "exists, kept (use --force to overwrite)."
else
  cp "$PACK/CLAUDE.md" "$PROJECT/CLAUDE.md"; step "CLAUDE.md" "copied."
fi

# ---------------------------------------------------------------------------
# 5) .gitignore
# ---------------------------------------------------------------------------
GI="$PROJECT/.gitignore"
ADDED=()
for entry in ".agent/" "ERRORS.md"; do
  if ! { [ -f "$GI" ] && grep -qxF "$entry" "$GI"; }; then ADDED+=("$entry"); fi
done
if [ ${#ADDED[@]} -gt 0 ]; then
  { echo; echo "# Skillpack (local tooling, not committed)"; printf '%s\n' "${ADDED[@]}"; } >> "$GI"
  step ".gitignore" "added: ${ADDED[*]}"
else
  step ".gitignore" "already set, skip."
fi

echo; echo "DONE. Skillpack installed into the project."
