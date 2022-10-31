#export NVM_DIR="$HOME/.nvm"
#[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
#[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion

if command -v kubectl &> /dev/null
then
    source <(kubectl completion zsh) # The kubectl plugin is not already doing this for me
fi

_nuke_zsh_complete()
{
  local completions=("$(nuke :complete "$words")")
  reply=( "${(ps:\n:)completions}" )
}

compctl -K _nuke_zsh_complete nuke
