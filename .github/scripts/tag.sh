#!/usr/bin/env bash

### vars ####
TOML_FILE=pyproject.toml # TODO: move to inputs.

### funcs ####
function version_gt() { test "$(echo "$@" | tr " " "\n" | sort -V | head -n 1)" != "$1";}

function is_semver() {
    local version
    version="$1"
    if [[ ! ${version} =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
        #exit 1
		return 1
    fi
}

function add_github_tag() {
    local version
    version="$1"
    if [ -z "`git tag -l ${version}`" ];then
      echo "tagging with ${version}"
      git tag $NEW_VERSION
      #git push origin $NEW_VERSION
      git push --tags
      git push
      exit 0
    else
     echo "Tag already exists.."
     echo "::error::tag ${version} exsists, aborting..."
     exit 1
    fi 
}

##########
VERSION_TOML=$(grep version $TOML_FILE | cut -d \" -f2)

echo "VERSION_TOML=$VERSION_TOML"
echo "Getting current github tag"
CURRENT_VERSION=`git describe --abbrev=0 --tags 2>/dev/null`

if [[ $CURRENT_VERSION == '' ]] || ! is_semver $CURRENT_VERSION
then
 NEW_VERSION=$VERSION_TOML
 echo "No  semver tag found, using version $NEW_VERSION found in $TOML_FILE"
 add_github_tag $NEW_VERSION # do tagging
else
  echo "found existing version tag  $CURRENT_VERSION."
  echo "check if version in $TOML_FILE has changed"
  NEW_VERSION=$(git diff HEAD^ HEAD   -U0  $version_toml  | grep '^[+-]' | grep -Ev '^(--- a/|\+\+\+ b/)' | grep +version |  cut -d \" -f2)
  if [ -n "$NEW_VERSION" ]
  then
    echo "Yes, it was changed to $NEW_VERSION"
    echo "Checking if new toml version ($NEW_VERSION) is greater than the one found in tag ($CURRENT_VERSION)" 
    if ( version_gt $CURRENT_VERSION $NEW_VERSION );then
        echo "::warning::Found tag $CURRENT_VERSION  than is greater than $NEW_VERSION"
    fi 
    add_github_tag $NEW_VERSION # do tagging
  else
    echo "Version has not been changed in toml file."
    echo "comparing VERSION_TOML with CURRENT_VERSION"
    if ( version_gt $CURRENT_VERSION $VERSION_TOML )
    then
      echo "::warning::Found tag $CURRENT_VERSION  than is greater than toml version $VERSION_TOML"
    fi
  fi
fi
 