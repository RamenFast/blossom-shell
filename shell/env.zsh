# env.zsh — login environment (PATH + tool inits), mirrored from the existing
# bash setup so nothing breaks. Sourced by both ~/.zprofile (login) and init.zsh
# (interactive). `typeset -U` keeps PATH de-duplicated no matter how often it runs.

typeset -U path PATH

# UTF-8, guaranteed — emoji-bearing filenames need it for completion, globbing
# and cursor math. kitty always provides a UTF-8 locale, but IDE terminals and
# bare launchers sometimes spawn zsh with LANG unset or =C, and then every
# multibyte name turns to mojibake. This only acts when the locale is actually
# broken; it repairs LC_CTYPE (character classes + width) and leaves message
# and sort locales alone. No UTF-8 locale on the system at all → no-op.
case "${(L)${LC_ALL:-${LC_CTYPE:-${LANG:-}}}}" in
  (*utf-8*|*utf8*) ;;                                # already fine — hands off
  (*)
    _bs_loc="$(locale -a 2>/dev/null | grep -m1 -iE '^(c|en_us)\.utf-?8$')"
    [[ -n "$_bs_loc" ]] || _bs_loc="$(locale -a 2>/dev/null | grep -m1 -iE '\.utf-?8$')"
    if [[ -n "$_bs_loc" ]]; then
      export LC_CTYPE="$_bs_loc"
      [[ -n "${LANG:-}" ]] || export LANG="$_bs_loc"
    fi
    unset _bs_loc
    ;;
esac

# user bins
[[ -d "$HOME/.local/bin"   ]] && path=("$HOME/.local/bin" $path)
[[ -d "$HOME/.opencode/bin" ]] && path=("$HOME/.opencode/bin" $path)

# rust / cargo
[[ -f "$HOME/.cargo/env" ]] && source "$HOME/.cargo/env"

# node / nvm  (nvm.sh is POSIX; it works under zsh)
export NVM_DIR="$HOME/.nvm"
[[ -s "$NVM_DIR/nvm.sh" ]] && source "$NVM_DIR/nvm.sh"

# bun
export BUN_INSTALL="$HOME/.bun"
[[ -d "$BUN_INSTALL/bin" ]] && path=("$BUN_INSTALL/bin" $path)

# hermes / nexus home name (kept identical to the bash env)
export HERMES_HOME_NAME="nexus"
[[ -f "$HOME/.config/bashrc.d/nexus.sh" ]] && source "$HOME/.config/bashrc.d/nexus.sh"

export PATH
