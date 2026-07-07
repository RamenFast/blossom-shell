# prompt.zsh — the Blossom prompt. Two lines, git-aware, exit-code-aware.
# cwd in gold, git branch in pink, staged/unstaged dots in gold/red, and a pink
# ❀ prompt char that turns red after a failed command. Truecolor; degrades fine
# on 256-colour terminals.

autoload -Uz vcs_info add-zsh-hook
zstyle ':vcs_info:*' enable git
zstyle ':vcs_info:git:*' check-for-changes true
zstyle ':vcs_info:git:*' stagedstr   ' %F{#f1bf40}●%f'
zstyle ':vcs_info:git:*' unstagedstr ' %F{#ec4e53}●%f'
zstyle ':vcs_info:git:*' formats       ' on %F{#db3776}%b%f%c%u'
zstyle ':vcs_info:git:*' actionformats ' on %F{#db3776}%b%f %F{#ec4e53}(%a)%f%c%u'

# Build the optional segments in precmd via psvar, so the prompt string itself
# stays free of nested ${..} braces (which collide with %F{#rrggbb} colour codes).
#   psvar[1] = user@host  (only over SSH)
#   psvar[2] = virtualenv name (only inside one)
_blossom_precmd() {
  vcs_info
  psvar=('' '')
  [[ -n "$SSH_CONNECTION" ]] && psvar[1]="${USER}@${HOST%%.*}"
  [[ -n "$VIRTUAL_ENV" ]]    && psvar[2]="${VIRTUAL_ENV:t}"
  _blossom_mode_fg=$_blossom_petal_insert   # each new line starts in insert mode
}
add-zsh-hook precmd _blossom_precmd

# vi-mode indicator — zsh-vi-mode calls this hook on every mode switch. The
# petal recolours: blue=normal, purple=visual, gold=replace; insert keeps the
# usual pink (or red after a failed command). Harmless no-op without the plugin.
# The variable always carries the *complete* colour code: a ${var:-fallback}
# with %F{…} inside would trip the same nested-brace collision psvar avoids.
typeset -g _blossom_petal_insert='%(?.%F{#db3776}.%F{#ec4e53})'
typeset -g _blossom_mode_fg="$_blossom_petal_insert"
zvm_after_select_vi_mode() {
  case "$ZVM_MODE" in
    "$ZVM_MODE_NORMAL")                          _blossom_mode_fg='%F{#36c8ff}' ;;
    "$ZVM_MODE_VISUAL"|"$ZVM_MODE_VISUAL_LINE")  _blossom_mode_fg='%F{#9b6cf2}' ;;
    "$ZVM_MODE_REPLACE")                         _blossom_mode_fg='%F{#f1bf40}' ;;
    *)                                           _blossom_mode_fg=$_blossom_petal_insert ;;
  esac
  zle reset-prompt 2>/dev/null || true
}

setopt PROMPT_SUBST
PROMPT='%(1V.%F{#9b6cf2}%1v%f .)%(2V.%F{#9b6cf2}(%2v)%f .)%F{#f1bf40}%~%f${vcs_info_msg_0_}
${_blossom_mode_fg}❀%f '
RPROMPT='%F{#3a4654}%*%f'
