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

# --- unicode / emoji ---
# Paths on this machine have emojis in them; the line editor treats that as
# normal. MULTIBYTE is on by default under a UTF-8 locale, but odd launchers
# strip the environment (env.zsh heals the locale itself) — so say it
# explicitly. COMBINING_CHARS makes multi-codepoint glyphs — ❤️ (heart +
# variation selector), flags, accents — occupy one cell, so the cursor can't
# drift after completing an emoji filename. Every terminal we target supports
# it; the raw console (TERM=linux) and dumb terminals don't, so they opt out.
setopt MULTIBYTE
[[ $TERM != (dumb|linux) ]] && setopt COMBINING_CHARS

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
# Matching runs in three tiers — a tier is tried only when the one before it
# found nothing, so everyday completion behaves exactly as it always did:
#   1. classic case-insensitive prefix
#   2. …also across . _ - word breaks (v.2<TAB> → v0.2.1 style)
#   3. substring — the typed text may land anywhere in the name. This is what
#      makes emoji paths completable: "📁 Documents" starts with a character
#      you can't type, so Doc<TAB> must be allowed to match mid-name. Type
#      the letters, never the emoji.
zstyle ':completion:*' matcher-list \
  'm:{a-zA-Z}={A-Za-z}' \
  'm:{a-zA-Z}={A-Za-z} r:|[._-]=* r:|=*' \
  'm:{a-zA-Z}={A-Za-z} l:|=* r:|=*'
# a parent directory the line already names exactly (emoji and all) is taken
# as-is rather than re-run through the matcher — descending into
# "📁 Documents/…" stays fast and never gets second-guessed
zstyle ':completion:*' accept-exact-dirs true
zstyle ':completion:*' list-colors ${(s.:.)LS_COLORS}      # colourful matches
zstyle ':completion:*' group-name ''
zstyle ':completion:*:descriptions' format '%F{#9b6cf2}%B%d%b%f'
zstyle ':completion:*:warnings'     format '%F{#ec4e53}no matches%f'
zstyle ':completion:*' rehash true

# --- keybindings ---
# All in keys.zsh, sourced *after* plugins.zsh: zsh-vi-mode rebuilds the vi
# keymaps as it initializes, so anything bound here would be wiped.
