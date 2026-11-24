# Metz Standards Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Personal Claude Code setup that enforces Sandi Metz's rules and testing approach, with a Stop hook running standardrb + Metz RuboCop limits on changed Ruby files.

**Architecture:** Style guide + RuboCop config live in `~/dotfiles/personal/` and are symlinked into `~/.claude/`. A bash Stop hook finds changed Ruby files in the session's git repo, runs both checkers through the project bundle, and blocks stopping (JSON `decision: block`) with the violations.

**Tech Stack:** bash, jq, git, bundler, standardrb, rubocop.

**Spec:** `docs/superpowers/specs/2026-11-24-metz-standards-design.md`

## Global Constraints
- All files under `~/dotfiles/personal/`; `~/.claude/*` entries are symlinks to them.
- Metz limits: `Metrics/ClassLength` Max 100, `Metrics/MethodLength` Max 5, `Metrics/ParameterLists` Max 4.
- Hook never modifies files; it only reports.
- Checkers run via `bundle exec` in the project; no global Ruby is assumed (mise has no default).
- Merge into `personal/claude-settings.json`; never replace existing keys.
- Don't commit unless the user asks.

## Review Focus
1. Hook run outside a git repo (e.g. `~/workspace`) → exit 0, no output.
2. Project without `standard` in `Gemfile.lock` → exit 0, no output (no false blocks on non-Ruby repos).
3. Changed file was deleted (`git status` lists it, file absent) → ignored, no checker error.
4. `stop_hook_active: true` with violations still present → allow stop, show violations to the user via `systemMessage`.
5. Filenames with spaces → passed intact to the checkers.

---

### Task 1: Style guide, Metz RuboCop config, CLAUDE.md update

**Files:**
- Create: `personal/RUBY_RAILS_STYLE.md`
- Create: `personal/metz-rubocop.yml`
- Modify: `personal/CLAUDE.md` (Ruby & Rails Guidelines → "Slim Controllers" bullet; add a "Quality Gate" note)
- Symlinks: `~/.claude/RUBY_RAILS_STYLE.md`, `~/.claude/metz-rubocop.yml`

- [ ] **Step 1: Write `RUBY_RAILS_STYLE.md`** with sections:
  - *Sandi Metz's Rules*: the four rules verbatim in substance. Violation protocol: stop and refactor; if deviation is justified, stop and state rule broken + justification + what's being done instead, then continue (no waiting for approval). Rule 4 is judgment-based (not checked by the hook).
  - *Testing (Magic Tricks of Testing)*: incoming query → assert return value; incoming command → assert direct public side effect; messages to self → don't test; outgoing query → don't test/expect; outgoing command → expect it was sent, using verified doubles (`instance_double`).
  - *Design*: SRP, dependency injection, Law of Demeter, composition over inheritance, shameless green first, refactor only under green tests.
  - *Quality Gate*: the Stop hook runs standardrb + `~/.claude/metz-rubocop.yml`; fix with `bundle exec standardrb --fix` first, then by hand.
- [ ] **Step 2: Write `metz-rubocop.yml`**: `AllCops: DisabledByDefault: true, NewCops: disable, SuggestExtensions: false, Exclude: [db/**/*, bin/**/*, vendor/**/*, node_modules/**/*]`; enable the three Metrics cops with the Global Constraints maxes.
- [ ] **Step 3: Edit `CLAUDE.md`**: replace "Keep logic in Models or Service Objects; use `app/services` for complex business logic." with "Keep logic out of controllers, in small single-purpose objects (models, POROs, `app/services`) that respect the Metz limits in the style guide." Add under Interaction Rules: "**Quality Gate:** a Stop hook runs standardrb and the Metz RuboCop limits on changed Ruby files; fix every violation it reports."
- [ ] **Step 4: Symlink**: `ln -s ~/dotfiles/personal/RUBY_RAILS_STYLE.md ~/.claude/RUBY_RAILS_STYLE.md` and same for `metz-rubocop.yml`.
- [ ] **Step 5: Verify**: `readlink -f ~/.claude/RUBY_RAILS_STYLE.md ~/.claude/metz-rubocop.yml` prints both dotfiles paths; in `~/workspace/craigtreptow-com` run `bundle exec rubocop -c ~/.claude/metz-rubocop.yml --format simple app` → runs without config errors (offenses allowed).

### Task 2: Stop hook script (TDD)

**Files:**
- Create: `personal/claude-hooks/ruby-quality-stop.sh` (executable)
- Test: `personal/claude-hooks/test/ruby-quality-stop_test.sh` (plain bash, no bats; prints PASS/FAIL per case, exits non-zero on any failure)

**Interfaces:**
- Produces: `ruby-quality-stop.sh` — reads Stop hook JSON on stdin (`cwd`, `stop_hook_active`); exit 0 always. Output:
  - clean or skipped → no stdout.
  - violations & `stop_hook_active` false → `{"decision":"block","reason":"<header + checker output>"}`.
  - violations & `stop_hook_active` true → `{"systemMessage":"Ruby quality check still failing:\n<output>"}`.
- Env: `METZ_RUBOCOP_CONFIG` (default `$HOME/.claude/metz-rubocop.yml`) so tests can point elsewhere.

Test harness: each case builds a temp git repo (`mktemp -d`), commits a baseline, makes changes, puts a fake `bundle` first on `PATH` that logs its args to `$TMP/bundle.log` and exits with `$FAKE_BUNDLE_EXIT` printing `$FAKE_BUNDLE_OUT`.

- [ ] **Step 1: Write failing tests**:
  - `test_outside_git_repo_is_silent` — cwd = a non-repo temp dir → stdout empty, exit 0.
  - `test_no_standard_in_lockfile_is_silent` — Gemfile.lock without `standard` → empty, bundle.log absent.
  - `test_no_changed_ruby_files_is_silent` — only `README.md` changed → empty, bundle not called.
  - `test_clean_files_are_silent` — modified `app/a.rb`, fake exit 0 → empty; bundle.log has `exec standardrb app/a.rb` and `exec rubocop -c <config> app/a.rb`.
  - `test_violations_block` — fake exit 1, out `app/a.rb:1:1: C: Metrics/MethodLength` → `jq -r .decision` = `block`, `.reason` contains `Metrics/MethodLength`.
  - `test_stop_hook_active_allows_stop` — same as above with `"stop_hook_active":true` → no `.decision`; `.systemMessage` contains `Metrics/MethodLength`.
  - `test_includes_untracked_and_staged_ignores_deleted` — untracked `lib/new.rb`, staged `lib/staged.rb`, deleted `lib/gone.rb` → log contains first two, not `gone.rb`.
  - `test_gemfile_and_rakefile_included_and_space_in_name` — changed `Gemfile`, `Rakefile`, `app/my file.rb` → all three passed as single args (fake bundle logs one arg per line).
- [ ] **Step 2: Run** `bash personal/claude-hooks/test/ruby-quality-stop_test.sh` → all FAIL (script missing).
- [ ] **Step 3: Implement the script.** `set -euo pipefail`; parse stdin with jq; `cd "$cwd"`; `git rev-parse --show-toplevel` or exit 0; `cd` to toplevel; require `Gemfile.lock` matching `^    standard ` else exit 0. Changed files: `git diff --name-only -z HEAD` plus `git ls-files -z --others --exclude-standard`, keep `*.rb|Gemfile|Rakefile` that exist (`-f`), store in a bash array. Run both checkers (capture combined output, don't stop at first failure); build JSON with `jq -n --arg`.
- [ ] **Step 4: Run tests** → all PASS; `shellcheck personal/claude-hooks/*.sh personal/claude-hooks/test/*.sh` → no warnings.

### Task 3: Register hook and verify live

**Files:**
- Modify: `personal/claude-settings.json` (add `hooks.Stop`)
- Modify: `README.md` (one short section: Claude setup files + symlinks for RUBY_RAILS_STYLE.md and metz-rubocop.yml)

- [ ] **Step 1: Add to settings** (merge, keep all existing keys):
  `"hooks": {"Stop": [{"hooks": [{"type": "command", "command": "bash ~/dotfiles/personal/claude-hooks/ruby-quality-stop.sh", "timeout": 120, "statusMessage": "Checking Ruby quality..."}]}]}`
- [ ] **Step 2: Validate**: `jq -e '.hooks.Stop[0].hooks[0].command' personal/claude-settings.json` prints the command; `jq -e .statusLine personal/claude-settings.json` still prints the status line.
- [ ] **Step 3: Pipe-test against real tooling**: scratch git repo with a copy of `craigtreptow-com`'s `Gemfile`, `Gemfile.lock` and Ruby version file, plus an untracked `a.rb` with a 7-line method and a double-quote violation; `echo '{"cwd":"<scratch>","stop_hook_active":false}' | bash ~/dotfiles/personal/claude-hooks/ruby-quality-stop.sh` → `decision: block` with both a Standard offense and `Metrics/MethodLength`.
- [ ] **Step 4: Confirm Stop input contract**: temporarily prefix the command with `tee ~/.claude/stop-hook-input.json |`… (or log stdin) and end one turn; check the file has `cwd` and `stop_hook_active`; remove the logging. If the watcher doesn't pick up the change, ask the user to open `/hooks` once.
- [ ] **Step 5: Update README** and show the user `git status` in `~/dotfiles`; ask before committing.
