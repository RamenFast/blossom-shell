#!/usr/bin/env bash
# blossomfetch must not mistake Ghostty's isolated XDG root for its own config.
set -euo pipefail

ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
SCRATCH_BASE="${JCODE_SCRATCH_DIR:-${TMPDIR:-/var/tmp}}"
WORK="$(mktemp -d "$SCRATCH_BASE/blossomfetch-config.XXXXXX")"
trap 'rm -rf "$WORK"' EXIT

mkdir -p "$WORK/home/.config/fastfetch" "$WORK/isolated/greenhouse/sway" "$WORK/fake"
: >"$WORK/home/.config/fastfetch/config-mini.jsonc"

cat >"$WORK/fake/fastfetch" <<'EOF'
#!/usr/bin/env bash
printf '%s\n' "$@" >"$FASTFETCH_ARGS"
EOF
chmod +x "$WORK/fake/fastfetch"

HOME="$WORK/home" \
XDG_CONFIG_HOME="$WORK/isolated/greenhouse/sway" \
FASTFETCH_ARGS="$WORK/fastfetch.args" \
PATH="$WORK/fake:/usr/bin:/bin" \
  "$ROOT/fetch/blossomfetch" --mini

mapfile -t args <"$WORK/fastfetch.args"
expected=(--config "$WORK/home/.config/fastfetch/config-mini.jsonc")
if [[ ${args[*]} != "${expected[*]}" ]]; then
  printf 'not ok - blossomfetch used %q instead of the real home fastfetch config\n' "${args[*]}" >&2
  exit 1
fi

printf 'ok - blossomfetch escapes a Ghostty-only XDG root and finds its startup config\n'
