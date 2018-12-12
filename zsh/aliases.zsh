################################################################################
# general overrides
################################################################################
# Use modern regexp, i.e. "(one|two)", not "(\(one\|two\)"
alias sed="sed -E"
alias cp="cp -iv"
alias rm="rm -iv"
alias mv="mv -iv"
alias ls="ls -FGh"
alias du="du -cksh"
alias df="df -h"

################################################################################
# going places
################################################################################
alias code="cd ~/code"
alias gods"cd ~/code/dotfiles"
alias god="cd ~/code/daily_drip/elixir"
alias goe="cd ~/code/exercism/elixir"
alias study="cd ~/code/study-notes"
alias work="~/code/work/dotfiles/work"
alias gow="cd ~/code/work"

################################################################################
# process related
################################################################################
alias kkr="pkill -9 -f 'rb-fsevent|rails|spring|puma|webpack|ruby'"
alias kkz="pkill -9 'zsh'"
alias uar='cd $MBC_WORK_ROOT/mbc_tools; bundle exec $MBC_WORK_ROOT/mbc_tools/scripts/update_all_repos'

################################################################################
# postgresql related
################################################################################

alias postgresstart='pg_ctl -D /usr/local/var/postgres -l /usr/local/var/postgres/server.log start'
alias postgresstop='pg_ctl -D /usr/local/var/postgres stop -s -m fast'

################################################################################
# Git related
################################################################################
alias gl='git log --oneline --decorate --graph --stat'
alias gitcleanup='git branch --merged | egrep -v "(^\*|master|develop)" | xargs -n 1 git branch -d'

################################################################################
# Rubocop related
################################################################################
# Before commit
alias rbc='clear;git ls-files -m | xargs ls -1 2>/dev/null | grep '\.rb$' | xargs rubocop'
# Before push
alias rbp='clear;git diff-tree -r --no-commit-id --name-only master@\{u\} head | xargs ls -1 2>/dev/null | grep '\.rb$' | grep -v schema | xargs rubocop'

alias rac='rubocop --auto-correct'

################################################################################
# tmux related
################################################################################
alias tml="tmux list-sessions"       #list running tmux sessions
alias tma="tmux -2 attach -t $1"     #join a current session
alias tmk="tmux kill-session -t $1"  #kill a session
alias mux="tmuxinator"

################################################################################
# brew related
################################################################################
alias cleanup="brew update; brew upgrade; brew cleanup"
