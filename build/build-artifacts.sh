#!/bin/bash

set -e

# print variable regex: (.*?)\n
# echo "$1: [\$$1]"\n

#git tag -d $(git tag -l) > /dev/null
#git fetch --tags --quiet

source ./display_vars.sh

publish_artifacts() {

  export EXT_VERSION="$ENVIRONMENT-$SERVICE-$BRANCH-$COMMIT-$VERSION"

  echo "current directory $(pwd)"
  aws s3 sync ./ s3://stokedconsulting.com-sdlc-artifacts/sdlc/ --delete
}

update_environment_deploy_tag () {
  # delete exiting environment tag if already exists
  git describe --tags
  git push origin :refs/tags/$ENVIRONMENT

  # write new environment tag on current commit
  git tag -a $ENVIRONMENT -m "deploy to $ENVIRONMENT environment"
  git push origin --tags
}

if ! [ -z "$SKIP_BUILD" ]; then
  echo "build artifacts already exist.. skipping build"
else
  publish_artifacts
fi

if ! [ -z "$EVENT_TAG" ]; then
  update_environment_deploy_tag
fi
