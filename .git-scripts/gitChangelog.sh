#! /bin/bash

RELEASE="FALSE"
DRY_RUN="FALSE"

while true; do
  case "$1" in
    -r | --release ) RELEASE="TRUE"; shift ;;
    -d | --release-dry-run ) DRY_RUN="TRUE"; shift ;;
    -- ) shift; break ;;
    * ) break ;;
  esac
done

TMP_CHANGELOG="$(mktemp)"
BASE_URL=$(git remote get-url origin | sed "s;git@ssh.dev.azure.com:v3/tricentis/cloud;https://dev.azure.com/tricentis/cloud/_git;" | sed "s;https://tricentis@dev;https://dev;")
FIRST_COMMIT=$(git rev-list --max-parents=0 HEAD | tail -n 1)

LATEST_TAG=$(git tag -l --sort=version:refname | tail -1)
NEXT_TAG=""

if [[ $(git log --format="%s" $LATEST_TAG..HEAD | grep -E '(feat|fix|refactor|docs|ci|test|style)(\(.+\))?!:') != '' || $(git log --format="%B" $LATEST_TAG..HEAD | grep -E 'BREAKING(\s|-)CHANGE:') != '' ]]; then
  NEXT_TAG=$(echo $LATEST_TAG | perl -pe 's/^v?(\d+)\.(\d+)\.(\d+).*$/v.($1+1).".0.0"/e')
elif [[ $(git log --no-merges --pretty="%s" $LATEST_TAG..HEAD | grep "feat:") != '' ]]; then
  NEXT_TAG=$(echo $LATEST_TAG | perl -pe 's/^v?(\d+)\.(\d+)\.(\d+).*$/v.($1).".".($2+1).".0"/e')
elif [[ $(git log --no-merges --pretty="%s" $LATEST_TAG..HEAD | grep "fix:") != '' ]]; then
  NEXT_TAG=$(echo $LATEST_TAG | perl -pe 's/^v?(\d+)\.(\d+)\.(\d+).*$/v.($1).".".($2).".".($3+1)/e')
fi

trap 'rm "$TMP_CHANGELOG" && git tag -d "$NEXT_TAG" > /dev/null 2> /dev/null' EXIT

if [[ NEXT_TAG != "" && ( $RELEASE == "TRUE" || $DRY_RUN == "TRUE" ) ]]; then
  git tag $NEXT_TAG -m "Automated Release - $(date)"
fi

echo "# ${PWD##*/} Changelog" | sed -e "s/\b\(.\)/\u\1/g" > $TMP_CHANGELOG
echo >> $TMP_CHANGELOG
echo "This file was auto-generated and should not be manually edited" >> $TMP_CHANGELOG

for TAG in $(git tag -l --sort=version:refname | tac)
do
  PREVIOUS_TAG=$(git describe --abbrev=0 $TAG^ 2> /dev/null || echo $FIRST_COMMIT)

  if [[ $PREVIOUS_TAG == $FIRST_COMMIT ]]; then
    COMPARE_NAME="the start of the repository"
  else
    COMPARE_NAME="\`$PREVIOUS_TAG\`"
  fi

  echo >> $TMP_CHANGELOG
  echo >> $TMP_CHANGELOG

  if [[ $(git cat-file -t $TAG) == "tag" ]]; then
    git tag -l --format="## [%(refname:strip=2)]($BASE_URL?version=GT%(refname:strip=2)) %(contents)" $TAG >> $TMP_CHANGELOG
    echo >> $TMP_CHANGELOG
    git tag -l --format="**Date Tagged (Released)**: %(taggerdate:format:%B %d, %Y)" $TAG >> $TMP_CHANGELOG
    echo >> $TMP_CHANGELOG
    git tag -l --format="**Tagged (Released) By**: %(taggername)" $TAG >> $TMP_CHANGELOG
  else
    git tag -l --format="## [%(refname:strip=2)]($BASE_URL?version=GT%(refname:strip=2))" $TAG >> $TMP_CHANGELOG
    echo >> $TMP_CHANGELOG
  fi

  NON_MERGE_COMMITS=$(git log --no-merges --pretty="* [%h]($BASE_URL/commit/%H) - %s" $PREVIOUS_TAG..$TAG)

  FEATURES=$(echo "$NON_MERGE_COMMITS" | grep "\- feat:")
  [[ $FEATURES != '' ]] && printf "\n\n### **New features** added between \`$TAG\` and $COMPARE_NAME\n\n$FEATURES" >> $TMP_CHANGELOG

  FIXES=$(echo "$NON_MERGE_COMMITS" | grep "\- fix:")
  [[ $FIXES != '' ]] && printf "\n\n### **Bugs fixed** between \`$TAG\` and $COMPARE_NAME\n\n$FIXES" >> $TMP_CHANGELOG

  COMMITS=$(echo "$NON_MERGE_COMMITS" | grep -v "\- fix:\|\- feat:")
  [[ $COMMITS != '' && ( $FIXES == '' && $FEATURES == '' ) ]] && printf "\n\n### **Commits** between \`$TAG\` and $COMPARE_NAME\n\n$COMMITS" >> $TMP_CHANGELOG
  [[ $COMMITS != '' && ( $FIXES != '' || $FEATURES != '' ) ]] && printf "\n\n### **Additional commits** between \`$TAG\` and $COMPARE_NAME\n\n$COMMITS" >> $TMP_CHANGELOG

  PULL_REQUESTS=$(git log --merges --pretty="* %s" $PREVIOUS_TAG..$TAG | grep "Merged PR")
  [[ $PULL_REQUESTS != '' ]] && printf "\n\n### **Pull Requests** between \`$TAG\` and $COMPARE_NAME\n\n$PULL_REQUESTS" >> $TMP_CHANGELOG

  # Intentionally adding two spaces after the astrisk instead of one since ADO is not rendering it as a list otherwise.
  WORK_ITEMS=$(git log --pretty="%b" $PREVIOUS_TAG..$TAG | grep -o -E "#[0-9]+" | sort --unique | awk '{print "*  "$1}')
  [[ $WORK_ITEMS != '' ]] && printf "\n\n### **Work Items** between \`$TAG\` and $COMPARE_NAME\n\n$WORK_ITEMS" >> $TMP_CHANGELOG

  BREAKING_CHANGES=$(git log --format="%B" $PREVIOUS_TAG..$TAG | grep -E 'BREAKING(\s|-)CHANGE:' | sort --unique | sed 's/BREAKING\(\s\|-\)CHANGE: \(.*\)/* \2/g')
  [[ $BREAKING_CHANGES != '' ]] && printf "\n\n### **Breaking change details** between \`$TAG\` and $COMPARE_NAME\n\n$BREAKING_CHANGES" >> $TMP_CHANGELOG

done

if [[ $DRY_RUN == "TRUE" ]]; then
  git tag -d $NEXT_TAG > /dev/null 2> /dev/null
fi

#sed -i 's/Merged PR \([0-9]*\)[^0-9].*/!\1/g' $TMP_CHANGELOG
sed -i 's/- \(feat\|fix\|refactor\|docs\|ci\|test\|style\)[^:]*!:\(.*\)$/- \2 **(Contains breaking change)**/g' $TMP_CHANGELOG
sed -i 's/- \(feat\|fix\|refactor\|docs\|ci\|test\|style\):/-/g' $TMP_CHANGELOG
echo >> $TMP_CHANGELOG
cat -s $TMP_CHANGELOG > CHANGELOG.md
rm $TMP_CHANGELOG
trap - EXIT
