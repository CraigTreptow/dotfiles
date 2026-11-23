#!/usr/bin/env bash
# Claude Code status line — matches Starship config (fish_style_pwd_dir_length=1, truncate_to_repo)

input=$(cat)

cwd=$(echo "$input" | jq -r '.workspace.current_dir // .cwd // empty')
project_dir=$(echo "$input" | jq -r '.workspace.project_dir // empty')
model=$(echo "$input" | jq -r '.model.display_name // empty')
remaining=$(echo "$input" | jq -r '.context_window.remaining_percentage // empty')

BOLD_CYAN="\033[1;36m"
BOLD_GREEN="\033[1;32m"
YELLOW="\033[33m"
RESET="\033[0m"

if [ -n "$cwd" ]; then
  home_replaced="${cwd/#$HOME/~}"

  if [ -n "$project_dir" ] && [ "$cwd" != "$project_dir" ] || [ -n "$project_dir" ] && [ "$cwd" = "$project_dir" ]; then
    repo_name=$(basename "$project_dir")
    before_repo="${project_dir/#$HOME/~}"

    # Fish-style: first letter of each path component before repo root
    abbreviated=""
    IFS='/' read -ra parts <<< "$before_repo"
    for part in "${parts[@]}"; do
      [ -n "$part" ] && abbreviated="${abbreviated}/${part:0:1}"
    done

    rel="${cwd#$project_dir}"

    # bold cyan prefix / bold green repo root / bold cyan relative suffix
    display_path="${BOLD_CYAN}${abbreviated}/${RESET}${BOLD_GREEN}${repo_name}${RESET}${BOLD_CYAN}${rel}${RESET}"
  else
    display_path="${BOLD_CYAN}${home_replaced}${RESET}"
  fi
else
  display_path="${BOLD_CYAN}?${RESET}"
fi

out="${display_path}"

[ -n "$model" ] && out="${out}  ${YELLOW}${model}${RESET}"

if [ -n "$remaining" ]; then
  remaining_int=$(printf '%.0f' "$remaining")
  out="${out}  ctx:${remaining_int}%"
fi

# --- Plan usage pace (design: ~/.claude/docs/2026-11-23-statusline-usage-pace-design.md)
# Projection = used% / fraction of window elapsed: where you'll land at reset at current pace.
# Red ⚠ >100 (will hit limit early), green 85-100 (target), dim <85 (leaving usage unused).
RED="\033[1;91m"; GREEN="\033[1;92m"; DIM="\033[97m"  # bright variants: readable on dark backgrounds
now=${STATUSLINE_NOW:-$(date +%s)}

# usage_seg LABEL USED RESETS_AT WINDOW_SECS RESET_FMT RESET_ALWAYS(1/0)
usage_seg() {
  local label=$1 used=$2 resets=$3 window=$4 fmt=$5 always=$6
  local used_int proj proj_str color reset_str=""
  used_int=$(printf '%.0f' "$used")
  proj=$(awk -v u="$used" -v r="$resets" -v n="$now" -v w="$window" 'BEGIN {
    e = 1 - (r - n) / w; if (e > 1) e = 1
    if (e < 0.10) print "-"; else printf "%.0f", u / e }')
  if [ "$proj" = "-" ]; then
    color=$DIM; proj_str="…"
  else
    proj_str="${proj}%"
    if   [ "$proj" -gt 100 ]; then color=$RED; proj_str="${proj_str} ⚠"
    elif [ "$proj" -ge 85 ];  then color=$GREEN
    else color=$DIM; fi
  fi
  if [ "$always" = 1 ] || [ "$color" = "$RED" ]; then
    reset_str=" ↻$(date -r "$resets" +"$fmt")"
  fi
  printf '%s' "${color}${label} ${used_int}%→${proj_str}${reset_str}${RESET}"
}

usage=""
read -r fh_used fh_reset sd_used sd_reset < <(echo "$input" | jq -r '[
  .rate_limits.five_hour.used_percentage, .rate_limits.five_hour.resets_at,
  .rate_limits.seven_day.used_percentage, .rate_limits.seven_day.resets_at
] | map(. // "null") | @tsv')
if [ "$fh_used" != null ] && [ "$fh_reset" != null ]; then
  usage=$(usage_seg 5h "$fh_used" "$fh_reset" 18000 %H:%M 1)
fi
if [ "$sd_used" != null ] && [ "$sd_reset" != null ]; then
  seg=$(usage_seg 7d "$sd_used" "$sd_reset" 604800 %a 0)
  usage="${usage:+${usage}  · }${seg}"
fi
[ -n "$usage" ] && out="${out}  ${usage}"

printf '%b\n' "$out"
