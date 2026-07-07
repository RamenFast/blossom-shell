# plugins.zsh — load the cloned zsh plugins (installed by `blossom-shell enable`).
# Missing plugins are silently skipped, so the shell still works offline.
# Order matters: zsh-vi-mode first (it rebuilds the vi keymaps as it initializes),
# syntax highlighting last (it wraps every widget defined before it). All
# keybindings live in keys.zsh, sourced *after* this file, so they land in the
# final keymaps instead of being wiped.
_bs_plug="${XDG_DATA_HOME:-$HOME/.local/share}/blossom-shell/plugins"

# vi-mode — modal vim editing at the prompt: text objects (ciw, da"), surround
# like vim-surround (ys/ds/cs, S in visual), visual + visual-line mode, and a
# mode-aware cursor (beam=insert, block=normal, underline=operator-pending).
# The prompt petal recolours per mode too — see prompt.zsh.
# ZVM_INIT_MODE=sourcing makes it initialize right here rather than at the first
# prompt, so everything loaded after binds on top of it, not under it.
if [[ -f "$_bs_plug/zsh-vi-mode/zsh-vi-mode.plugin.zsh" ]]; then
  ZVM_INIT_MODE=sourcing
  function zvm_config() {
    ZVM_LINE_INIT_MODE=$ZVM_MODE_INSERT            # every new prompt starts in insert
    ZVM_INSERT_MODE_CURSOR=$ZVM_CURSOR_BLINKING_BEAM
    ZVM_NORMAL_MODE_CURSOR=$ZVM_CURSOR_BLOCK
    ZVM_OPPEND_MODE_CURSOR=$ZVM_CURSOR_UNDERLINE
    ZVM_VI_HIGHLIGHT_BACKGROUND='#db3776'          # visual selection: Blossom pink
    ZVM_VI_HIGHLIGHT_FOREGROUND='#16141c'
  }
  source "$_bs_plug/zsh-vi-mode/zsh-vi-mode.plugin.zsh"
fi

# autosuggestions — fish-style ghost text from your history as you type
if [[ -f "$_bs_plug/zsh-autosuggestions/zsh-autosuggestions.zsh" ]]; then
  source "$_bs_plug/zsh-autosuggestions/zsh-autosuggestions.zsh"
  ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE='fg=#5a6b7a'
  ZSH_AUTOSUGGEST_STRATEGY=(history completion)
fi

# history-substring-search — type a few letters, ↑/↓ walks matching history.
# (The ↑/↓/Ctrl-P/N bindings are in keys.zsh.)
if [[ -f "$_bs_plug/zsh-history-substring-search/zsh-history-substring-search.zsh" ]]; then
  source "$_bs_plug/zsh-history-substring-search/zsh-history-substring-search.zsh"
  HISTORY_SUBSTRING_SEARCH_HIGHLIGHT_FOUND='fg=#000000,bg=#db3776'
fi

# fzf — fuzzy finder. Keys: Ctrl-T insert a file/dir path · Alt-C cd into a dir ·
# Ctrl-R search history. Install the binary with:  sudo apt install fzf
if command -v fzf >/dev/null; then
  export FZF_DEFAULT_OPTS='--height 45% --layout=reverse --border=rounded --cycle
    --pointer=❀ --marker=✿
    --bind ctrl-j:down,ctrl-k:up,ctrl-d:half-page-down,ctrl-u:half-page-up,ctrl-/:toggle-preview
    --color=fg+:#e8dccb,bg+:#2a1f18,hl:#f1bf40,hl+:#f1bf40,pointer:#db3776,marker:#db3776,prompt:#db3776,info:#7f7f7f,border:#4a3a30'
  # prefer fd for path/dir sources if present (fast, honours .gitignore); else find
  if command -v fdfind >/dev/null; then
    export FZF_CTRL_T_COMMAND='fdfind --hidden --strip-cwd-prefix'
    export FZF_ALT_C_COMMAND='fdfind --type d --hidden --strip-cwd-prefix'
  fi
  # live previews: dirs listed with eza, files syntax-highlighted with bat —
  # each degrades to plain ls/head when the nicer tool isn't installed
  if command -v eza >/dev/null; then _bs_dirprev='eza -1 --color=always --icons=auto --group-directories-first'
  else _bs_dirprev='ls -1 --color=always'; fi
  if   command -v batcat >/dev/null; then _bs_fileprev='batcat --color=always --style=numbers --line-range=:200'
  elif command -v bat    >/dev/null; then _bs_fileprev='bat --color=always --style=numbers --line-range=:200'
  else _bs_fileprev='head -200'; fi
  export FZF_CTRL_T_OPTS="--preview '[ -d {} ] && $_bs_dirprev {} || $_bs_fileprev {} 2>/dev/null'"
  export FZF_ALT_C_OPTS="--preview '$_bs_dirprev {}'"
  if fzf --zsh >/dev/null 2>&1; then
    source <(fzf --zsh)                         # fzf >= 0.48 ships its own loader
  else
    for f in /usr/share/doc/fzf/examples/key-bindings.zsh /usr/share/fzf/key-bindings.zsh; do
      [[ -r "$f" ]] && { source "$f"; break; }  # older fzf: key-bindings only (fzf-tab does TAB)
    done
  fi
fi

# zoxide — a smarter cd. Real paths behave exactly as before, but `cd blos`
# from anywhere jumps to the directory you visit that matches best (frecency),
# and `cdi` opens an interactive fzf picker over everywhere you've been.
if command -v zoxide >/dev/null; then
  eval "$(zoxide init zsh --cmd cd)"
  # zoxide's completion ends in an unconditional `return 0`, which tells
  # compsys "matches were added" even when its `_files -/` found none — so the
  # matcher-list retry loop stops at tier 1 and the substring tier that makes
  # emoji dirs completable (options.zsh) never runs. Wrap it to report the
  # truth: succeed only if something was actually added.
  if (( ${+functions[__zoxide_z_complete]} && ! ${+functions[_bs_zoxide_z_complete]} )); then
    functions -c __zoxide_z_complete _bs_zoxide_z_complete
    __zoxide_z_complete() {
      _bs_zoxide_z_complete "$@"
      (( compstate[nmatches] ))
    }
  fi
fi

# fzf-tab — turns TAB completion into a fuzzy, navigable menu. Made for paths
# with emojis in them: the substring matcher (options.zsh) surfaces
# "📁 Documents" when you type Doc<TAB>, and fzf-tab lets you pick it with
# ↑/↓ or Ctrl-j/k, Enter to fill. Loads after compinit, before highlighting.
if command -v fzf >/dev/null && [[ -f "$_bs_plug/fzf-tab/fzf-tab.plugin.zsh" ]]; then
  zstyle ':completion:*' menu no                        # required: fzf-tab replaces zsh's menu
  zstyle ':completion:*:descriptions' format '[%d]'     # group headers inside the menu
  zstyle ':fzf-tab:*' use-fzf-default-opts yes          # inherit the Blossom fzf colours
  # vim-style nav inside the fuzzy menu (letters type into the filter, so Ctrl-*):
  # Ctrl-j/k down/up · Ctrl-d/u half-page · Ctrl-h/l move the filter cursor
  zstyle ':fzf-tab:*' fzf-bindings 'ctrl-j:down' 'ctrl-k:up' \
    'ctrl-d:half-page-down' 'ctrl-u:half-page-up' \
    'ctrl-h:backward-char' 'ctrl-l:forward-char'
  zstyle ':fzf-tab:*' continuous-trigger '/'            # press / to keep diving into a dir
  # previews (same eza/bat helpers as fzf above): dir contents when completing
  # cd/z, file contents when completing an editor/pager argument
  zstyle ':fzf-tab:complete:(cd|z|zoxide):*' fzf-preview "$_bs_dirprev \$realpath"
  zstyle ':fzf-tab:complete:(nvim|vim|vi|nano|bat|batcat|cat|less|code):*' fzf-preview \
    "[ -d \$realpath ] && $_bs_dirprev \$realpath || $_bs_fileprev \$realpath 2>/dev/null"
  source "$_bs_plug/fzf-tab/fzf-tab.plugin.zsh"
  # fzf-tab needs `menu no`, but the native fallback menu needs `menu select`
  # (that's where keys.zsh's h/j/k/l bindings live). The plugin's own toggles
  # never touch that zstyle, so the promised `disable-fzf-tab` fallback would
  # land in a menu-less limbo — wrap both toggles (same functions -c trick as
  # ysu below) so each mode always gets the right menu.
  if (( ${+functions[disable-fzf-tab]} && ! ${+functions[_bs_disable_fzf_tab]} )); then
    functions -c disable-fzf-tab _bs_disable_fzf_tab
    disable-fzf-tab() { _bs_disable_fzf_tab "$@"; zstyle ':completion:*' menu select; }
  fi
  if (( ${+functions[enable-fzf-tab]} && ! ${+functions[_bs_enable_fzf_tab]} )); then
    functions -c enable-fzf-tab _bs_enable_fzf_tab
    enable-fzf-tab() { _bs_enable_fzf_tab "$@"; zstyle ':completion:*' menu no; }
  fi
fi
unset _bs_dirprev _bs_fileprev

# autopair — auto-insert/skip matching quotes, brackets and parens as you type.
# Loaded before syntax-highlighting so its widgets get wrapped, not the reverse.
if [[ -f "$_bs_plug/zsh-autopair/autopair.zsh" ]]; then
  source "$_bs_plug/zsh-autopair/autopair.zsh"
  autopair-init
fi

# you-should-use — after you run a command that has a shorter alias, a gentle
# reminder prints below the output — at most once per alias per shell session.
# NEVER set YSU_HARDCORE here, not even to 0: the plugin only checks that the
# variable is *set* and then blocks the command outright.
if [[ -f "$_bs_plug/you-should-use/you-should-use.plugin.zsh" ]]; then
  YSU_MESSAGE_POSITION="after"
  YSU_MODE="BESTMATCH"                    # suggest the single best alias, not a list
  YSU_MESSAGE_FORMAT=$'\e[38;2;90;107;122m❀ tip: \e[38;2;219;55;118m%alias\e[38;2;90;107;122m is your alias for \e[38;2;241;191;64m%command\e[0m'
  source "$_bs_plug/you-should-use/you-should-use.plugin.zsh"
  # once-per-session: wrap the plugin's message fn, drop repeats of the same tip
  if (( ${+functions[ysu_message]} )); then
    functions -c ysu_message _bs_ysu_message
    typeset -gA _bs_ysu_seen
    ysu_message() {
      [[ -n "${_bs_ysu_seen[$3]:-}" ]] && return 0
      _bs_ysu_seen[$3]=1
      _bs_ysu_message "$@"
    }
  fi
fi

# syntax highlighting — MUST be last; recoloured to the Blossom palette.
# `brackets` paints nested ()/[]/{} in rotating Blossom colours and flags
# unbalanced ones red before you even run the line.
if [[ -f "$_bs_plug/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh" ]]; then
  source "$_bs_plug/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh"
  ZSH_HIGHLIGHT_HIGHLIGHTERS=(main brackets)
  typeset -gA ZSH_HIGHLIGHT_STYLES
  ZSH_HIGHLIGHT_STYLES[command]='fg=#36c8ff'
  ZSH_HIGHLIGHT_STYLES[builtin]='fg=#36c8ff'
  ZSH_HIGHLIGHT_STYLES[function]='fg=#36c8ff'
  ZSH_HIGHLIGHT_STYLES[alias]='fg=#36c8ff'
  ZSH_HIGHLIGHT_STYLES[precommand]='fg=#36c8ff'
  ZSH_HIGHLIGHT_STYLES[path]='fg=#eaf6ff'
  ZSH_HIGHLIGHT_STYLES[globbing]='fg=#9b6cf2'
  ZSH_HIGHLIGHT_STYLES[single-quoted-argument]='fg=#f1bf40'
  ZSH_HIGHLIGHT_STYLES[double-quoted-argument]='fg=#f1bf40'
  ZSH_HIGHLIGHT_STYLES[command-substitution]='fg=#9b6cf2'
  ZSH_HIGHLIGHT_STYLES[unknown-token]='fg=#ec4e53,bold'
  ZSH_HIGHLIGHT_STYLES[comment]='fg=#5a6b7a'
  ZSH_HIGHLIGHT_STYLES[bracket-level-1]='fg=#db3776'
  ZSH_HIGHLIGHT_STYLES[bracket-level-2]='fg=#f1bf40'
  ZSH_HIGHLIGHT_STYLES[bracket-level-3]='fg=#36c8ff'
  ZSH_HIGHLIGHT_STYLES[bracket-level-4]='fg=#9b6cf2'
  ZSH_HIGHLIGHT_STYLES[bracket-error]='fg=#ec4e53,bold'
  ZSH_HIGHLIGHT_STYLES[cursor-matchingbracket]='standout'
fi
unset _bs_plug
