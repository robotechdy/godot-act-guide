default:
    @just --list

# GODOT_BIN can point to a local executable, including a path containing spaces.
check:
    @actual="$("${GODOT_BIN:-godot}" --version)" || exit 1; expected="$(cat .godot-version)" || exit 1; if [ -z "$expected" ] || [ "$actual" != "$expected" ]; then printf 'Godot version mismatch: expected %s, got %s\n' "$expected" "$actual" >&2; exit 1; fi

editor: check
    "${GODOT_BIN:-godot}" --path . --editor

run: check
    "${GODOT_BIN:-godot}" --path .
