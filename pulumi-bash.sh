export PATH=$PATH:$HOME/.pulumi/bin
source <(pulumi gen-completion bash)

set_pulumi_context(){
  CONTEXT=""
  HELP=false
  LOCAL=false
  USE_PASSWORD=false
  STACK=""

  while true; do
    case "$1" in
      --help | -h ) HELP=true; shift ;;
      -l | --local ) LOCAL=true; shift ;;
      -p | --password ) USE_PASSWORD=true; export PULUMI_CONFIG_PASSPHRASE="$2"; shift 2 ;;
      -s | --stack ) STACK="$2"; shift 2 ;;
      -- ) shift; break ;;
      * ) CONTEXT="$1"; break ;;
    esac
  done

  local -a show_help_text

  show_help_text(){
    CONTEXTS=$(az keyvault secret list --subscription '11cf0077-bfb8-4091-b0ea-74a22e21a53d' --vault-name 'tplat-sre-global-kv' --query="[?starts_with(name,'pulumi-stack-passphrase')].name" -o tsv | sed 's/pulumi-stack-passphrase-\(.*\)/\t- \\033[0;35m\1\\033[0;37m/' 2> /dev/null || echo )

    echo "Help Info:"
    echo "__________"
    echo
    echo -e "Usage: \033[0;33mset_pulumi_context\033[0;37m [\033[0;34m--local\033[0;37m] [\033[0;34m--help\033[0;37m|\033[0;34m-h\033[0;37m] [\033[0;34m--password\033[0;37m=\033[0;35mstring\033[0;37m] [\033[0;34m--stack\033[0;37m=\033[0;35mstring\033[0;37m] [\033[0;35mcontext\033[0;37m]"

    if [[ $CONTEXTS != '' ]]; then
      echo "Possible values for context:"
      echo -e "$CONTEXTS"
    fi

    echo
    echo -e "When accessing pulumi backends stored in Azure storage accounts,"
    echo -e "ensure you are logged into Azure before running. If you aren't, this command will run \033[0;33maz login\033[0;37m."
    echo -e "This will set \033[0;32mPULUMI_CONFIG_PASSPHRASE\033[0;37m, \033[0;32mAZURE_STORAGE_ACCOUNT\033[0;37m, and \033[0;32mAZURE_STORAGE_KEY\033[0;37m"
    echo -e "and then run \033[0;33mpulumi login \033[0;34m--cloud-url\033[0;37m with the appropriate cloud url"
    echo
    echo -e "For a local pulumi backend, you should also specify a password. The local option automatically scans all parent directories for a pulumi backend folder"
    echo
    echo -e "Either \033[0;34m--local\033[0;37m or \033[0;35mcontext\033[0;37m must be provided"
    echo
    echo -e "Example usage: \033[0;33mset_pulumi_context\033[0;37m \033[0;35miris\033[0;37m"
    echo -e "Example usage: \033[0;33mset_pulumi_context\033[0;37m \033[0;34m--stack\033[0;37m \033[0;35mdev.northeurope.003 \033[0;35mspoke\033[0;37m"
    echo -e "Example usage: \033[0;33mset_pulumi_context\033[0;37m \033[0;34m--password\033[0;37m \033[0;35m''\033[0;37m \033[0;34m--local\033[0;37m"

    return
  }

  if [[ "$HELP" == 'true' ]]; then
    show_help_text
    return
  fi

  #rm $HOME/.pulumi/workspaces/$(yq e '.name' Pulumi.yaml)-*-workspace.json(N) 2> /dev/null

  if [[ "$LOCAL" == 'true' ]]; then
    DIR=$(dirname $(readlink -f "$0") )

    while [[ "$DIR" != "/" && ! -d "$DIR/.pulumi" ]]; do
      DIR=$(readlink -f "$DIR/..")
    done

    if [[ "$USE_PASSWORD" == 'false' ]]; then
      echo -e "\033[0;33mWARNING:\033[0;37m No password was supplied while using the \033[0;34m--local\033[0;37m option. Defaulting to empty string."
      export PULUMI_CONFIG_PASSPHRASE=""
    fi

    if [[ "$DIR" == '/' ]]; then
      echo -e "\033[0;31mERROR:\033[0;37m No \033[0;34m.pulumi/\033[0;37m directory located in the current directory nor any parent directory"
    fi

    pulumi login "file://$DIR"

    if [[ "$STACK" != "" ]]; then
      pulumi stack select $STACK
    fi

    return
  fi

  if [[ "$CONTEXT" == '' ]]; then
    echo -e "\033[0;31mERROR:\033[0;37m Either \033[0;34m--local\033[0;37m or a \033[0;34mcontext\033[0;37m must be provided"
    show_help_text
    return -1
  fi

  az account show > /dev/null 2> /dev/null || az login

  if [[ "$USE_PASSWORD" == 'false' ]]; then
    export PULUMI_CONFIG_PASSPHRASE=$(az keyvault secret show --subscription '11cf0077-bfb8-4091-b0ea-74a22e21a53d' --vault-name 'tplat-sre-global-kv' --name "pulumi-stack-passphrase-$CONTEXT" --query='@.value' -o tsv 2> /dev/null || echo "INVALID CONTEXT")

    if [[ "$PULUMI_CONFIG_PASSPHRASE" == 'INVALID CONTEXT' ]]; then
      echo -e "\033[0;31mERROR: \033[0;35m$CONTEXT\033[0;37m is not a valid \033[0;34mcontext\033[0;37m."
      export PULUMI_CONFIG_PASSPHRASE=''
      show_help_text
      return -1
    fi

    echo "PULUMI_CONFIG_PASSPHRASE has been set to $(print_password -s 3 $PULUMI_CONFIG_PASSPHRASE)"
  fi

  case "$CONTEXT" in
    e2g)
      export AZURE_STORAGE_ACCOUNT="dex2iacstate"
      CONTEXT="dex"
      ;;
    hub|shared|spoke|wan)
      export AZURE_STORAGE_ACCOUNT="olympiacstate"
      ;;
    legacy-spoke)
      export AZURE_STORAGE_ACCOUNT="olympiacstate"
      CONTEXT="olymp"
      ;;
    iris|core|visionai)
      export AZURE_STORAGE_ACCOUNT="${CONTEXT}iacstate"
      ;;
    visionai-hub)
      export AZURE_STORAGE_ACCOUNT="visionaiiacstate"
      ;;
  esac

  echo "Using storage account: $AZURE_STORAGE_ACCOUNT"
  export AZURE_STORAGE_KEY=$(az storage account keys list --account-name="$AZURE_STORAGE_ACCOUNT" --subscription='35e7279c-24e1-45c4-87be-a76776a62875' --query='[0].value' -o tsv)
  pulumi login --cloud-url "azblob://pulumi-$CONTEXT-state"

  if [[ "$STACK" != "" ]]; then
    pulumi stack select "$STACK"
  fi
}

_set_pulumi_context_bash_completion(){
  local cur prev opts
  COMPREPLY=()
  cur="${COMP_WORDS[COMP_CWORD]}"
  prev="${COMP_WORDS[COMP_CWORD-1]}"
  opts=(-h --help -l --local -p --password -s --stack)

  if [[ ${cur} == -* ]]; then

    for word in "${COMP_WORDS[@]}"; do
      if [[ "$word" == "-h" || "$word" == "--help" ]]; then
        opts=()
        break
      fi

      if [[ "$word" == "-l" || "$word" == "--local" ]]; then
        opts=(${opts[@]//*-l*})
        opts=(${opts[@]//*-h*})
      fi

      if [[ "$word" == "-p" || "$word" == "--password" ]]; then
        opts=(${opts[@]//*-p*})
        opts=(${opts[@]//*-h*})
      fi

      if [[ "$word" == "-s" || "$word" == "--stack" ]]; then
        opts=(${opts[@]//*-s*})
        opts=(${opts[@]//*-h*})
      fi
    done

  	COMPREPLY=( $(compgen -W "${opts[*]}" -- ${cur}) )
  	return 0
  fi

  case "${prev}" in
  	-p|--password)
  		COMPREPLY=()
  		;;
  	-s|--stack)
  		local stacks=$(ls | grep 'Pulumi\..*\.yaml' | sed 's/Pulumi\.\(.*\)\.yaml/\1/g')
  		COMPREPLY=( $(compgen -W "$stacks" -- ${cur}) )
  		;;
  	*)
  		az account show > /dev/null 2> /dev/null \
        && COMPREPLY=( $(compgen -W "$(az keyvault secret list --subscription '11cf0077-bfb8-4091-b0ea-74a22e21a53d' --vault-name 'tplat-sre-global-kv' --query="[?starts_with(name,'pulumi-stack-passphrase')].name" -o tsv | sed 's/pulumi-stack-passphrase-\(.*\)/\1/')" -- ${cur}) ) \
        || COMPREPLY=()
  	;;
  esac
}

__set_pulumi_context_caching_policy_zsh_completion() {
    oldp=( "$1"(Nmm+5) )     # Rebuild if older than 5 minutes
    (( $#oldp ))
}

__get_pulumi_contexts_zsh_completion() {
    local cache_policy

    zstyle -s ":completion:${curcontext}:" cache-policy cache_policy
    if [[ -z "$cache_policy" ]]; then
        zstyle ":completion:${curcontext}:" cache-policy __set_pulumi_context_caching_policy_zsh_completion
    fi

    if ( [[ ${+_contexts} -eq 0 ]] || _cache_invalid set_pulumi_context ) \
        && ! _retrieve_cache set_pulumi_context;
    then
        az account show > /dev/null 2> /dev/null && \
        _contexts=(${(f)"$(az keyvault secret list --subscription '11cf0077-bfb8-4091-b0ea-74a22e21a53d' --vault-name 'tplat-sre-global-kv' --query="[?starts_with(name,'pulumi-stack-passphrase')].name" -o tsv | sed 's/pulumi-stack-passphrase-\(.*\)/\1/')"}) && \
        _store_cache set_pulumi_context _contexts
    fi

    if [[ $_contexts != '' ]]; then
      _values 'set_pulumi_context' $_contexts
    fi
}

_set_pulumi_context()
{
  local -a contexts

  _arguments -A "-*" \
    '(--help -h --local -l)'{--local,-l}'[Recursively searches up directories for .pulumi/ backend. Password must be set manually with --password option]' \
    '(--help -h --password -p)'{--password,-p}'[Manually sets the password instead of pulling from cloud. When used with --local, it defaults to empty string]:password: ' \
    '(--help -h --local -l --password -p --stack -s)'{--help,-h}'[Display help text]:*:' \
    '(--help -h --stack -s)'{--stack,-s}"[Select a stack to point to]:stack:_values stack $(ls | grep 'Pulumi\..*\.yaml' | sed 's/Pulumi\.\(.*\)\.yaml/\1/g')" \
    ":context:__get_pulumi_contexts_zsh_completion"
}

if [[ "$(cat /proc/$$/cmdline)" == *"bash"* ]]; then
  complete -F _set_pulumi_context_bash_completion set_pulumi_context
elif [[ "$(cat /proc/$$/cmdline)" == *"zsh"* ]]; then
  compdef _set_pulumi_context set_pulumi_context
fi
