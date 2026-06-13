#!/usr/bin/env bash
# Claude Code status line script
# Displays: model | git branch[*] | context bar %

input=$(cat)

# 1. Model short name + version: e.g. "claude-opus-4-7" -> "opus 4.7"
model_id=$(echo "$input" | jq -r '.model.id // empty')
if [ -n "$model_id" ]; then
  # Strip context-window suffix like "[1m]"
  model_id="${model_id%%\[*}"
  family=$(echo "$model_id" | grep -oiE 'opus|sonnet|haiku|fable' | head -1 | tr '[:upper:]' '[:lower:]')
  version=$(echo "$model_id" | grep -oE '[0-9]+(-[0-9]+)?' | head -1 | tr '-' '.')
  if [ -n "$family" ] && [ -n "$version" ]; then
    model_name="$family $version"
  elif [ -n "$family" ]; then
    model_name="$family"
  else
    model_name=$(echo "$model_id" | awk -F'-' '{print $NF}')
  fi
else
  model_name="?"
fi

# 2. Git branch + dirty indicator
cwd=$(echo "$input" | jq -r '.workspace.current_dir // .cwd // empty')
if [ -n "$cwd" ] && [ -d "$cwd/.git" ] || ([ -n "$cwd" ] && git -C "$cwd" rev-parse --git-dir > /dev/null 2>&1); then
  branch=$(git -C "$cwd" symbolic-ref --short HEAD 2>/dev/null || git -C "$cwd" rev-parse --short HEAD 2>/dev/null)
  if [ -n "$branch" ]; then
    # Check for uncommitted changes (staged or unstaged), skip optional locks
    if ! git -C "$cwd" diff --quiet 2>/dev/null || ! git -C "$cwd" diff --cached --quiet 2>/dev/null; then
      git_info="${branch}*"
    else
      git_info="$branch"
    fi
  else
    git_info=""
  fi
else
  git_info=""
fi

# 3. Context usage progress bar
used=$(echo "$input" | jq -r '.context_window.used_percentage // empty')
if [ -n "$used" ]; then
  filled=$(printf '%.0f' "$(echo "$used * 10 / 100" | bc -l 2>/dev/null || echo 0)")
  [ "$filled" -gt 10 ] 2>/dev/null && filled=10
  [ "$filled" -lt 0 ] 2>/dev/null && filled=0
  empty=$((10 - filled))
  bar=""
  i=0
  while [ "$i" -lt "$filled" ]; do
    bar="${bar}█"
    i=$((i + 1))
  done
  i=0
  while [ "$i" -lt "$empty" ]; do
    bar="${bar}░"
    i=$((i + 1))
  done
  # Token counts — sum all input categories to match used_percentage calculation
  input_tokens=$(echo "$input" | jq -r '
    (.context_window.current_usage.input_tokens // 0) +
    (.context_window.current_usage.cache_creation_input_tokens // 0) +
    (.context_window.current_usage.cache_read_input_tokens // 0)
  ')
  ctx_size=$(echo "$input" | jq -r '.context_window.context_window_size // empty')
  if [ -n "$input_tokens" ] && [ -n "$ctx_size" ]; then
    # Format with "k" or "m" suffix
    if [ "$input_tokens" -ge 1000000 ] 2>/dev/null; then
      used_k=$(printf '%.1fm' "$(echo "$input_tokens / 1000000" | bc -l 2>/dev/null || echo 0)")
    else
      used_k=$(printf '%.0fk' "$(echo "$input_tokens / 1000" | bc -l 2>/dev/null || echo 0)")
    fi
    if [ "$ctx_size" -ge 1000000 ] 2>/dev/null; then
      total_k=$(printf '%.1fm' "$(echo "$ctx_size / 1000000" | bc -l 2>/dev/null || echo 0)")
    else
      total_k=$(printf '%.0fk' "$(echo "$ctx_size / 1000" | bc -l 2>/dev/null || echo 0)")
    fi
    ctx_part=$(printf '%s %.0f%% (%s/%s)' "$bar" "$used" "$used_k" "$total_k")
  else
    ctx_part=$(printf '%s %.0f%%' "$bar" "$used")
  fi
else
  ctx_part="░░░░░░░░░░ -"
fi

# 3b. Subscription (plan) utilization — 5h session window + 7d weekly window.
# Present only for Pro/Max/Team sessions after the first response; absent for
# API-key/Bedrock/Vertex sessions, in which case this segment stays empty.
five_h=$(echo "$input" | jq -r '.rate_limits.five_hour.used_percentage // empty')
five_reset=$(echo "$input" | jq -r '.rate_limits.five_hour.resets_at // empty | floor')
week=$(echo "$input" | jq -r '.rate_limits.seven_day.used_percentage // empty')
week_reset=$(echo "$input" | jq -r '.rate_limits.seven_day.resets_at // empty | floor')

# Coarse single-unit countdown to a reset (epoch secs): <1h->Nm, <24h->Nh, else Nd
now_epoch=$(date +%s)
fmt_reset() {
  local at="$1" rem
  [ -z "$at" ] && return 0
  rem=$(( at - now_epoch ))
  if [ "$rem" -lt 60 ]; then
    printf '<1m'
  elif [ "$rem" -lt 3600 ]; then
    printf '%dm' "$(( rem / 60 ))"
  elif [ "$rem" -lt 86400 ]; then
    printf '%dh' "$(( rem / 3600 ))"
  else
    printf '%dd' "$(( rem / 86400 ))"
  fi
}

# Color a window token by usage: >=90% red (hot), >=80% yellow (warn), else plain.
# (Tweak the escapes here — e.g. $'\033[38;5;208m' for orange — if your theme
#  renders yellow poorly.)
c_reset=$'\033[0m'; c_warn=$'\033[33m'; c_hot=$'\033[31m'
window_tok() { # $1=label  $2=pct(float)  $3=reset-string
  local label="$1" int reset="$3" col=""
  int=$(printf '%.0f' "$2")
  if [ "$int" -ge 90 ]; then col="$c_hot"
  elif [ "$int" -ge 80 ]; then col="$c_warn"; fi
  printf '%s%s:%d%%%s%s' "$col" "$label" "$int" "${reset:+ ($reset)}" "${col:+$c_reset}"
}

sub_part=""
if [ -n "$five_h" ]; then
  sub_part=$(window_tok "5h" "$five_h" "$(fmt_reset "$five_reset")")
fi
if [ -n "$week" ]; then
  wk_part=$(window_tok "7d" "$week" "$(fmt_reset "$week_reset")")
  if [ -n "$sub_part" ]; then
    sub_part="$sub_part $wk_part"
  else
    sub_part="$wk_part"
  fi
fi

# 4. Directory basename
if [ -n "$cwd" ]; then
  dir_name="[$(basename "$cwd")]"
else
  dir_name=""
fi

# 5. Date + time, ISO 8601 (rightmost segment)
date_time=$(date '+%Y-%m-%d %H:%M:%S')

# Assemble output, skip empty parts
parts=""
for part in "$dir_name" "$ctx_part" "$sub_part" "$model_name" "$git_info" "$date_time"; do
  if [ -n "$part" ]; then
    if [ -n "$parts" ]; then
      parts="$parts | $part"
    else
      parts="$part"
    fi
  fi
done

printf '%s' "$parts"
