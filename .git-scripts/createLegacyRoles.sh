#!/bin/zsh

createRoleBinding () {
  id=`az ad group show --group "platform-$1-$2-admin" -o tsv --query 'id' 2>/dev/null`
  echo "kubectl create rolebinding $1-admin-edit -n $3 --group=$id --clusterrole=edit --context plat-neu-$2-001-aks"
  kubectl create rolebinding $1-admin-edit -n $3 --group=$id --clusterrole=edit --context plat-neu-$2-001-aks

  id=`az ad group show --group "platform-$1-$2-reader" -o tsv --query 'id' 2>/dev/null`
  echo "kubectl create rolebinding $1-reader-view -n $3 --group=$id --clusterrole=view --context plat-neu-$2-001-aks"
  kubectl create rolebinding $1-reader-view -n $3 --group=$id --clusterrole=view --context plat-neu-$2-001-aks
}

services=( 'core' 'inv' 'tds' 'play' 'e2g' 'mbt' 'iris' 'sap' )

environments=( 'dev' 'stg' 'prod' )

for env in $environments; do
  echo "---------- $env ----------"
  for service in $services; do
    createRoleBinding "traviata" $env "$service"
    createRoleBinding "$service" $env "$service"
  done
done

for env in $environments; do
  echo "---------- $env (dex/e2g) ----------"
  createRoleBinding "traviata" $env "dex"
  createRoleBinding "e2g" $env "dex"
done
