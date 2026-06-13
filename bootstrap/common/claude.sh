#!/usr/bin/env bash
# Link version-controlled Claude Code config from conf.d into ~/.claude.
#
# ~/.claude itself is NOT a symlink: Claude Code writes runtime state there
# (projects/, plugins/, remote/, ...). We only symlink the pieces we track in
# conf.d, leaving the rest of ~/.claude alone. update_links can't do this — it
# is basename-only and would link to ~/.skills instead of ~/.claude/skills.

mkdir -p ~/.claude

link_into_claude() {
    src=$1
    dst=~/.claude/$(basename "$src")
    # Back up a real (non-symlink) file/dir before we replace it; leave an
    # already-correct symlink to be recreated idempotently below.
    if [ -e "$dst" ] && [ ! -L "$dst" ]; then
        mv -f "$dst" "$dst.bak"
    fi
    ln -sfn "$src" "$dst"
}

link_into_claude ~/conf.d/claude/skills
link_into_claude ~/conf.d/claude/statusline-command.sh
