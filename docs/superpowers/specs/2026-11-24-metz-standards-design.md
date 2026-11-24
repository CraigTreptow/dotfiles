# Design: Metz-based personal coding standards

**Date:** 2026-11-24 · **Size:** small change · **Status:** approved

## Why
Steer Claude Code toward good-quality code, meaningful tests, and maintainable apps,
using Sandi Metz's guidelines as the initial measure.

## Approaches
- A: Style guide only — simplest; relies on Claude self-judging.
- B: Guide + RuboCop Metz self-check before finishing — exact pass/fail on measurable rules.
- C: B + hook after every edit — unskippable but noisy mid-refactor.

Picked **B**, then extended: the checks run in a **Stop hook** (fires when Claude finishes,
not per edit), which avoids C's noise while making the checks unskippable.

## What gets built (all in `~/dotfiles/personal/`, symlinked into `~/.claude/`)
1. `RUBY_RAILS_STYLE.md` → `~/.claude/RUBY_RAILS_STYLE.md` (already referenced by CLAUDE.md)
   - Metz's four rules. On violation: stop and refactor; if deviation is justified,
     stop, state the rule, the justification, and what's being done instead, then continue.
   - Testing: Metz "Magic Tricks of Testing" — test incoming queries (return value) and
     commands (public side effects); don't test private methods or outgoing queries;
     expect outgoing commands with verified doubles.
   - Design (Claude's proposal): SRP, dependency injection, Law of Demeter, composition
     over inheritance, shameless green first, refactor only under green.
2. `metz-rubocop.yml` → `~/.claude/metz-rubocop.yml`: only Metrics/ClassLength 100,
   Metrics/MethodLength 5, Metrics/ParameterLists 4; excludes db/, generated files.
3. `claude-hooks/ruby-quality-stop.sh`, registered as a Stop hook in `claude-settings.json`:
   - Changed files = modified/staged/untracked vs HEAD, `*.rb`, `Gemfile`, `Rakefile`.
   - Runs `bundle exec standardrb` and `bundle exec rubocop -c ~/.claude/metz-rubocop.yml`
     on them; skips silently outside git, with no changed Ruby files, or when the
     project doesn't bundle standard/rubocop.
   - Violations → block stop, feed them back; Claude fixes (`standardrb --fix`, then manual).
   - Loop guard: if stop_hook_active and violations remain, allow stop and surface them.
4. `CLAUDE.md`: "Keep logic in Models or Service Objects" → small single-purpose objects;
   note that the Stop hook enforces standardrb + Metz limits.

## Claude's calls
- RuboCop/standardrb run via the project bundle (no global Ruby default under mise).
- "Changed" = uncommitted; may flag pre-existing uncommitted edits.
- Hook never auto-fixes; Claude does the fixing so every change is visible.
- Rule 4 (controller → one object to view) stays judgment-based.
- Stop hook I/O to be verified against Claude Code docs.

## Out of scope
Work-machine variants.
