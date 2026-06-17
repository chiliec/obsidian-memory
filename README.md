# obsidian-memory

A Claude Code plugin that gives every project a memory. At the **end** of each
session it writes a concise `SUMMARY.md` and a per-session journal note into your
Obsidian vault; at the **start** of the next session it loads that `SUMMARY.md`
back in as context — so a fresh session already knows where you left off.

## How it works

- **SessionEnd** (async): a small Claude Haiku call reads the session transcript
  and writes two files into `<vault>/<project>/` — a living `SUMMARY.md` and an
  immutable `sessions/<timestamp>.md` note. Wikilinks, a rolling "Recent
  sessions" list, and a size cap are maintained automatically.
- **SessionStart**: that project's `SUMMARY.md` is injected as context.
- A user-authored `MEMORY.md` in the project folder, if present, is treated as
  authoritative ground truth and is never modified.

## Install (plugin)

```
/plugin marketplace add chiliec/obsidian-memory
/plugin install obsidian-memory
/obsidian-memory-setup
```

`/obsidian-memory-setup` asks for your vault's Projects-root path and writes it
to `~/.claude/settings.json`. Done.

## Install (manual, no plugin system)

```
git clone https://github.com/chiliec/obsidian-memory
cd obsidian-memory && ./install.sh
```

Then paste the printed snippet into `~/.claude/settings.json`.

## Requirements

- `jq` on PATH.
- The `claude` CLI on PATH (for session synthesis). Without it, the load side
  still works; saves are skipped and logged.

## Cost

Each session end (≥4 meaningful turns) spends one small Claude Haiku call. New or
trivial sessions are skipped. Synthesis for a given session+turn-count runs once
(deduplicated).

## Configuration

| Variable | Purpose |
| --- | --- |
| `OBSIDIAN_MEMORY_VAULT` | Absolute path to the vault Projects root (required). |
| `OBSIDIAN_MEMORY_TEMPLATES` | Override the bundled templates directory (optional). |

To retire a single project, set its `SUMMARY.md` `**Status**:` to `archived` —
the plugin then leaves it untouched.

## Security

The SessionEnd summarizer is a child `claude` process that receives your
transcript as input — which is **untrusted** (it can contain text you pasted or
browsed). To contain prompt-injection, that child runs **without**
`--dangerously-skip-permissions`: it uses `--permission-mode dontAsk` with
`--allowedTools "Write"` only, and explicitly denies `Bash`, `Read`, `Edit`,
`WebFetch`, `WebSearch`, `Task`, and `Agent`. This removes code-execution and
network-egress as injection vectors. A residual remains — a crafted transcript
could in principle steer a `Write` to an unintended local path — so the
summarizer prompt also marks all embedded content as data, not instructions.
Treat your vault as you would any local notes directory.

## License

MIT
