#!/bin/bash

# Read JSON input from stdin
input=$(cat)

# Extract values from JSON
model_name=$(echo "$input" | jq -r '.model.display_name')
current_dir=$(echo "$input" | jq -r '.workspace.current_dir')
used_pct=$(echo "$input" | jq -r '.context_window.used_percentage // empty')

# Change to the current directory to get accurate version and git info
cd "$current_dir" 2>/dev/null || cd "$HOME"

# Get Ruby version
ruby_version=""
if command -v ruby >/dev/null 2>&1; then
    ruby_version=$(ruby -v | cut -d' ' -f2)
fi

# Get Node.js version
node_version=""
if command -v node >/dev/null 2>&1; then
    node_version=$(node -v | sed 's/^v//')
fi

# Get Yarn version
yarn_version=""
if command -v yarn >/dev/null 2>&1; then
    yarn_version=$(yarn --version 2>/dev/null)
fi

# Get git status info (matching Starship style with cyan colors)
git_info=""
if git rev-parse --git-dir >/dev/null 2>&1; then
    branch=$(git branch --show-current 2>/dev/null || echo "detached")

    # Check for changes (using Starship-like symbols)
    git_status=""
    if ! git diff-index --quiet HEAD -- 2>/dev/null; then
        git_status=" "  # Modified (Starship style)
    fi

    # Check for untracked files
    if [[ -n $(git ls-files --others --exclude-standard 2>/dev/null) ]]; then
        git_status="${git_status}? "
    fi

    # Count ahead/behind (Starship style)
    ahead_behind=""
    if [[ "$branch" != "detached" ]]; then
        upstream=$(git rev-parse --abbrev-ref --symbolic-full-name @{u} 2>/dev/null)
        if [[ -n "$upstream" ]]; then
            ahead=$(git rev-list --count @{u}..HEAD 2>/dev/null || echo "0")
            behind=$(git rev-list --count HEAD..@{u} 2>/dev/null || echo "0")
            if [[ "$ahead" != "0" ]] && [[ "$behind" != "0" ]]; then
                ahead_behind="⇕⇡${ahead}⇣${behind} "
            elif [[ "$ahead" != "0" ]]; then
                ahead_behind="⇡${ahead} "
            elif [[ "$behind" != "0" ]]; then
                ahead_behind="⇣${behind} "
            fi
        fi
    fi

    # Cyan color to match Starship theme
    git_info="\033[3;36m$branch\033[0m \033[36m$ahead_behind$git_status\033[0m"
fi

# Build version info
version_info=""
if [[ -n "$ruby_version" ]]; then
    version_info="Ruby $ruby_version"
fi
if [[ -n "$node_version" ]]; then
    if [[ -n "$version_info" ]]; then
        version_info="$version_info | Node.js $node_version"
    else
        version_info="Node.js $node_version"
    fi
fi
if [[ -n "$yarn_version" ]]; then
    if [[ -n "$version_info" ]]; then
        version_info="$version_info | Yarn $yarn_version"
    else
        version_info="Yarn $yarn_version"
    fi
fi

# Build context usage info
context_info=""
if [[ -n "$used_pct" ]]; then
    # Round to integer percentage
    used_int=$(printf "%.0f" "$used_pct")
    context_info=" \033[2m(ctx: ${used_int}%%)\033[0m"
fi

# Format the complete status line (matching Starship cyan theme)
printf "\033[1;36m$(basename "$current_dir")\033[0m"

if [[ -n "$git_info" ]]; then
    printf " $git_info"
fi

if [[ -n "$version_info" ]]; then
    printf " \033[2m$version_info\033[0m"
fi

printf " \033[1;36m$model_name\033[0m$context_info"