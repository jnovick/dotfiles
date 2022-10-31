# Docker automatically installs an older version at /usr/local/bin/kubectl
# but we want to point at correct newer version
# Only do this though if the version we want exists
[[ -f "/usr/bin/kubectl" ]] && alias kubectl='/usr/bin/kubectl'

kubesecretdecodetemplate="{{\"-----------------------------------\n\"}}{{.metadata.name}}{{\"\n-----------------------------------\n\"}}{{range \$k,\$v := .data}}{{printf \"%s: \" \$k}}{{if not \$v}}{{\$v}}{{else}}{{\$v | base64decode}}{{end}}{{\"\n\n\"}}{{end}}"
alias decode="kubectl get secret -o go-template='{{if .items}}{{range .items}}$kubesecretdecodetemplate{{\"\n\"}}{{end}}{{else}}$kubesecretdecodetemplate{{end}}'"

alias unseal='kubeseal -o yaml --recovery-unseal --recovery-private-key <(kubectl get secret -n kube-system sealed-secrets-key -o yaml)'

resetk8s(){
  kubectl config use-context plat-neu-dev-001-aks

  for user in $(kubectl config get-users | tail -n +2); do
    kubectl config set-credentials $user --auth-provider-arg=config-mode=1 --auth-provider-arg=access-token- --auth-provider-arg=expires-in- --auth-provider-arg=expires-on- --auth-provider-arg=refresh-token- > /dev/null
  done
}

generate_crd_role(){
  CRD=`kubectl get crd -o jsonpath='{range .items[*]}{.metadata.name}{","}{end}' | sed 's/,*$//g'`

  kubectl create role custom-resource-edit-role --verb=get,list,watch,create,delete,deletecollection,patch,update --resource=$CRD --dry-run=client -o yaml | \
  kubectl label -f /dev/stdin --dry-run=client rbac.authorization.k8s.io/aggregate-to-admin=true rbac.authorization.k8s.io/aggregate-to-edit=true --local -o yaml > crd-role-edit.yaml

  kubectl create role custom-resource-view-role --verb=get,list,watch --resource=$CRD --dry-run=client -o yaml | \
  kubectl label -f /dev/stdin --dry-run=client rbac.authorization.k8s.io/aggregate-to-view=true --local -o yaml > crd-role-view.yaml
}

alias kn='kubectl -n'
alias ksn='kcsc --current --namespace'

_get_aks_credentials_in_sub(){
  local rg name prv_dns dns_entry
  for id in $(az aks list --subscription $1 --query='[*].id' -o tsv); do
    rg=$(echo $id | sed 's|.*/resourcegroups/\(.*\)/providers/.*|\1|')
    name=$(echo $id | sed 's|.*/managedClusters/\(.*\)|\1|')

    az aks get-credentials --resource-group $rg --name $name --subscription $1

    prv_dns=$(az aks show --resource-group $rg --name $name --subscription $1 --query "apiServerAccessProfile.privateDnsZone" -o tsv)

    if [[ $prv_dns != '' ]]; then
      rg=$(echo $prv_dns | sed 's|.*/resourceGroups/\(.*\)/providers/.*|\1|')
      name=$(echo $prv_dns | sed 's|.*/privateDnsZones/\(.*\)|\1|')

      dns_entry=$(az network private-dns record-set a list --resource-group $rg --subscription $1 --zone-name $name --query='[].{Ip:aRecords[0].ipv4Address,Fqdn:fqdn}' -o tsv)
      grep -qxF $dns_entry /etc/hosts || echo $dns_entry | sudo tee --append /etc/hosts
      grep -qxF $dns_entry /mnt/c/Windows/System32/drivers/etc/hosts || echo $dns_entry | sudo tee --append /mnt/c/Windows/System32/drivers/etc/hosts
    fi
  done

  cp $HOME/.kube/config /mnt/c/Users/josno/.kube/config
}

get_all_aks_credentials(){
  for sub in $(az account list --all --query='[*].id' -o tsv); do
    _get_aks_credentials_in_sub $sub
  done
}

get_cloud_aks_credentials(){

  SUBS=(
    'Cloud Operations'
    'Tricentis Enterprise Cloud'
    'Tricentis Enterprise Cloud Dev/Test'
  )

  for sub in $SUBS; do
    _get_aks_credentials_in_sub $sub
  done
}

get_aks_public_ip(){

  while true; do
    case "$1" in
      --help | -h ) HELP=true; shift ;;
      -s | --subscription ) LOCAL=true; shift ;;
      -rg | --resource-group ) USE_PASSWORD=true; export PULUMI_CONFIG_PASSPHRASE=$2; shift 2 ;;
      -n | --name ) USE_PASSWORD=true; export PULUMI_CONFIG_PASSPHRASE=$2; shift 2 ;;
      -- ) shift; break ;;
      * ) CONTEXT=$1; break ;;
    esac
  done
}

restart_namespace(){
  deploys=`kubectl get deployments -n $1 --no-headers | cut -d ' ' -f 1`
  for deploy in $deploys; do
    kubectl rollout restart deployments/$deploy -n $1
  done
}

# kubectl rollout restart -n core deployment/administration-api
# kubectl rollout restart -n core deployment/administration-ui
# kubectl rollout restart -n core deployment/authorizationservice-api
# kubectl rollout restart -n core deployment/billingservice-api
# kubectl rollout restart -n core deployment/downloadservice-api
# kubectl rollout restart -n core deployment/new-administration-core-administration-api
# kubectl rollout restart -n core deployment/new-administration-core-administration-ui
# kubectl rollout restart -n core deployment/new-authorizationservice-core-authorizationservice-api
# kubectl rollout restart -n core deployment/new-downloadservice-core-downloadservice-api
# kubectl rollout restart -n core deployment/new-notificationservice-core-notificationservice-api
# kubectl rollout restart -n core deployment/new-ocelotproxy
# kubectl rollout restart -n core deployment/new-oktaservice-core-oktaservice-api
# kubectl rollout restart -n core deployment/new-onboardservice-core-onboardservice-api
# kubectl rollout restart -n core deployment/new-onboardservice-core-onboardservice-react
# kubectl rollout restart -n core deployment/new-organizationservice-core-organizationservice-api
# kubectl rollout restart -n core deployment/new-portalservice-core-portalservice-ui
# kubectl rollout restart -n core deployment/new-processservice-core-processservice-api
# kubectl rollout restart -n core deployment/new-processservice-core-processservice-worker
# kubectl rollout restart -n core deployment/new-swaggeraggregator
# kubectl rollout restart -n core deployment/new-topologyservice-core-topologyservice-api
# kubectl rollout restart -n core deployment/notificationservice-api
# kubectl rollout restart -n core deployment/ocelotproxy
# kubectl rollout restart -n core deployment/oktaservice-api
# kubectl rollout restart -n core deployment/onboardservice-api
# kubectl rollout restart -n core deployment/onboardservice-react
# kubectl rollout restart -n core deployment/organizationservice-api
# kubectl rollout restart -n core deployment/portalservice-ui
# kubectl rollout restart -n core deployment/processservice-api
# kubectl rollout restart -n core deployment/processservice-worker
# kubectl rollout restart -n core deployment/swaggeraggregator
# kubectl rollout restart -n core deployment/topologyservice-api

cp $HOME/.kube/config /mnt/c/Users/josno/.kube/config
