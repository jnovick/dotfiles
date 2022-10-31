# vim:ft=zsh ts=2 sw=2 sts=2
#
# Inspired by agnoster's Theme - https://gist.github.com/3712874
# A Powerline-inspired theme for ZSH
#
# # README
#
# In order for this theme to render correctly, you will need a
# [Powerline-patched font](https://github.com/Lokaltog/powerline-fonts).
# # Goals
#
# The aim of this theme is to only show you *relevant* information. Like most
# prompts, it will only show git information when in a git working directory.
# However, it goes a step further: everything from the current user and
# hostname to whether the last call exited with an error to whether background
# jobs are running in this shell will all be displayed automatically when
# appropriate.

zstyle ':completion:*:directory-stack' list-colors '=(#b) #([0-9]#)*( *)==95=38;5;12'

### Segment drawing
# A few utility functions to make it easy and re-usable to draw segmented prompts

CURRENT_BG='NONE'
NEWLINE='
'
PROMPTCHAR='$'
[[ $UID -eq 0 ]] && PROMPTCHAR='#'


case ${SOLARIZED_THEME:-dark} in
    light) CURRENT_FG='white';;
    *)     CURRENT_FG='black';;
esac

# Special Powerline characters

() {
  local LC_ALL="" LC_CTYPE="en_US.UTF-8"
  # NOTE: This segment separator character is correct.  In 2012, Powerline changed
  # the code points they use for their special characters. This is the new code point.
  # If this is not working for you, you probably have an old version of the
  # Powerline-patched fonts installed. Download and install the new version.
  # Do not submit PRs to change this unless you have reviewed the Powerline code point
  # history and have new information.
  # This is defined using a Unicode escape sequence so it is unambiguously readable, regardless of
  # what font the user is viewing this source code in. Do not replace the
  # escape sequence with a single literal character.
  # Do not change this! Do not make it '\u2b80'; that is the old, wrong code point.
  SEGMENT_SEPARATOR=$'\ue0b0' # 

  # More options:

  # '\ue0a0' -     '\ue0b0' -     '\ue0c0' -     '\ue0d0' - 
  # '\ue0a1' -     '\ue0b1' -     '\ue0c1' -     '\ue0d1' - 
  # '\ue0a2' -     '\ue0b2' -     '\ue0c2' -     '\ue0d2' - 
  # '\ue0a3' -     '\ue0b3' -     '\ue0c3' - 
  # '\ue0c3' -     '\ue0b4' -     '\ue0c4' -     '\ue0d4' - 
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

}

# Begin a segment
# Takes two arguments, background and foreground. Both can be omitted,
# rendering default background/foreground.
prompt_segment() {
  local bg fg
  [[ -n $1 ]] && bg="%K{$1}" || bg="%k"
  [[ -n $2 ]] && fg="%F{$2}" || fg="%f"
  if [[ $CURRENT_BG != 'NONE' && $1 != $CURRENT_BG ]]; then
    echo -n " %{$bg%F{$CURRENT_BG}%}$SEGMENT_SEPARATOR%{$fg%} "
  else
    echo -n "%{$bg%}%{$fg%} "
  fi
  CURRENT_BG=$1
  [[ -n $3 ]] && echo -n $3
}

# End the prompt, closing any open segments
prompt_end() {
  if [[ -n $CURRENT_BG ]]; then
    echo -n " %{%k%F{$CURRENT_BG}%}$SEGMENT_SEPARATOR"
  else
    echo -n "%{%k%}"
  fi
  echo -n "%{%f%}"
  CURRENT_BG=''
  #echo -n $NEWLINE$PROMPTCHAR
}

### Prompt components
# Each component will draw itself, and hide itself if no information needs to be shown

# Context: user@hostname (who am I and where am I)
prompt_context() {
  if [[ "$USER" != "$DEFAULT_USER" || -n "$SSH_CLIENT" ]]; then
    prompt_segment black default "%(!.%{%F{yellow}%}.)%{%F{green}%}%n%{%F{default}%}@%{%F{cyan}%}%m"
  fi
}

# Git: branch/detached head, dirty status
prompt_git() {
  (( $+commands[git] )) || return
  if [[ "$(git config --get oh-my-zsh.hide-status 2>/dev/null)" = 1 ]]; then
    return
  fi
  local PL_BRANCH_CHAR
  () {
    local LC_ALL="" LC_CTYPE="en_US.UTF-8"
    PL_BRANCH_CHAR=$'\ue0a0'         # 
  }
  local ref dirty mode repo_path bg

  if $(git rev-parse --is-inside-work-tree >/dev/null 2>&1); then
    repo_path=$(git rev-parse --git-dir 2>/dev/null)
    dirty=$(parse_git_dirty)
    ref=$(git symbolic-ref HEAD 2> /dev/null) || ref="➦ $(git rev-parse --short HEAD 2> /dev/null)"
    if [[ -n $dirty ]]; then
      bg=yellow
    else
      bg=white
    fi

    prompt_segment $bg black

    if [[ -e "${repo_path}/BISECT_LOG" ]]; then
      mode=" <B>"
    elif [[ -e "${repo_path}/MERGE_HEAD" ]]; then
      mode=" >M<"
    elif [[ -e "${repo_path}/rebase" || -e "${repo_path}/rebase-apply" || -e "${repo_path}/rebase-merge" || -e "${repo_path}/../.dotest" ]]; then
      mode=" >R>"
    fi

    setopt promptsubst
    autoload -Uz vcs_info

    zstyle ':vcs_info:*' enable git
    zstyle ':vcs_info:*' get-revision true
    zstyle ':vcs_info:*' check-for-changes true
    zstyle ':vcs_info:*' stagedstr '✚'
    zstyle ':vcs_info:*' unstagedstr '●'
    zstyle ':vcs_info:*' formats ' %u%c'
    zstyle ':vcs_info:*' actionformats ' %u%c'

    vcs_info
    echo -n "${ref/refs\/heads\//$PL_BRANCH_CHAR }${vcs_info_msg_0_%% }${mode}"
  fi
}

rprompt_git_tracking() {
  (( $+commands[git] )) || return
  if [[ "$(git config --get oh-my-zsh.hide-status 2>/dev/null)" = 1 ]]; then
    return
  fi

  if $(git rev-parse --is-inside-work-tree >/dev/null 2>&1); then
    remote=$(git for-each-ref --format='%(upstream:short)' $(git symbolic-ref -q HEAD))
    remote_main_branch=origin/$(git_remote_branch)

    if [[ $remote != '' ]]; then
      ahead=$(git rev-list "$remote..HEAD" --count 2> /dev/null)
      behind=$(git rev-list "HEAD..$remote" --count 2> /dev/null)

      [[ $ahead -gt 0 ]] && prompt_segment $CURRENT_BG green "$ahead↑"
      [[ $behind -gt 0 ]] && prompt_segment $CURRENT_BG red "$behind↓"

      tracking_length=${#remote}
      main_length=${#remote_main_branch}
      length=$(( tracking_length > main_length ? tracking_length : main_length ))

      echo -n "%{%f%}  ${(l:$length:: :)${remote}}"
    fi
  fi
}

rprompt_git_main() {
  (( $+commands[git] )) || return
  if [[ "$(git config --get oh-my-zsh.hide-status 2>/dev/null)" = 1 ]]; then
    return
  fi

  if $(git rev-parse --is-inside-work-tree >/dev/null 2>&1); then
    remote=$(git for-each-ref --format='%(upstream:short)' $(git symbolic-ref -q HEAD))

    remote_main_branch=origin/$(git_remote_branch)

    if [[ $remote != $remote_main_branch && ! -z $(git branch -rl $remote_main_branch) ]]; then
      ahead=$(git rev-list "$remote_main_branch..HEAD" --count 2> /dev/null)
      behind=$(git rev-list "HEAD..$remote_main_branch" --count 2> /dev/null)

      [[ $ahead -gt 0 ]] && prompt_segment $CURRENT_BG green "$ahead↑"
      [[ $behind -gt 0 ]] && prompt_segment $CURRENT_BG red "$behind↓"

      tracking_length=${#remote}
      main_length=${#remote_main_branch}
      length=$(( tracking_length > main_length ? tracking_length : main_length ))

      echo -n "%{%f%}  ${(l:$length:: :)${remote_main_branch}}"
    fi
  fi
}

# Dir: current working directory
prompt_dir() {
  width=$(($COLUMNS / 5))
  prompt_segment green black "%${width}<...<%2~%<<"
}

# Status:
# - was there an error
# - am I root
# - are there background jobs?
prompt_status() {
  local -a symbols

  [[ $RETVAL -ne 0 ]] && symbols+="%{%F{red}%}✘"
  [[ $UID -eq 0 ]] && symbols+="%{%F{yellow}%}⚡"
  [[ $(jobs -l | wc -l) -gt 0 ]] && symbols+="%{%F{cyan}%}⚙"

  [[ -n "$symbols" ]] && prompt_segment black default "$symbols"
}

prompt_kubecontext() {
    (( $+commands[kubectl] )) || return
    prompt_segment cyan black `printf "\u2388\u00A0$(kubectl config current-context):$(kubectl config view --minify --output 'jsonpath={..namespace}')"`
}

prompt_pulumi() {
  if [[ -f Pulumi.yaml && ( -d .pulumi || "$PULUMI_CONFIG_PASSPHRASE" != '' ) ]]; then
    BACKEND=$(jq -r '.current' $HOME/.pulumi/credentials.json 2> /dev/null)

    if [[ "${BACKEND#*azblob://}" != "$BACKEND" ]]; then
      BACKEND=$(echo $BACKEND | sed 's|azblob://pulumi-\(.*\)-state|\1|')
    else
      BACKEND=$(echo $BACKEND | sed "s|file:///home/$USER/git|file:...|")
    fi

    STACK=$(yq e .stack $HOME/.pulumi/workspaces/$(yq e '.name' Pulumi.yaml)-*-workspace.json(N) 2> /dev/null)
    prompt_segment magenta black "$BACKEND"

    if [[ $STACK != '' ]]; then
      prompt_segment magenta black ""
      prompt_segment magenta black "$STACK"
    fi
  fi
}

displaytime() {
  local T=$1
  local D=$((T/60/60/24))
  local H=$((T/60/60%24))
  local M=$((T/60%60))
  local S=$((T%60))
  [[ $D > 0 ]] && printf '%dd ' $D
  [[ $H > 0 ]] && printf '%dh ' $H
  [[ $M > 0 ]] && printf '%dm ' $M
  [[ $S > 0 ]] && printf '%ds' $S
}

prompt_time() {
  prompt_segment black white '%D{%r}'
}

prompt_cmd_exec_time() {
  [ $last_exec_duration -gt 5 ] && prompt_segment yellow black "$(displaytime $last_exec_duration)"
}

preexec() {
  cmd_timestamp=`date +%s`
}

precmd() {
  local stop=`date +%s`
  local start=${cmd_timestamp:-$stop}
  let last_exec_duration=$stop-$start
  cmd_timestamp=''
}

prompt-length() {
  emulate -L zsh
  local -i COLUMNS=${2:-COLUMNS}
  local -i x y=${#1} m
  if (( y )); then
    while (( ${${(%):-$1%$y(l.1.0)}[-1]} )); do
      x=y
      (( y *= 2 ))
    done
    while (( y > x + 1 )); do
      (( m = x + (y - x) / 2 ))
      (( ${${(%):-$1%$m(l.x.y)}[-1]} = m ))
    done
  fi
  echo $x
}

fill-line() {
  emulate -L zsh
  local -i left_len=$(prompt-length $1)
  local -i right_len=$(prompt-length $2 9999)
  local -i pad_len=$((COLUMNS - left_len - right_len - ${ZLE_RPROMPT_INDENT:-1}))
  if (( pad_len < 1 )); then
    # Not enough space for the right part. Drop it.
    echo $1
  else
    local pad=${(pl.$pad_len.. .)}  # pad_len spaces
    echo ${1}${pad}${2}
  fi
}

## Main prompt
build_prompt() {
  RETVAL=$?
  prompt_status
  prompt_time
  prompt_context
  prompt_dir
  prompt_git
  prompt_kubecontext
  prompt_pulumi
  prompt_cmd_exec_time
  prompt_end
}

PROMPT='$NEWLINE$(fill-line "$(build_prompt)" "$(rprompt_git_main)")$NEWLINE$PROMPTCHAR '
RPROMPT='$(rprompt_git_tracking)'
