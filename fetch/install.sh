#!/usr/bin/env bash
# install.sh — deploy Blossomfetch.
#
#   ./install.sh              deploy configs + logo, link `blossomfetch` onto
#                             PATH, and add a guarded greeter to ~/.bashrc.
#   ./install.sh --uninstall  undo all of the above (restores nothing it didn't
#                             add; the ~/.bashrc block is marker-bounded).
#
# zsh users: the greeter already lives in blossom-shell/shell/init.zsh, so no
# bashrc edit is needed for the Blossom zsh — this just covers plain bash logins.
set -uo pipefail

SRC="$(cd "$(dirname "$(readlink -f "$0")")" && pwd)"
CFG="${XDG_CONFIG_HOME:-$HOME/.config}/fastfetch"
BIN="$HOME/.local/bin"
BASHRC="$HOME/.bashrc"
MARK_BEGIN="# >>> blossomfetch >>>"
MARK_END="# <<< blossomfetch <<<"

PINK=$'\e[38;2;219;55;118m'; GOLD=$'\e[38;2;241;191;64m'; GREEN=$'\e[38;2;55;255;160m'; R=$'\e[0m'
ok()  { printf '  %s✓%s %s\n' "$GREEN" "$R" "$*"; }
hdr() { printf '\n%s❀ %s%s\n' "$PINK" "$*" "$R"; }

strip_bash_block() {
  [ -f "$BASHRC" ] || return 0
  awk -v b="$MARK_BEGIN" -v e="$MARK_END" '
    $0==b {skip=1} !skip {print} $0==e {skip=0}' "$BASHRC" > "$BASHRC.bftmp" && mv "$BASHRC.bftmp" "$BASHRC"
}

install_all() {
  hdr "Installing Blossomfetch"

  mkdir -p "$CFG/logo" "$BIN"
  cp "$SRC/logo/blossom.txt" "$SRC/logo/blossom-mini.txt" "$CFG/logo/"
  ok "logo art → $CFG/logo/"

  # deploy configs, rewriting the @PREFIX@ token to the real config dir
  for c in config-full config-mini; do
    sed "s|@PREFIX@|$CFG|g" "$SRC/$c.jsonc" > "$CFG/$c.jsonc"
  done
  ok "configs → $CFG/"

  ln -sf "$SRC/blossomfetch" "$BIN/blossomfetch"
  ok "blossomfetch → $BIN/blossomfetch"

  # bash greeter (idempotent: strip any old block, then append a fresh one)
  strip_bash_block
  cat >> "$BASHRC" <<EOF
$MARK_BEGIN
# Compact Blossom fetch, once per top-level interactive terminal. Quiet in
# subshells (BLOSSOM_GREETED is exported) and before fastfetch is installed.
if [[ \$- == *i* && -t 1 && -z \${BLOSSOM_GREETED:-} && \$TERM != dumb ]] \\
   && command -v blossomfetch >/dev/null 2>&1 && command -v fastfetch >/dev/null 2>&1; then
  export BLOSSOM_GREETED=1
  blossomfetch --mini
fi
$MARK_END
EOF
  ok "greeter added to ~/.bashrc (marker-bounded, reversible)"

  if command -v fastfetch >/dev/null; then
    ok "fastfetch found: $(fastfetch --version 2>/dev/null | head -1)"
  else
    printf '\n  %s!%s fastfetch isn'\''t installed yet — install it, then `blossomfetch`:\n' "$GOLD" "$R"
    printf '      sudo add-apt-repository -y ppa:zhangsongcui3371/fastfetch && sudo apt update && sudo apt install -y fastfetch\n'
  fi
  printf '\n  Try it:  %sblossomfetch%s · %sblossomfetch --mini%s · %sblossomfetch --steam --copy%s\n' \
         "$GOLD" "$R" "$GOLD" "$R" "$GOLD" "$R"
}

uninstall_all() {
  hdr "Uninstalling Blossomfetch"
  rm -f "$BIN/blossomfetch"; ok "removed $BIN/blossomfetch"
  rm -f "$CFG/config-full.jsonc" "$CFG/config-mini.jsonc"
  rm -rf "$CFG/logo"; ok "removed deployed configs + logo"
  strip_bash_block; ok "stripped greeter from ~/.bashrc"
  printf '\n  (The zsh greeter lives in blossom-shell/shell/init.zsh — leave it or\n   remove that block if you want zsh quiet too.)\n'
}

case "${1:-}" in
  ""|install)    install_all ;;
  -u|--uninstall) uninstall_all ;;
  *) echo "usage: $0 [--uninstall]" >&2; exit 1 ;;
esac
