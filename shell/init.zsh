# init.zsh — the entrypoint that ~/.zshrc sources. Loads the Blossom zsh setup in
# the right order. BLOSSOM_SHELL_HOME is exported by the generated ~/.zshrc.

: ${BLOSSOM_SHELL_HOME:="${${(%):-%x}:A:h:h}"}   # fall back to this file's repo
_bs="$BLOSSOM_SHELL_HOME/shell"

# environment (PATH + tools) — safe for non-interactive shells too
source "$_bs/env.zsh"

# everything below is interactive-only
[[ -o interactive ]] || return

source "$_bs/options.zsh"    # shell options, history, completion
source "$_bs/plugins.zsh"    # vi-mode, autosuggestions, fzf/fzf-tab, zoxide, highlight
source "$_bs/keys.zsh"       # keybindings (after plugins: zsh-vi-mode resets keymaps)
source "$_bs/aliases.zsh"    # aliases + functions (ported from bash + extras)
source "$_bs/prompt.zsh"     # the Blossom prompt

# Blossom greeter — a compact fetch, once per top-level interactive terminal.
# BLOSSOM_GREETED is exported, so nested/subshells stay quiet; a fresh terminal
# starts clean and greets. Guarded on fastfetch so there's no nag before setup.
if [[ -o interactive && -t 1 && -z ${BLOSSOM_GREETED:-} && $TERM != dumb ]] \
   && command -v blossomfetch >/dev/null && command -v fastfetch >/dev/null; then
  export BLOSSOM_GREETED=1
  blossomfetch --mini
fi

unset _bs
