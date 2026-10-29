# tp [dir]: attach to (or create) a tmux session for a project directory.
# Session name = initials of the dir name's -/_ separated words (arch-reverse-engineer -> are),
# or the full name if it is a single word.
tp() {
    local dir base name
    dir=$(cd "${1:-$PWD}" && pwd) || return
    base=$(basename "$dir")
    if [[ $base == *[-_]* ]]; then
        name=$(tr '_' '-' <<<"$base" | awk -F- '{for (i = 1; i <= NF; i++) if ($i != "") printf substr($i, 1, 1)}')
    else
        name=$base
    fi
    if [ -n "$TMUX" ]; then
        tmux has-session -t "=$name" 2>/dev/null || tmux new-session -d -s "$name" -c "$dir"
        tmux switch-client -t "=$name"
    else
        tmux new-session -A -s "$name" -c "$dir"
    fi
}
