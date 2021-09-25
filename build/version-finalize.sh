#!/bin/bash

set -e

source ./display_vars.sh

create_version () {
  # switching to new version: main-v0.0.*
  projectId="${CODEBUILD_PROJECT/*:/}"; shortId="${projectId:0:7}"; badge="[${shortId}];"
  MESSAGE="${badge} ${CODEBUILD_PROJECT/:*/}"

  export CREATE="$(git tag -a $BRANCH-v$VERSION HEAD -m "$MESSAGE $BVERSION")"
  err=$?; [ -n $err ] || echo "error creating the version tag: $BRANCH-v$VERSION"

  # push tag to remote
  export PUSH="$(git push origin --tags)"
  err=$?; [ -n $err ] || echo "error pushing version tag: $BRANCH-v$VERSION"
}

if ! [[ -z ${SKIP_VERSIONING} ]]; then

  echo "skipping version finalization.. reusing ${BRANCH-v$VERSION}"

else
  create_version
fi
