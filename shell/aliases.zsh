# aliases.zsh — your bash aliases, carried over verbatim, plus a few extras.

# colour ls/grep (same as bash)
if [[ -x /usr/bin/dircolors ]]; then
  [[ -r ~/.dircolors ]] && eval "$(dircolors -b ~/.dircolors)" || eval "$(dircolors -b)"
  alias ls='ls --color=auto'
  alias grep='grep --color=auto'
  alias fgrep='fgrep --color=auto'
  alias egrep='egrep --color=auto'
fi

# from ~/.bashrc
alias ll='ls -alF'
alias la='ls -A'
alias l='ls -CF'

# from ~/.bash_aliases
alias claude='claude --dangerously-skip-permissions'
nexus() { command hermes "$@"; }   # 'nexus' is the home name for hermes

# --- extras you might like ---
alias ..='cd ..'
alias ...='cd ../..'
alias ....='cd ../../..'
alias l.='ls -d .*'                       # just dotfiles
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
