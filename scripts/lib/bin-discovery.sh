#!/bin/bash

find_executable_binary() {
    local binary_name="$1"
    shift
    local fallback_paths=("$@")

    if command -v "$binary_name" &> /dev/null; then
        local resolved_path
        resolved_path=$(command -v "$binary_name")
        echo "Found $binary_name via PATH: $resolved_path" >&2
        echo "$resolved_path"
        return 0
    fi

    local shell="${SHELL:-/bin/zsh}"
    local login_path
    login_path=$("$shell" -lc "which '$binary_name' 2>/dev/null" 2>/dev/null)
    if [[ -n "$login_path" && -x "$login_path" ]]; then
        echo "Found $binary_name via login shell PATH: $login_path" >&2
        echo "$login_path"
        return 0
    fi

    for candidate_path in "${fallback_paths[@]}"; do
        if [[ -x "$candidate_path" ]]; then
            echo "Found $binary_name via fallback path: $candidate_path" >&2
            echo "$candidate_path"
            return 0
        fi
    done

    return 1
}