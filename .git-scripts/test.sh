#!/bin/zsh

get_group () {
  id=`az ad group show --group $1 -o tsv --query 'id' 2>/dev/null`
  echo "$1: $id"
}

typeset -A services=(
  #'core' '70bdf3b6-35a9-46f1-9cbb-b882e1494533' # Agile Team Focus
  'core' '6143af97-57a6-42d9-aef2-15df7f8065eb' # agile team lean coders
  'inv' '2b048d82-956f-468e-8b77-f5a77e7ab847' # Agile Team Medusa
  'tds' '2b048d82-956f-468e-8b77-f5a77e7ab847' # Agile Team Medusa
  'play' '702daafb-e7ae-4596-b667-5cd3b4bedb50' # Agile Team Future
  'e2g' '567f8131-1720-491b-98cc-849535936c00' # agile peregrine team
  'mbt' '1320dad2-253f-418f-b798-0d59f3043f11' # Agile Team Builder
  'iris' 'edaf6337-3fb5-460a-b3db-465f230cba0d' # agile team soa
  'sap' '07de3f2d-2138-435c-9070-584d41acee6e' # Agile Team United
)

environments=( 'dev' 'stg' 'prod' )

for env in $environments; do
  echo "---------- $env ----------"
  get_group "platform-traviata-$env-admin"
  get_group "platform-traviata-$env-reader"

  for key val in "${(@kv)services}"; do
    get_group "platform-$key-$env-admin"
    get_group "platform-$key-$env-reader"
  done
done
