#!/usr/bin/env bash
set -euo pipefail

state_file="${XDG_STATE_HOME:-$HOME/.local/state}/quickshell/ai-model-usage.json"
lock_file="${state_file}.lock"
today="$(TZ=America/Los_Angeles date +%F)"

quota_for() {
    case "$1" in
        gemma-4-31b-it) echo 14400 ;;
        gemini-3.5-flash-lite|gemini-3.1-flash-lite) echo 500 ;;
        gemini-3-flash-preview|gemini-3.6-flash|gemini-3.7-flash) echo 20 ;;
        *) echo 0 ;;
    esac
}

candidates_for() {
    case "$1" in
        screen)
            echo "gemini-3.5-flash-lite gemini-3.1-flash-lite gemini-3.7-flash gemini-3.6-flash gemini-3-flash-preview"
            ;;
        text)
            echo "gemini-3.5-flash-lite gemini-3.1-flash-lite gemma-4-31b-it gemini-3.7-flash gemini-3.6-flash gemini-3-flash-preview"
            ;;
        *)
            return 1
            ;;
    esac
}

fresh_state() {
    jq -n --arg date "$today" '{date: $date, counts: {}}'
}

load_state() {
    if [[ ! -s "$state_file" ]] || [[ "$(jq -r '.date // empty' "$state_file" 2>/dev/null)" != "$today" ]]; then
        fresh_state
    else
        jq -c '{date, counts: (.counts // {})}' "$state_file"
    fi
}

save_state() {
    local data="$1" temporary
    temporary="$(mktemp "${state_file}.XXXXXX")"
    printf '%s\n' "$data" > "$temporary"
    mv -f "$temporary" "$state_file"
}

reserve_next() {
    local profile="$1" state model count quota
    exec 9>"$lock_file"
    flock 9
    state="$(load_state)"

    for model in $(candidates_for "$profile"); do
        quota="$(quota_for "$model")"
        count="$(jq -r --arg model "$model" '.counts[$model] // 0' <<< "$state")"
        if (( count < quota )); then
            state="$(jq -c --arg model "$model" '.counts[$model] = ((.counts[$model] // 0) + 1)' <<< "$state")"
            save_state "$state"
            printf '%s\n' "$model"
            return 0
        fi
    done

    return 1
}

mark_exhausted() {
    local model="$1" state quota
    quota="$(quota_for "$model")"
    (( quota > 0 )) || return 1
    exec 9>"$lock_file"
    flock 9
    state="$(load_state)"
    state="$(jq -c --arg model "$model" --argjson quota "$quota" '.counts[$model] = $quota' <<< "$state")"
    save_state "$state"
}

case "${1:-}" in
    next)
        reserve_next "${2:?Missing request profile}"
        ;;
    fallback)
        mark_exhausted "${3:?Missing exhausted model}"
        reserve_next "${2:?Missing request profile}"
        ;;
    exhaust)
        mark_exhausted "${2:?Missing model name}"
        ;;
    status)
        load_state | jq -c .
        ;;
    *)
        echo "Usage: $0 {next PROFILE|fallback PROFILE MODEL|exhaust MODEL|status}" >&2
        exit 2
        ;;
esac
