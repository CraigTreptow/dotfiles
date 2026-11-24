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
