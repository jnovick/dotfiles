#!/bin/bash

SCRIPTPATH=$(dirname $(readlink -f "$0") )

FILES=(
  .kube
  .nuget
  .oh-my-zsh-custom
  .git-scripts
  .gitconfig
  .npmrc
  .tmux.conf
  .vimrc
  .yarnrc
  .zshrc
  vpn-fix.bash # Not a dotfile but we want the symlink here
  un-vpn-fix.bash # Not a dotfile but we want the symlink here
)

for FILE in ${FILES[@]}; do
  if [[ ! ( -L "$HOME/$FILE" && $SCRIPTPATH/$FILE ==  $(readlink -f "$HOME/$FILE") ) ]]; then
    if [[ ( -f "$HOME/$FILE" || -d "$HOME/$FILE" ) ]]; then
      BACKUP=$HOME/$FILE.$(date +"%Y_%m_%d_%I_%M_%p").bak
      echo "Backing up $HOME/$FILE as $BACKUP"
      mv $HOME/$FILE $BACKUP
    fi

    echo "Linking $SCRIPTPATH/$FILE to $HOME/$FILE"
    ln -sf $SCRIPTPATH/$FILE ~/$FILE

    fi
done

chmod -R 600 $HOME/.kube/config
# chmod -R 777 $HOME/.nuget
# chmod -R 666 $HOME/.nuget/NuGet/NuGet.Config
chmod 700 -R $HOME/.git-scripts
# chmod -R 666 $HOME/.gitconfig
chmod 600 $HOME/.npmrc
# chmod -R 666 $HOME/.tmux.conf
chmod 600 $HOME/.yarnrc # Mine was 666, not sure why anyone else need to be able to read/write so changing to 600
chmod 644 $HOME/.zshrc

chmod +x /home/$USER/vpn-fix.bash
