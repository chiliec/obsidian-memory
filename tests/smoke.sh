#!/usr/bin/env bash
# Portability smoke tests for obsidian-memory. Run from anywhere.
set -u
REPO="$(cd "$(dirname "$0")/.." && pwd)"
PLUGIN="$REPO/plugins/obsidian-memory"
FAIL=0
pass() { echo "PASS: $1"; }
fail() { echo "FAIL: $1"; FAIL=1; }

# 1. No personal strings anywhere in the shipped plugin (the tests/ dir itself
#    legitimately contains these patterns as scan strings, so it's excluded).
if grep -rnE '/Users/babin|Develop/Pet/Journal|linear|breadcrumb' "$REPO" \
     --include='*.sh' --include='*.json' --include='*.md' \
     --exclude-dir=.git --exclude-dir=tests >/dev/null 2>&1; then
  fail "personal/Linear strings present"
  grep -rnE '/Users/babin|Develop/Pet/Journal|linear|breadcrumb' "$REPO" \
     --include='*.sh' --include='*.json' --include='*.md' --exclude-dir=.git --exclude-dir=tests
else
  pass "no personal/Linear strings"
fi

# 2. Shell syntax.
for s in "$PLUGIN/hooks/obsidian-load.sh" "$PLUGIN/hooks/obsidian-save.sh" "$REPO/install.sh"; do
  bash -n "$s" 2>/dev/null && pass "syntax $s" || fail "syntax $s"
done

# 3. JSON validity.
for j in "$REPO/.claude-plugin/marketplace.json" "$PLUGIN/plugin.json" "$PLUGIN/hooks/hooks.json"; do
  jq empty "$j" 2>/dev/null && pass "json $j" || fail "json $j"
done

# 4. Load hook no-ops when vault unset.
OUT=$(unset OBSIDIAN_MEMORY_VAULT; echo '{"cwd":"/tmp/x"}' | "$PLUGIN/hooks/obsidian-load.sh")
[ -z "$OUT" ] && pass "load no-op (unset vault)" || fail "load no-op (unset vault)"

# 5. Load hook emits context when SUMMARY present.
TMPV=$(mktemp -d); mkdir -p "$TMPV/demo"; printf 'hello-marker' > "$TMPV/demo/SUMMARY.md"
OUT=$(OBSIDIAN_MEMORY_VAULT="$TMPV" sh -c 'echo "{\"cwd\":\"/a/demo\"}" | "'"$PLUGIN"'/hooks/obsidian-load.sh"' | jq -r '.hookSpecificOutput.additionalContext' 2>/dev/null)
echo "$OUT" | grep -q 'hello-marker' && pass "load emits SUMMARY" || fail "load emits SUMMARY"
rm -rf "$TMPV"

# 6. Save hook no-ops when vault unset.
RC=$(unset OBSIDIAN_MEMORY_VAULT; echo '{"session_id":"x","cwd":"/tmp/x"}' | "$PLUGIN/hooks/obsidian-save.sh"; echo $?)
[ "$RC" = "0" ] && pass "save no-op (unset vault)" || fail "save no-op (unset vault)"

echo
[ "$FAIL" = "0" ] && echo "ALL SMOKE TESTS PASSED" || { echo "SOME TESTS FAILED"; exit 1; }
