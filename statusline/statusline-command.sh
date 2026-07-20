#!/bin/bash

truncate_path() {
    local path="$1"
    local max_len=50
    local len=${#path}

    if [ "$len" -le "$max_len" ]; then
        echo "$path"
        return
    fi

    local side_len=$(( (max_len - 3) / 2 ))
    local start="${path:0:$side_len}"
    local end="${path: -$side_len}"

    echo "${start}…${end}"
}

input=$(cat)

agent=$(echo "$input" | jq -r '.agent.name // empty')
model="${agent:-$(echo "$input" | jq -r '.model.display_name')}"

# Last-turn model from conversation JSONL (show as primary when different from session model)
session_model_id=$(echo "$input" | jq -r '.model.id')
transcript_path=$(echo "$input" | jq -r '.transcript_path // empty')
if [ -f "$transcript_path" ]; then
    last_model_id=$(tail -30 "$transcript_path" 2>/dev/null | grep -o '"model":"claude-[^"]*"' | tail -1 | sed 's/"model":"//;s/"//')
    if [ -n "$last_model_id" ] && [ "$last_model_id" != "$session_model_id" ]; then
        last_short=$(echo "$last_model_id" | sed 's/claude-//;s/-.*//')
        default_short=$(echo "$session_model_id" | sed 's/claude-//;s/-.*//')
        model="${last_short} (default: ${default_short})"
    fi
fi

usage=$(echo "$input" | jq '.context_window.current_usage')
context_info=''

if [ "$usage" != "null" ]; then
    total=$(echo "$usage" | jq '.input_tokens + .cache_creation_input_tokens + .cache_read_input_tokens')
    size=$(echo "$input" | jq '.context_window.context_window_size')

    format_k() {
        local val="$1"
        if [ "$val" = "0" ]; then
            echo "0"
        else
            awk "BEGIN {v=$val/1000; if(v==int(v)) printf \"%d\", v; else printf \"%.1f\", v}"
        fi
    }

    total_k=$(format_k "$total")
    size_k=$(format_k "$size")
    pct=$(awk "BEGIN {printf \"%.1f\", ($total*100)/$size}")

    context_info=" | ${total_k}k/${size_k}k (${pct}%)"
fi

cwd=$(echo "$input" | jq -r '.workspace.current_dir')
project_dir=$(echo "$input" | jq -r '.workspace.project_dir')
full_path="${cwd/#$HOME/~}"
display_path=$(truncate_path "$full_path")
if [ "$cwd" != "$project_dir" ]; then
    proj_path="${project_dir/#$HOME/~}"
    display_path="$(truncate_path "$proj_path") → ${cwd#"$project_dir"/}"
fi

# Git info: branch + status summary (mirrors Starship git_branch + git_status)
git_info=''
if cd "$cwd" 2>/dev/null; then
    branch=$(git --no-optional-locks rev-parse --abbrev-ref HEAD 2>/dev/null)
    if [ -n "$branch" ]; then
        git_info=" $branch"

        # Parse git status for modified/staged/untracked counts
        status_output=$(git --no-optional-locks status --porcelain 2>/dev/null)
        if [ -n "$status_output" ]; then
            staged=$(echo "$status_output" | grep -c '^[MADRC]' || true)
            modified=$(echo "$status_output" | grep -c '^.[MD]' || true)
            untracked=$(echo "$status_output" | grep -c '^??' || true)

            status_parts=''
            [ "$staged" -gt 0 ]    && status_parts="${status_parts}+${staged}"
            [ "$modified" -gt 0 ]  && status_parts="${status_parts} ~${modified}"
            [ "$untracked" -gt 0 ] && status_parts="${status_parts} ?${untracked}"

            status_parts="${status_parts# }"
            [ -n "$status_parts" ] && git_info="${git_info} [${status_parts}]"
        fi
    fi
fi

# user@host (mirrors Starship username + hostname)
user_host="$(whoami)@$(hostname -s)"

time_str=$(date +%H:%M)

printf '%s | %s | %s%s%s | %s' "$user_host" "$model" "$display_path" "$git_info" "$context_info" "$time_str"
