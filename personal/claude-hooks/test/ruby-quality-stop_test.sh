#!/usr/bin/env bash
# Tests for ruby-quality-stop.sh. Run: bash personal/claude-hooks/test/ruby-quality-stop_test.sh
set -uo pipefail

HOOK="$(cd "$(dirname "$0")/.." && pwd)/ruby-quality-stop.sh"
FAILURES=0

TMP_DIRS=()
trap 'rm -rf "${TMP_DIRS[@]}"' EXIT

setup() {
  TMP=$(mktemp -d)
  TMP_DIRS+=("$TMP")
  REPO="$TMP/repo"
  mkdir -p "$REPO" "$TMP/bin"
  cat > "$TMP/bin/bundle" <<'FAKE'
#!/usr/bin/env bash
for arg in "$@"; do printf '%s\n' "$arg"; done >> "$FAKE_LOG"
echo "--" >> "$FAKE_LOG"
printf '%s' "${FAKE_BUNDLE_OUT:-}"
exit "${FAKE_BUNDLE_EXIT:-0}"
FAKE
  chmod +x "$TMP/bin/bundle"
  export FAKE_LOG="$TMP/bundle.log" FAKE_BUNDLE_EXIT=0 FAKE_BUNDLE_OUT=""
  export METZ_RUBOCOP_CONFIG="$TMP/metz.yml"
  git -C "$REPO" init -q
  git -C "$REPO" config user.email t@example.com
  git -C "$REPO" config user.name test
  printf 'GEM\n  specs:\n    standard (1.0.0)\n' > "$REPO/Gemfile.lock"
  mkdir -p "$REPO/app" "$REPO/lib"
  echo 'puts 1' > "$REPO/app/a.rb"
  echo '# readme' > "$REPO/README.md"
  git -C "$REPO" add -A && git -C "$REPO" commit -qm base
}

run_hook() { # $1 = cwd, $2 = stop_hook_active
  printf '{"cwd":"%s","stop_hook_active":%s}' "$1" "${2:-false}" |
    PATH="$TMP/bin:$PATH" bash "$HOOK"
}

check() { # $1 = name, $2 = condition result (0 = pass)
  if [ "$2" -eq 0 ]; then echo "PASS $1"; else echo "FAIL $1"; FAILURES=$((FAILURES + 1)); fi
}

test_outside_git_repo_is_silent() {
  setup; mkdir "$TMP/plain"
  out=$(run_hook "$TMP/plain"); code=$?
  [ -z "$out" ] && [ "$code" -eq 0 ]; check "${FUNCNAME[0]}" $?
}

test_no_standard_in_lockfile_is_silent() {
  setup
  printf 'GEM\n  specs:\n    rake (13.0)\n' > "$REPO/Gemfile.lock"
  echo 'puts 2' > "$REPO/app/a.rb"
  out=$(run_hook "$REPO")
  [ -z "$out" ] && [ ! -e "$FAKE_LOG" ]; check "${FUNCNAME[0]}" $?
}

test_no_changed_ruby_files_is_silent() {
  setup
  echo '# changed' > "$REPO/README.md"
  out=$(run_hook "$REPO")
  [ -z "$out" ] && [ ! -e "$FAKE_LOG" ]; check "${FUNCNAME[0]}" $?
}

test_clean_files_are_silent() {
  setup
  echo 'puts 2' > "$REPO/app/a.rb"
  out=$(run_hook "$REPO")
  [ -z "$out" ] &&
    grep -qx 'standardrb' "$FAKE_LOG" &&
    grep -qx 'rubocop' "$FAKE_LOG" &&
    grep -qx -- "$METZ_RUBOCOP_CONFIG" "$FAKE_LOG" &&
    grep -qx 'app/a.rb' "$FAKE_LOG"
  check "${FUNCNAME[0]}" $?
}

test_violations_block() {
  setup
  echo 'puts 2' > "$REPO/app/a.rb"
  export FAKE_BUNDLE_EXIT=1 FAKE_BUNDLE_OUT='app/a.rb:1:1: C: Metrics/MethodLength'
  out=$(run_hook "$REPO")
  [ "$(jq -r .decision <<<"$out")" = block ] &&
    jq -r .reason <<<"$out" | grep -q 'Metrics/MethodLength'
  check "${FUNCNAME[0]}" $?
}

test_stop_hook_active_allows_stop() {
  setup
  echo 'puts 2' > "$REPO/app/a.rb"
  export FAKE_BUNDLE_EXIT=1 FAKE_BUNDLE_OUT='app/a.rb:1:1: C: Metrics/MethodLength'
  out=$(run_hook "$REPO" true)
  [ "$(jq -r '.decision // "none"' <<<"$out")" = none ] &&
    jq -r .systemMessage <<<"$out" | grep -q 'Metrics/MethodLength'
  check "${FUNCNAME[0]}" $?
}

test_includes_untracked_and_staged_ignores_deleted() {
  setup
  echo 'x' > "$REPO/lib/gone.rb"; git -C "$REPO" add -A; git -C "$REPO" commit -qm gone
  rm "$REPO/lib/gone.rb"
  echo 'x' > "$REPO/lib/new.rb"
  echo 'x' > "$REPO/lib/staged.rb"; git -C "$REPO" add lib/staged.rb
  run_hook "$REPO" >/dev/null
  grep -qx 'lib/new.rb' "$FAKE_LOG" &&
    grep -qx 'lib/staged.rb' "$FAKE_LOG" &&
    ! grep -q 'gone.rb' "$FAKE_LOG"
  check "${FUNCNAME[0]}" $?
}

test_gemfile_and_rakefile_included_and_space_in_name() {
  setup
  echo 'source "x"' > "$REPO/Gemfile"
  echo 'task :x' > "$REPO/Rakefile"
  echo 'x' > "$REPO/app/my file.rb"
  run_hook "$REPO" >/dev/null
  grep -qx 'Gemfile' "$FAKE_LOG" &&
    grep -qx 'Rakefile' "$FAKE_LOG" &&
    grep -qx 'app/my file.rb' "$FAKE_LOG"
  check "${FUNCNAME[0]}" $?
}

test_runs_from_subdirectory() {
  setup
  echo 'puts 2' > "$REPO/app/a.rb"
  run_hook "$REPO/app" >/dev/null
  grep -qx 'app/a.rb' "$FAKE_LOG"
  check "${FUNCNAME[0]}" $?
}

test_rubocop_forces_config_exclusions() {
  setup
  echo 'puts 2' > "$REPO/app/a.rb"
  run_hook "$REPO" >/dev/null
  grep -qx -- '--force-exclusion' "$FAKE_LOG"
  check "${FUNCNAME[0]}" $?
}

test_repo_without_commits_checks_untracked() {
  setup
  rm -rf "$REPO/.git" && git -C "$REPO" init -q
  run_hook "$REPO" >/dev/null
  grep -qx 'app/a.rb' "$FAKE_LOG"
  check "${FUNCNAME[0]}" $?
}

test_tool_error_warns_without_blocking() {
  setup
  echo 'puts 2' > "$REPO/app/a.rb"
  export FAKE_BUNDLE_EXIT=7 FAKE_BUNDLE_OUT='Could not find gem standard'
  out=$(run_hook "$REPO")
  [ "$(jq -r '.decision // "none"' <<<"$out")" = none ] &&
    jq -r .systemMessage <<<"$out" | grep -q 'Could not find gem standard'
  check "${FUNCNAME[0]}" $?
}

for t in $(declare -F | awk '{print $3}' | grep '^test_'); do "$t"; done
echo "$FAILURES failure(s)"
[ "$FAILURES" -eq 0 ]
