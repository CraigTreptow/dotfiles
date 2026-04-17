# dotfiles
dotfiles for personal projects

## Claude Code Status Line

A custom status line script lives in `work/statusline-command.sh` and `personal/statusline-command.sh`.

To activate on a new machine, symlink the appropriate variant into `~/.claude/`:

```bash
# work machine
ln -sf ~/dotfiles/work/statusline-command.sh ~/.claude/statusline-command.sh

# personal machine
ln -sf ~/dotfiles/personal/statusline-command.sh ~/.claude/statusline-command.sh
```

The `~/.claude/settings.json` entry that wires it up:

```json
"statusLine": {
  "type": "command",
  "command": "bash ~/.claude/statusline-command.sh"
}
```
