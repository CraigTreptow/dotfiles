eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
eval "$(mise activate zsh)"
eval "$(starship init zsh)"

# Machine-local secrets (not tracked in git)
[[ -f ~/.zshrc.secrets ]] && source ~/.zshrc.secrets

# Maximum number of lines kept in memory during a session
export HISTSIZE=100000
# Maximum number of lines saved to the history file
export SAVEHIST=100000
# File where history is stored
HISTFILE=~/.zsh_history

# Optional: Additional useful history options
setopt EXTENDED_HISTORY     # Write the history file in the ":start:elapsed;command" format
setopt INC_APPEND_HISTORY   # Write to the history file immediately, not when the shell exits
setopt SHARE_HISTORY        # Share history between all active Zsh sessions
setopt HIST_IGNORE_DUPS     # Do not save a command if it is a duplicate of the previous one
setopt HIST_SAVE_NO_DUPS    # Do not write duplicate entries in the history file


alias ls='ls --color=auto'
alias grep='rg'
alias vim='nvim'

export PATH="$HOME/.local/bin:$HOME/.bun/bin:$PATH"
