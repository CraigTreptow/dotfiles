# dotfiles
dotfiles for personal projects

## Claude Code Status Line

Two variants:

- `personal/claude-statusline.sh` — path, model, context, plus plan usage pace for the
  5-hour and 7-day windows (e.g. `5h 62%→129% ⚠ ↻16:40 · 7d 38%→76%`). The arrow value is
  the projected usage at reset at the current pace: red ⚠ over 100% (you'll hit the limit
  early), green 85–100% (on target), white under 85% (usage left on the table).
- `work/statusline-command.sh` — path, model, and context usage.

To activate on a new machine, symlink the appropriate variant into `~/.claude/`:

```bash
# work machine
ln -sf ~/dotfiles/work/statusline-command.sh ~/.claude/statusline-command.sh

# personal machine (settings.json also lives here)
ln -sf ~/dotfiles/personal/claude-statusline.sh ~/.claude/statusline-command.sh
ln -sf ~/dotfiles/personal/claude-settings.json ~/.claude/settings.json
```

The `~/.claude/settings.json` entry that wires it up:

```json
"statusLine": {
  "type": "command",
  "command": "bash ~/.claude/statusline-command.sh"
}
```

## Claude Code Coding Standards (personal)

- `personal/CLAUDE.md` — global instructions; points at the style guide below.
- `personal/RUBY_RAILS_STYLE.md` — Sandi Metz's rules, the rule-break protocol, "Magic Tricks
  of Testing", and POODR / 99 Bottles design principles.
- `personal/metz-rubocop.yml` — RuboCop config for Metz rules 1–3 (class ≤100 lines,
  method ≤5 lines, ≤4 parameters).
- `personal/claude-hooks/ruby-quality-stop.sh` — Stop hook (registered in
  `claude-settings.json`): runs `standardrb` and the Metz config on changed Ruby files and
  blocks Claude from finishing until they pass. Skips repos that don't bundle `standard`.
  Tests: `bash personal/claude-hooks/test/ruby-quality-stop_test.sh`.

```bash
ln -sf ~/dotfiles/personal/CLAUDE.md ~/.claude/CLAUDE.md
ln -sf ~/dotfiles/personal/RUBY_RAILS_STYLE.md ~/.claude/RUBY_RAILS_STYLE.md
ln -sf ~/dotfiles/personal/metz-rubocop.yml ~/.claude/metz-rubocop.yml
```
