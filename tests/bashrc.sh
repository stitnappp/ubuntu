#!/usr/bin/env bash
set -euo pipefail

repo_dir=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
test_dir=$(mktemp -d)
trap 'rm -rf "$test_dir"' EXIT

check_startup() {
    local home=$1 mode=$2
    if ! env -i HOME="$home" PATH="$PATH" TERM=xterm \
        bash --noprofile --norc -c '
            source "$1"
            alias ll >/dev/null || exit 1
            if [ "$2" = full ]; then
                declare -F __git_ps1 >/dev/null || exit 1
                complete -p git >/dev/null || exit 1
                declare -F _z >/dev/null || exit 1
                complete -p z >/dev/null || exit 1
                [[ "$PS1" == *\$\(__git_ps1* ]] || exit 1
            else
                [[ "$PS1" != *\$\(__git_ps1* ]] || exit 1
            fi
        ' bash "$repo_dir/root/.bashrc" "$mode" \
        >"$test_dir/stdout" 2>"$test_dir/stderr"; then
        printf 'FAIL: startup (%s)\n' "$home" >&2
        cat "$test_dir/stdout" "$test_dir/stderr" >&2
        return 1
    fi
    if [ -s "$test_dir/stdout" ] || [ -s "$test_dir/stderr" ]; then
        cat "$test_dir/stdout" "$test_dir/stderr"
        return 1
    fi
}

for name in home 'home with spaces'; do
    home="$test_dir/$name"
    mkdir -p "$home"
    cp -R "$repo_dir/root/.scripts" "$home/.scripts"
    check_startup "$home" full
    printf 'PASS: full startup (%s)\n' "$name"
done

mkdir -p "$test_dir/minimal"
check_startup "$test_dir/minimal" minimal
printf 'PASS: startup without optional helpers\n'
