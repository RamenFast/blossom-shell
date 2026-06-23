# plugins.zsh — load the cloned zsh plugins (installed by `blossom-shell enable`).
# Missing plugins are silently skipped, so the shell still works offline.
_bs_plug="${XDG_DATA_HOME:-$HOME/.local/share}/blossom-shell/plugins"

# autosuggestions — fish-style ghost text from your history as you type
if [[ -f "$_bs_plug/zsh-autosuggestions/zsh-autosuggestions.zsh" ]]; then
  source "$_bs_plug/zsh-autosuggestions/zsh-autosuggestions.zsh"
  ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE='fg=#5a6b7a'
  ZSH_AUTOSUGGEST_STRATEGY=(history completion)
fi

# history-substring-search — type a few letters, ↑/↓ walks matching history
if [[ -f "$_bs_plug/zsh-history-substring-search/zsh-history-substring-search.zsh" ]]; then
  source "$_bs_plug/zsh-history-substring-search/zsh-history-substring-search.zsh"
  bindkey '^[[A' history-substring-search-up
  bindkey '^[[B' history-substring-search-down
  bindkey '^P'   history-substring-search-up
  bindkey '^N'   history-substring-search-down
  HISTORY_SUBSTRING_SEARCH_HIGHLIGHT_FOUND='fg=#000000,bg=#db3776'
fi

# fzf — fuzzy finder. Keys: Ctrl-T insert a file/dir path · Alt-C cd into a dir ·
# Ctrl-R search history. Install the binary with:  sudo apt install fzf
if command -v fzf >/dev/null; then
  export FZF_DEFAULT_OPTS='--height 45% --layout=reverse --border=rounded --cycle
    --bind ctrl-j:down,ctrl-k:up,ctrl-d:half-page-down,ctrl-u:half-page-up,ctrl-/:toggle-preview
    --color=fg+:#e8dccb,bg+:#2a1f18,hl:#f1bf40,hl+:#f1bf40,pointer:#db3776,marker:#db3776,prompt:#db3776,info:#7f7f7f,border:#4a3a30'
  # prefer fd for path/dir sources if present (fast, honours .gitignore); else find
  if command -v fdfind >/dev/null; then
    export FZF_CTRL_T_COMMAND='fdfind --hidden --strip-cwd-prefix'
    export FZF_ALT_C_COMMAND='fdfind --type d --hidden --strip-cwd-prefix'
  fi
  if fzf --zsh >/dev/null 2>&1; then
    source <(fzf --zsh)                         # fzf >= 0.48 ships its own loader
  else
    for f in /usr/share/doc/fzf/examples/key-bindings.zsh /usr/share/fzf/key-bindings.zsh; do
      [[ -r "$f" ]] && { source "$f"; break; }  # older fzf: key-bindings only (fzf-tab does TAB)
    done
  fi
fi

# fzf-tab — turns TAB completion into a fuzzy, navigable menu. Built for paths
# with emojis in them: type the plain-text bits, pick with ↑/↓ or Ctrl-j/k,
# Enter to fill. Loads after compinit (via options.zsh), before highlighting.
if command -v fzf >/dev/null && [[ -f "$_bs_plug/fzf-tab/fzf-tab.plugin.zsh" ]]; then
  zstyle ':completion:*' menu no                        # required: fzf-tab replaces zsh's menu
  zstyle ':completion:*:descriptions' format '[%d]'     # group headers inside the menu
  # vim-style nav inside the fuzzy menu (letters type into the filter, so Ctrl-*):
  # Ctrl-j/k down/up · Ctrl-d/u half-page · Ctrl-h/l move the filter cursor
  zstyle ':fzf-tab:*' fzf-bindings 'ctrl-j:down' 'ctrl-k:up' \
    'ctrl-d:half-page-down' 'ctrl-u:half-page-up' \
    'ctrl-h:backward-char' 'ctrl-l:forward-char'
  zstyle ':fzf-tab:*' continuous-trigger '/'            # press / to keep diving into a dir
  zstyle ':fzf-tab:complete:cd:*' fzf-preview 'ls -1 --color=always $realpath'
  source "$_bs_plug/fzf-tab/fzf-tab.plugin.zsh"
fi

# autopair — auto-insert/skip matching quotes, brackets and parens as you type.
# Loaded before syntax-highlighting so its widgets get wrapped, not the reverse.
if [[ -f "$_bs_plug/zsh-autopair/autopair.zsh" ]]; then
  source "$_bs_plug/zsh-autopair/autopair.zsh"
  autopair-init
fi

# you-should-use — after you run a command that has an alias, it reminds you of
# the shorter alias so the muscle memory sticks. Non-intrusive (prints after).
if [[ -f "$_bs_plug/you-should-use/you-should-use.plugin.zsh" ]]; then
  YSU_MESSAGE_POSITION="after"
  YSU_HARDCORE=0                          # remind, don't block
  source "$_bs_plug/you-should-use/you-should-use.plugin.zsh"
fi

# syntax highlighting — MUST be last; recoloured to the Blossom palette
if [[ -f "$_bs_plug/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh" ]]; then
  source "$_bs_plug/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh"
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
fi
unset _bs_plug
