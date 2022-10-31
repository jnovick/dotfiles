export PATH=$PATH:$HOME/.pulumi/bin
source <(pulumi gen-completion zsh)

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
      -p | --password ) USE_PASSWORD=true; export PULUMI_CONFIG_PASSPHRASE=$2; shift 2 ;;
      -s | --stack ) STACK=$2; shift 2 ;;
      -- ) shift; break ;;
      * ) CONTEXT=$1; break ;;
    esac
  done

  local -a show_help_text

  show_help_text(){
    CONTEXTS=$(az keyvault secret list --subscription '11cf0077-bfb8-4091-b0ea-74a22e21a53d' --vault-name 'tplat-sre-global-kv' --query="[?starts_with(name,'pulumi-stack-passphrase')].name" -o tsv | sed 's/pulumi-stack-passphrase-\(.*\)/\t- \\033[0;35m\1\\033[0;37m/' 2> /dev/null || echo )

    echo "Help Info:"
    echo "__________"
    echo
    echo "Usage: \033[0;33mset_pulumi_context\033[0;37m [\033[0;34m--local\033[0;37m] [\033[0;34m--help\033[0;37m|\033[0;34m-h\033[0;37m] [\033[0;34m--password\033[0;37m=\033[0;35mstring\033[0;37m] [\033[0;35mcontext\033[0;37m]"

    if [[ $CONTEXTS != '' ]]; then
      echo "Possible values for context:"
      echo -e "$CONTEXTS"
    fi

    echo
    echo "When accessing pulumi backends stored in Azure storage accounts,"
    echo "ensure you are logged into Azure before running. If you aren't, this command will run \033[0;33maz login\033[0;37m."
    echo "This will set \033[0;32mPULUMI_CONFIG_PASSPHRASE\033[0;37m, \033[0;32mAZURE_STORAGE_ACCOUNT\033[0;37m, and \033[0;32mAZURE_STORAGE_KEY\033[0;37m"
    echo "and then run \033[0;33mpulumi login \033[0;34m--cloud-url\033[0;37m with the appropriate cloud url"
    echo
    echo "For a local pulumi backend, you should also specify a password. The local option automatically scans all parent directories for a pulumi backend folder"
    echo
    echo "Either \033[0;34m--local\033[0;37m or \033[0;35mcontext\033[0;37m must be provided"
    echo
    echo "Example usage: \033[0;33mset_pulumi_context\033[0;37m \033[0;35miris\033[0;37m"
    echo "Example usage: \033[0;33mset_pulumi_context\033[0;37m \033[0;34m--password\033[0;37m \033[0;35m''\033[0;37m \033[0;34m--local\033[0;37m"

    return
  }

  if [[ $HELP == 'true' ]]; then
    show_help_text
    return
  fi

  #rm $HOME/.pulumi/workspaces/$(yq e '.name' Pulumi.yaml)-*-workspace.json(N) 2> /dev/null

  if [[ $LOCAL == 'true' ]]; then
    DIR=$(dirname $(readlink -f "$0") )

    while [[ $DIR != "/" && ! -d "$DIR/.pulumi" ]]; do
      DIR=$(readlink -f "$DIR/..")
    done

    if [[ $USE_PASSWORD == 'false' ]]; then
      echo -e "\033[0;33mWARNING:\033[0;37m No password was supplied while using the \033[0;34m--local\033[0;37m option. Defaulting to empty string."
      export PULUMI_CONFIG_PASSPHRASE=""
    fi

    if [[ $DIR == '/' ]]; then
      echo -e "\033[0;31mERROR:\033[0;37m No \033[0;34m.pulumi/\033[0;37m directory located in the current directory nor any parent directory"
    fi

    pulumi login "file://$DIR"

    if [[ $STACK != "" ]]; then
      pulumi stack select $STACK
    fi

    return
  fi

  if [[ $CONTEXT == '' ]]; then
    echo -e "\033[0;31mERROR:\033[0;37m Either \033[0;34m--local\033[0;37m or a \033[0;34mcontext\033[0;37m must be provided"
    show_help_text
    return -1
  fi

  az account show > /dev/null 2> /dev/null || az login

  if [[ $USE_PASSWORD == 'false' ]]; then
    export PULUMI_CONFIG_PASSPHRASE=$(az keyvault secret show --subscription '11cf0077-bfb8-4091-b0ea-74a22e21a53d' --vault-name 'tplat-sre-global-kv' --name "pulumi-stack-passphrase-$CONTEXT" --query='@.value' -o tsv 2> /dev/null || echo "INVALID CONTEXT")

    if [[ $PULUMI_CONFIG_PASSPHRASE == 'INVALID CONTEXT' ]]; then
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

  if [[ $STACK != "" ]]; then
    pulumi stack select $STACK
  fi
}
