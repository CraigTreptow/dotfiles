#!/usr/bin/env bash
# Claude Code Stop hook: run standardrb and Sandi Metz's RuboCop limits on changed Ruby files.
# Blocks Claude from stopping while violations remain; on the retry (stop_hook_active), lets it
# stop and shows the remaining violations to the user instead of looping forever.
set -euo pipefail

input=$(cat)
cwd=$(jq -r '.cwd // empty' <<<"$input")
retrying=$(jq -r '.stop_hook_active // false' <<<"$input")
metz_config="${METZ_RUBOCOP_CONFIG:-$HOME/.claude/metz-rubocop.yml}"

cd "${cwd:-.}" 2>/dev/null || exit 0
root=$(git rev-parse --show-toplevel 2>/dev/null) || exit 0
cd "$root"
grep -q '^    standard ' Gemfile.lock 2>/dev/null || exit 0

files=()
while IFS= read -r -d '' file; do
  case "$file" in
    *.rb | Gemfile | Rakefile | */Gemfile | */Rakefile) [ -f "$file" ] && files+=("$file") ;;
  esac
done < <(
  git diff --name-only -z HEAD 2>/dev/null || true # no HEAD yet in a fresh repo
  git ls-files -z --others --exclude-standard
)
[ "${#files[@]}" -eq 0 ] && exit 0

output=""
tool_errors=""
# Exit 1 = offenses found. Any other non-zero (bundler, missing config, crash) is an
# environment problem Claude can't fix by editing code, so it warns instead of blocking.
run_check() { # $1 = label, rest = command
  local label=$1 result status=0
  shift
  result=$("$@" 2>&1) || status=$?
  case "$status" in
    0) ;;
    1) output+="== $label =="$'\n'"$result"$'\n' ;;
    *) tool_errors+="== $label (exit $status) =="$'\n'"$result"$'\n' ;;
  esac
}
run_check standardrb bundle exec standardrb --format simple "${files[@]}"
run_check "Metz limits (rubocop)" \
  bundle exec rubocop -c "$metz_config" --force-exclusion --format simple "${files[@]}"

if [ -n "$tool_errors" ] && [ -z "$output" ]; then
  jq -n --arg msg "Ruby quality check could not run:"$'\n'"$tool_errors" '{systemMessage: $msg}'
  exit 0
fi
[ -z "$output" ] && exit 0
output+="$tool_errors"

if [ "$retrying" = "true" ]; then
  jq -n --arg msg "Ruby quality check still failing:"$'\n'"$output" '{systemMessage: $msg}'
else
  reason="Ruby quality check failed on changed files. Fix every violation (run \`bundle exec standardrb --fix\` first, then fix the rest by hand; for a Metz limit you intend to keep, follow the rule-break protocol in ~/.claude/RUBY_RAILS_STYLE.md):"$'\n'"$output"
  jq -n --arg reason "$reason" '{decision: "block", reason: $reason}'
fi
