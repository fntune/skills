#!/bin/bash

set -euo pipefail

script_dir=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
fixture_root=$(mktemp -d)
trap 'rm -rf "$fixture_root"' EXIT

home="$fixture_root/home"
workspace="$fixture_root/workspace"
current_transcript="$fixture_root/current.jsonl"
decoy_transcript="$home/.claude/projects/decoy/newer.jsonl"

mkdir -p "$workspace" "$(dirname "$decoy_transcript")"
printf '%s\n' '{"model":"claude-opus-4-1"}' > "$current_transcript"
printf '%s\n' '{"model":"claude-haiku-4-1"}' > "$decoy_transcript"
touch -t 203001010000 "$decoy_transcript"

input=$(jq -n \
    --arg cwd "$workspace" \
    --arg transcript "$current_transcript" \
    '{
        agent: {},
        context_window: {current_usage: null},
        model: {display_name: "Sonnet", id: "claude-sonnet-4-1"},
        transcript_path: $transcript,
        workspace: {current_dir: $cwd, project_dir: $cwd}
    }')

output=$(HOME="$home" "$script_dir/statusline-command.sh" <<< "$input")
case "$output" in
    *"opus (default: sonnet)"*) ;;
    *)
        printf 'Expected current transcript model, got: %s\n' "$output" >&2
        exit 1
        ;;
esac

missing_input=$(jq -n \
    --arg cwd "$workspace" \
    '{
        agent: {},
        context_window: {current_usage: null},
        model: {display_name: "Sonnet", id: "claude-sonnet-4-1"},
        transcript_path: "/missing/transcript.jsonl",
        workspace: {current_dir: $cwd, project_dir: $cwd}
    }')

missing_output=$(HOME="$home" "$script_dir/statusline-command.sh" <<< "$missing_input")
case "$missing_output" in
    *" | Sonnet | "*) ;;
    *)
        printf 'Expected session model fallback, got: %s\n' "$missing_output" >&2
        exit 1
        ;;
esac

printf 'statusline transcript fixtures passed\n'
