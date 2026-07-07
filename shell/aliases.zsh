# aliases.zsh — your bash aliases, carried over verbatim, plus a few extras.

# colour grep (same as bash)
if [[ -x /usr/bin/dircolors ]]; then
  [[ -r ~/.dircolors ]] && eval "$(dircolors -b ~/.dircolors)" || eval "$(dircolors -b)"
  alias grep='grep --color=auto'
  alias fgrep='fgrep --color=auto'
  alias egrep='egrep --color=auto'
fi

# ls family — eza (if installed) upgrades it in place: icons, git status column,
# directories grouped first. Same muscle memory (ll/la/l), prettier output;
# falls back to the classic bash aliases without it.
if command -v eza >/dev/null; then
  alias ls='eza --group-directories-first --icons=auto'
  alias ll='eza -la --group-directories-first --icons=auto --git'
  alias la='eza -a --group-directories-first --icons=auto'
  alias l='eza -F --group-directories-first --icons=auto'  # -F: classify, like the old ls -CF
  alias l.='eza -d .* --icons=auto'         # just dotfiles
  alias lt='eza --tree --level=2 --icons=auto --group-directories-first'
else
  alias ls='ls --color=auto'
  alias ll='ls -alF'
  alias la='ls -A'
  alias l='ls -CF'
  alias l.='ls -d .*'
fi

# bat is packaged as batcat on Debian/Ubuntu/Mint — give it its real name
if ! command -v bat >/dev/null && command -v batcat >/dev/null; then
  alias bat='batcat'
fi

# man pages in Blossom colours: gold headings/bold, blue underline (options),
# search hits on a pink standout. GROFF_NO_SGR makes groff emit the old-style
# attributes these LESS_TERMCAP overrides hook into.
export GROFF_NO_SGR=1
export LESS_TERMCAP_md=$'\e[1;38;2;241;191;64m'
export LESS_TERMCAP_me=$'\e[0m'
export LESS_TERMCAP_us=$'\e[4;38;2;54;200;255m'
export LESS_TERMCAP_ue=$'\e[0m'
export LESS_TERMCAP_so=$'\e[48;2;219;55;118;38;2;234;246;255m'
export LESS_TERMCAP_se=$'\e[0m'

# from ~/.bash_aliases
alias claude='claude --dangerously-skip-permissions'
nexus() { command hermes "$@"; }   # 'nexus' is the home name for hermes

# --- extras you might like ---
alias ..='cd ..'
alias ...='cd ../..'
alias ....='cd ../../..'
alias path='print -l $path'               # PATH, one entry per line
alias reload='exec zsh'                   # reload the shell in place
alias h='history'
alias please='sudo $(fc -ln -1)'          # re-run last command with sudo
alias serve='python3 -m http.server'      # quick static server in $PWD

# git shorthands
alias g='git'
alias gs='git status -sb'
alias gl='git log --oneline --graph --decorate -20'
alias gd='git diff'
alias ga='git add'
alias gc='git commit'
alias gp='git push'
alias gco='git checkout'

# mkdir + cd into it
mkcd() { mkdir -p -- "$1" && cd -- "$1"; }
# extract most archive types
extract() {
  case "$1" in
    *.tar.bz2|*.tbz2) tar xjf "$1" ;;
    *.tar.gz|*.tgz)   tar xzf "$1" ;;
    *.tar.xz)         tar xJf "$1" ;;
    *.tar)            tar xf  "$1" ;;
    *.zip)            unzip   "$1" ;;
    *.gz)             gunzip  "$1" ;;
    *.7z)             7z x    "$1" ;;
    *) echo "extract: don't know how to handle '$1'" ;;
  esac
}
