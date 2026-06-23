# options.zsh — behaviour. Tuned for fast, forgiving, low-friction interactive use.

# --- navigation / quality of life ---
setopt AUTO_CD              # `Documents` == `cd Documents`
setopt AUTO_PUSHD           # cd builds a directory stack
setopt PUSHD_IGNORE_DUPS
setopt CDABLE_VARS
setopt INTERACTIVE_COMMENTS # allow # comments at the prompt
setopt EXTENDED_GLOB        # ^ ~ # globbing, **/ recursive
setopt GLOB_DOTS            # globs match dotfiles
setopt NO_BEEP
setopt NO_FLOW_CONTROL      # free up ctrl-s / ctrl-q
setopt PROMPT_SUBST

# --- history ---
HISTFILE="$HOME/.zsh_history"
HISTSIZE=100000
SAVEHIST=100000
setopt SHARE_HISTORY          # live history across open shells
setopt INC_APPEND_HISTORY
setopt HIST_IGNORE_ALL_DUPS
setopt HIST_IGNORE_SPACE      # ` cmd` (leading space) stays out of history
setopt HIST_REDUCE_BLANKS
setopt HIST_VERIFY            # expand !! before running

# --- completion ---
# extra completion definitions (zsh-completions) must be on fpath *before* compinit
_zc="${XDG_DATA_HOME:-$HOME/.local/share}/blossom-shell/plugins/zsh-completions/src"
[[ -d "$_zc" ]] && fpath=("$_zc" $fpath); unset _zc
autoload -Uz compinit
ZCD="${XDG_CACHE_HOME:-$HOME/.cache}/zsh"; mkdir -p "$ZCD"
compinit -d "$ZCD/zcompdump"
zmodload zsh/complist 2>/dev/null
setopt COMPLETE_IN_WORD ALWAYS_TO_END
zstyle ':completion:*' menu select                         # arrow-key menu
zstyle ':completion:*' matcher-list 'm:{a-zA-Z}={A-Za-z}'  # case-insensitive
zstyle ':completion:*' list-colors ${(s.:.)LS_COLORS}      # colourful matches
zstyle ':completion:*' group-name ''
zstyle ':completion:*:descriptions' format '%F{#9b6cf2}%B%d%b%f'
zstyle ':completion:*:warnings'     format '%F{#ec4e53}no matches%f'
zstyle ':completion:*' rehash true

# --- keybindings (emacs base + sane terminal keys) ---
bindkey -e
bindkey '^[[H'  beginning-of-line
bindkey '^[[F'  end-of-line
bindkey '^[[1~' beginning-of-line
bindkey '^[[4~' end-of-line
bindkey '^[[3~' delete-char
bindkey '^[[1;5C' forward-word      # ctrl-right
bindkey '^[[1;5D' backward-word     # ctrl-left
bindkey '^H' backward-kill-word     # ctrl-backspace

# --- vim keys in the completion selection menu (zsh's native menuselect) ---
# This is the menu you get when fzf isn't driving completion. With fzf installed,
# fzf-tab takes over TAB (see plugins.zsh) and its vim nav is Ctrl-h/j/k/l — letter
# keys there type into the fuzzy filter. Run `disable-fzf-tab` to fall back to this
# native menu and get plain h/j/k/l. (zsh/complist is loaded above.)
bindkey -M menuselect 'h' vi-backward-char
bindkey -M menuselect 'j' vi-down-line-or-history
bindkey -M menuselect 'k' vi-up-line-or-history
bindkey -M menuselect 'l' vi-forward-char
bindkey -M menuselect 'g' beginning-of-history     # jump to first match
bindkey -M menuselect 'G' end-of-history           # jump to last match
bindkey -M menuselect '/' history-incremental-search-forward  # filter within the menu
bindkey -M menuselect '^[' send-break              # Esc cancels
