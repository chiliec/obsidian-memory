---
description: Configure obsidian-memory — set the vault path and verify dependencies.
---

You are configuring the **obsidian-memory** plugin for this user. Work through these steps in order, one at a time, and report results concisely.

1. **Preflight dependencies.** Run `command -v jq` and `command -v claude`.
   - If `jq` is missing, tell the user to install it (`brew install jq` on macOS, `apt-get install jq` on Debian/Ubuntu) and STOP — configuration cannot proceed without it.
   - If `claude` is missing from PATH, warn that automatic session synthesis will be skipped until the `claude` CLI is on PATH, but continue (the load hook still works).

2. **Determine the vault path.** Ask the user for the absolute path to their Obsidian vault's **Projects root** — the directory that will contain one folder per project (each holding its own `SUMMARY.md` and `sessions/`). Show an example: `~/Obsidian/Projects` or `~/Develop/Journal/Projects`.
   - Expand `~` to `$HOME`.
   - If the directory does not exist, offer to create it with `mkdir -p`. Only create it after the user confirms.

3. **Write the env var into `~/.claude/settings.json`.** Read the file (create `{}` if absent). Merge `OBSIDIAN_MEMORY_VAULT` into the top-level `env` object without disturbing any other keys. Use this jq transform, substituting the confirmed absolute path for `<PATH>`:

   ```bash
   SETTINGS="$HOME/.claude/settings.json"
   [ -f "$SETTINGS" ] || echo '{}' > "$SETTINGS"
   tmp=$(mktemp)
   jq --arg v "<PATH>" '.env = (.env // {}) | .env.OBSIDIAN_MEMORY_VAULT = $v' "$SETTINGS" > "$tmp" && mv "$tmp" "$SETTINGS"
   ```

   Then show the user the resulting `env` block so they can confirm it merged cleanly.

4. **Explain what happens next.** Tell the user, in two or three lines:
   - At the **end** of each session (≥4 meaningful turns) the plugin spends a small **Claude Haiku** synthesis call to write/refresh `SUMMARY.md` and a per-session note in the vault. This costs a small amount of tokens per session.
   - At the **start** of each session, that project's `SUMMARY.md` is injected as context automatically.
   - To disable temporarily, remove `OBSIDIAN_MEMORY_VAULT` from `~/.claude/settings.json` `env` (or uninstall the plugin). To retire a single project, set its SUMMARY.md `**Status**:` to `archived`.

5. **Confirm done.** Print the final configured vault path and remind them the change takes effect on the next session start.

This command is idempotent — re-running it just updates the path in place.
