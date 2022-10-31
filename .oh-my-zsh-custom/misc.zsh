if [[ "$PWD" = "/c/Windows/System32" ]]; then
  cd ~
fi

if [[ "$PWD" = "/mnt/c/Windows/System32" ]]; then
  cd ~
fi

export PATH=$PATH:$HOME/.local/bin
export PATH=$PATH:/usr/local/go/bin
export PATH=$PATH:$HOME/.dotnet/tools

cp -r ~/.ssh /mnt/c/Users/josno/.ssh

# This is an altered version of git_main_branch
git_remote_branch() {
  command git rev-parse --git-dir &> /dev/null || return
  local ref
  for ref in refs/remotes/origin/{main,trunk,releases/ops}
  do
    if command git show-ref -q --verify $ref
    then
      echo $ref | sed -e 's|refs/remotes/origin/\(.*\)|\1|'
      return
    fi
  done
  echo master
}

pr() {
  local URL="https://tricentis.visualstudio.com/"
  URL="$URL$(pwd | sed "s|$HOME\/git\/\([^/]*\).*|\1|g")/_git/"
  URL="$URL$(pwd | sed "s|$HOME/git/[^/]*/\([^/]*\).*|\1|g")/"
  URL="${URL}pullrequestcreate?sourceRef=$(git rev-parse --abbrev-ref HEAD)&"
  URL="${URL}targetRef=$(git_remote_branch)"

  echo $URL
}

print_powerline_characters(){
  for c4 in {0..9} {a..f}; do
    for c3 in {a..d}; do
      echo -n "\\\ue0${c3}${c4} - \\ue0${c3}${c4}    "
    done
    echo
  done
}

  # '\ue0a0' -     '\ue0b0' -     '\ue0c0' -     '\ue0d0' - 
  # '\ue0a1' -     '\ue0b1' -     '\ue0c1' -     '\ue0d1' - 
  # '\ue0a2' -     '\ue0b2' -     '\ue0c2' -     '\ue0d2' - 
  # '\ue0a3' -     '\ue0b3' -     '\ue0c3' - 
  #                 '\ue0b4' -     '\ue0c4' -     '\ue0d4' - 
  #                 '\ue0b5' -     '\ue0c5' - 
  #                 '\ue0b6' -     '\ue0c6' - 
  #                 '\ue0b7' -     '\ue0c7' - 
  #                 '\ue0b8' -     '\ue0c8' - 
  #                 '\ue0b9' - 
  #                 '\ue0ba' -     '\ue0ca' - 
  #                 '\ue0bb' - 
  #                 '\ue0bc' -     '\ue0cc' - 
  #                 '\ue0bd' -     '\ue0cd' - 
  #                 '\ue0be' -     '\ue0ce' - 
  #                 '\ue0bf' -     '\ue0cf' - 
