#!/bin/bash

set -e

source ./display_vars.sh

get_next_version () {

  major_max=0;
  minor_max=0;
  patch_max=1;

  # lets see if we have a version tag for this branch
  if ! [ -z "$REPO_LATEST_VERSION" ]; then
    # check to see if we already have this artifact

    #echo "Last tag: $REPO_LATEST_VERSION"
    version=$(echo $REPO_LATEST_VERSION | grep -o '[^v]*$')
    major=$(echo $version | cut -d. -f1)
    minor=$(echo $version | cut -d. -f2)
    patch=$(echo $version | cut -d. -f3)

    if [ "$major_max" -lt "$major" ]; then
            let major_max=$major
        fi
    if [ "$minor_max" -lt "$minor" ]; then
            let minor_max=$minor
        fi
    if [ "$patch_max" -lt "$patch" ]; then
        let patch_max=$patch
    fi

    let patch_max=($patch_max+1)
  fi
  if [ "$major_max" -ne "${MAJOR_VERSION}" ] || [ "$minor_max" -ne "${MINOR_VERSION}" ]; then
      major_max="${MAJOR_VERSION}"
      minor_max="${MINOR_VERSION}"
  fi

  export VERSION="$major_max.$minor_max.$patch_max"
  var VERSION

  export BVERSION=$BRANCH.$VERSION
  var BVERSION

  export FVERSION=${BRANCH}-v${VERSION}
  var FVERSION
}

create_package_version () {
  if [ -f "../package.json" ]; then
    export WRITE_SEMVER="$(json -I -f "../package.json" -e "this.version='$VERSION'")"
    err=$?; [ -n $err ] || echo "error pushing version tag: $BRANCH-v$VERSION"
    var WRITE_SEMVER
  fi
}

if ! [[ -z ${SKIP_VERSIONING} ]]; then

  export VERSION="${CODEBUILD_GIT_TAG/*-v/}"
  echo "VERSION=${VERSION}"

  info "the current commit: ${CODEBUILD_RESOLVED_SOURCE_VERSION} is already tied to version ${CODEBUILD_GIT_TAG/-v*/}"
  info "skipping versioning"

  export BVERSION="${BRANCH}.${VERSION}"
  echo "BVERSION=$BVERSION"

else

  get_next_version
  create_package_version

fi
