# env.zsh — login environment (PATH + tool inits), mirrored from the existing
# bash setup so nothing breaks. Sourced by both ~/.zprofile (login) and init.zsh
# (interactive). `typeset -U` keeps PATH de-duplicated no matter how often it runs.

typeset -U path PATH

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
