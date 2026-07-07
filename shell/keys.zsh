# keys.zsh — every keybinding, in one place. Sourced after plugins.zsh on
# purpose: zsh-vi-mode rebuilds the vi keymaps when it initializes, so binds
# made here land in the final keymaps instead of being wiped.

# vi editing at the prompt. zsh-vi-mode (plugins.zsh) provides the full modal
# experience; this fallback keeps plain vi-mode if the plugin isn't cloned yet.
if (( ! ${+ZVM_VERSION} )); then
  bindkey -v
  KEYTIMEOUT=15          # snappy Esc without breaking multi-key sequences
fi

# --- terminal keys — in both vi keymaps so Home/End/etc. work in normal mode too
for _bs_m in viins vicmd; do
  bindkey -M "$_bs_m" '^[[H'    beginning-of-line     # Home
  bindkey -M "$_bs_m" '^[[1~'   beginning-of-line
  bindkey -M "$_bs_m" '^[[F'    end-of-line           # End
  bindkey -M "$_bs_m" '^[[4~'   end-of-line
  bindkey -M "$_bs_m" '^[[3~'   delete-char           # Delete
  bindkey -M "$_bs_m" '^[[1;5C' forward-word          # Ctrl-→
  bindkey -M "$_bs_m" '^[[1;5D' backward-word         # Ctrl-←
done

# --- insert-mode comforts — the emacs muscle memory worth keeping
bindkey -M viins '^A' beginning-of-line
bindkey -M viins '^E' end-of-line
bindkey -M viins '^H' backward-kill-word              # Ctrl-Backspace
bindkey -M viins '^U' backward-kill-line

# --- ↑/↓ (and Ctrl-P/N in insert) walk history filtered by what you've typed
if (( ${+widgets[history-substring-search-up]} )); then
  for _bs_m in viins vicmd; do
    bindkey -M "$_bs_m" '^[[A' history-substring-search-up
    bindkey -M "$_bs_m" '^[[B' history-substring-search-down
  done
  bindkey -M viins '^P' history-substring-search-up
  bindkey -M viins '^N' history-substring-search-down
fi
unset _bs_m

# --- vim keys in the completion selection menu (zsh's native menuselect) ---
# This is the menu you get when fzf isn't driving completion. With fzf installed,
# fzf-tab takes over TAB (see plugins.zsh) and its vim nav is Ctrl-h/j/k/l — letter
# keys there type into the fuzzy filter. Run `disable-fzf-tab` to fall back to this
# native menu and get plain h/j/k/l. (zsh/complist is loaded by options.zsh.)
bindkey -M menuselect 'h' vi-backward-char
bindkey -M menuselect 'j' vi-down-line-or-history
bindkey -M menuselect 'k' vi-up-line-or-history
bindkey -M menuselect 'l' vi-forward-char
bindkey -M menuselect 'g' beginning-of-history     # jump to first match
bindkey -M menuselect 'G' end-of-history           # jump to last match
bindkey -M menuselect '/' history-incremental-search-forward  # filter within the menu
bindkey -M menuselect '^[' send-break              # Esc cancels
