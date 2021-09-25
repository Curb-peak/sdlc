#!/bin/bash

set -e

# S: echo \"([A-Z_]*)\=\\\"\$[A-Z_]*\\""
# R: var $1

source ./display_vars.sh

cb_vars () {
  heading "CODEBUILD_VARS"
  var AWS_REGION
  var CODEBUILD_BATCH_BUILD_IDENTIFIER
  var CODEBUILD_BUILD_ARN
  var CODEBUILD_BUILD_IMAGE
  var CODEBUILD_BUILD_NUMBER
  var CODEBUILD_BUILD_SUCCEEDING
  var CODEBUILD_INITIATOR
  var CODEBUILD_LOG_PATH
  var CODEBUILD_PUBLIC_BUILD_URL
  var CODEBUILD_RESOLVED_SOURCE_VERSION
  var CODEBUILD_SOURCE_REPO_URL
  var CODEBUILD_SOURCE_VERSION
  var CODEBUILD_SRC_DIR
  var CODEBUILD_START_TIME
  var CODEBUILD_WEBHOOK_ACTOR_ACCOUNT_ID
  var CODEBUILD_WEBHOOK_BASE_REF
  var CODEBUILD_WEBHOOK_EVENT
  var CODEBUILD_WEBHOOK_TRIGGER
  var CODEBUILD_WEBHOOK_HEAD_REF
}

custom_cb_vars () {
  heading "CUSTOM_CODEBUILD_VARS"

  export CI=true
  export CODEBUILD=true
  var CI
  var CODEBUILD

  export CODEBUILD_IDENTITY=$(aws sts get-caller-identity)
  var CODEBUILD_IDENTITY

  export CODEBUILD_ACCOUNT_ID=$(aws sts get-caller-identity --query 'Account' --output text)
  var CODEBUILD_ACCOUNT_ID

  export CODEBUILD_GIT_BRANCH="$(git symbolic-ref HEAD --short 2>/dev/null)"
  if [ -z "$CODEBUILD_GIT_BRANCH" ]; then
    export CODEBUILD_GIT_BRANCH="$(git rev-parse HEAD | xargs git name-rev | cut -d' ' -f2 | sed 's/remotes\/origin\///g')";
  fi
  var CODEBUILD_GIT_BRANCH

  export CODEBUILD_GIT_CLEAN_BRANCH="$(echo $CODEBUILD_GIT_BRANCH | tr '/' '.')"
  var CODEBUILD_GIT_CLEAN_BRANCH
  var CODEBUILD_GIT_BRANCH

  export CODEBUILD_GIT_ESCAPED_BRANCH="$(echo $CODEBUILD_GIT_CLEAN_BRANCH | sed -e 's/[]\/$*.^[]/\\\\&/g')"
  var CODEBUILD_GIT_ESCAPED_BRANCH
  export CODEBUILD_GIT_MESSAGE="$(git log -1 --pretty=%B)"
  var CODEBUILD_GIT_MESSAGE

  export CODEBUILD_GIT_AUTHOR="$(git log -1 --pretty=%an)"
  var CODEBUILD_GIT_AUTHOR

  export CODEBUILD_GIT_AUTHOR_EMAIL="$(git log -1 --pretty=%ae)"
  var CODEBUILD_GIT_AUTHOR_EMAIL

  export CODEBUILD_GIT_COMMIT="$(git log -1 --pretty=%H)"
  var CODEBUILD_GIT_COMMIT

  export CODEBUILD_GIT_SHORT_COMMIT="$(git log -1 --pretty=%h)"
  var CODEBUILD_GIT_SHORT_COMMIT

  export CODEBUILD_GIT_TAG="$(git describe --tags --exact-match 2>/dev/null)"
  #[[ -z "$CODEBUILD_GIT_TAG" ]] && export CODEBUILD_GIT_TAG="$(git describe --tags 2>/dev/null)"
  var CODEBUILD_GIT_TAG
  export CODEBUILD_GIT_MOST_RECENT_TAG="$(git describe --tags --abbrev=0)"
  var CODEBUILD_GIT_MOST_RECENT_TAG

  export CODEBUILD_PULL_REQUEST=false
  if [ "${CODEBUILD_GIT_BRANCH#pr-}" != "$CODEBUILD_GIT_BRANCH" ] ; then
    export CODEBUILD_PULL_REQUEST=${CODEBUILD_GIT_BRANCH#pr-};
  fi
  var CODEBUILD_PULL_REQUEST

  export CODEBUILD_PROJECT=${CODEBUILD_BUILD_ID%:$CODEBUILD_LOG_PATH}
  var CODEBUILD_PROJECT
  export CODEBUILD_BUILD_URL=https://$AWS_DEFAULT_REGION.console.aws.amazon.com/codebuild/home?region=$AWS_DEFAULT_REGION#/builds/$CODEBUILD_BUILD_ID/view/new
  var CODEBUILD_BUILD_URL

}

cicd_vars () {

  heading "CUSTOM_CICD_VARS"

  EVENT=$CODEBUILD_WEBHOOK_EVENT

  # if our event is a push and the commit matches a tag it was a push of a tag to a branch
  # in this case our intent is to deploy the tag to an Environment
  #if [[ $CODEBUILD_WEBHOOK_EVENT == "PUSH"]]; then

  export EVENT=$EVENT
  var EVENT

  EVENT_TYPE="commit"
  [[ $CODEBUILD_WEBHOOK_HEAD_REF == *"tags"* ]] && EVENT_TYPE="tag"
  export EVENT_TYPE=$EVENT_TYPE
  var EVENT_TYPE

 # set branch
  if [[ "${CODEBUILD_WEBHOOK_TRIGGER}" == *"branch"* ]]; then
    BRANCH=${CODEBUILD_WEBHOOK_TRIGGER/branch\//}
  else
    [[ -z "${CODEBUILD_GIT_TAG}" ]] && BRANCH=$DEFAULT_BRANCH || BRANCH="${CODEBUILD_GIT_TAG/-v*/}"
  fi
  export BRANCH=$BRANCH
  var BRANCH
  #git checkout $BRANCH

  COMMIT=$CODEBUILD_RESOLVED_SOURCE_VERSION
  export COMMIT=$COMMIT
  var COMMIT

  if [ $EVENT_TYPE == tag ]; then

    FULL_EVENT_TAG=${CODEBUILD_WEBHOOK_TRIGGER/*?\//}
    export FULL_EVENT_TAG=$FULL_EVENT_TAG
    var FULL_EVENT_TAG

    [[ -z ${EVENT_TAG} ]] &&
    export EVENT_TAG=$EVENT_TAG
    var EVENT_TAG
  fi

  var Environment

  tag_lookup="${BRANCH}\-v*.*.*"
  REPO_LATEST_VERSION="$(git tag -l "${tag_lookup}" | sort -V | tail -n 1)"
  var REPO_LATEST_VERSION

  #echo "check ${COMMIT:0:7} for existing tags..
  export COMMIT_VERSION_TAGS="$(git show-ref --tags -d | grep $COMMIT | sed -e 's,.* refs/tags/,,' -e 's/\^{}//' | sed -n 's/\(^'"${BRANCH}"'-v[0-9]*.[0-9]*.[0-9]*\)/\1/p')"
  var COMMIT_VERSION_TAGS

  if ! [ -z "${COMMIT_VERSION_TAGS}" ]; then
    COMMIT_HAS_VERSION_TAG="$(echo "$COMMIT_VERSION_TAGS" | tail -n1)"
  fi
  export COMMIT_HAS_VERSION_TAG=$COMMIT_HAS_VERSION_TAG
  var COMMIT_HAS_VERSION_TAG

  #echo "check ${COMMIT:0:7}'s tags to make sure the for existing tags.."
  COMMIT_BRANCHES="$(git branch -r --contains $COMMIT)"
  COMMIT_BRANCHES="${COMMIT_BRANCHES/[ ]*origin\//}"
  export COMMIT_BRANCHES=$COMMIT_BRANCHES
  var COMMIT_BRANCHES

  [[ "$COMMIT_BRANCHES" == *"$BRANCH"* ]] && COMMIT_IN_BRANCH=true
  export COMMIT_IN_BRANCH=$COMMIT_IN_BRANCH
  var COMMIT_IN_BRANCH

  [[ "$COMMIT_BRANCHES" == *"main"* ]] && COMMIT_IN_PRIMARY_BRANCH=true
  export COMMIT_IN_PRIMARY_BRANCH=$COMMIT_IN_PRIMARY_BRANCH
  var COMMIT_IN_PRIMARY_BRANCH

  export COMMIT_VERSION="$(git describe --abbrev=0 --match "${BRANCH}-v[0-9]*.[0-9]*.[0-9]*" HEAD 2>/dev/null)"
  var COMMIT_VERSION

  export LATEST_VERSION="$(git describe --abbrev=0 --match "${BRANCH}-v[0-9]*.[0-9]*.[0-9]*" HEAD 2>/dev/null)"
  var LATEST_VERSION

  # check to see if we already have a solid artifact for this build
  export EXISTING_AMI_ID="$(aws ec2 describe-images --filters "Name=name,Values=${Environment}-${Service}-${COMMIT_VERSION}" --query 'sort_by(Images,&CreationDate)[-1].ImageId' --output text)"
  [[ "${EXISTING_AMI_ID}" == None ]] && export EXISTING_AMI_ID=
  var EXISTING_AMI_ID
}

version_vars () {
  heading "VERSION_VARS"

  var DEFAULT_BRANCH
  var BRANCH
  var Service

  if [ -f "../package.json" ]; then
    export PACKAGE_VERSION=$(cat ../package.json | jq -r '.version');
    export PACKAGE_VERSION_MAJOR=${PACKAGE_VERSION/.*/};
    export PACKAGE_VERSION_MINOR=$(echo ${PACKAGE_VERSION} | sed 's/[0-9]*.\([0-9]*\).[0-9]*/\1/');
    export PACKAGE_VERSION_PATCH=${PACKAGE_VERSION/*[0-9]*\./};

    var PACKAGE_VERSION;
    var PACKAGE_VERSION_MAJOR;
    var PACKAGE_VERSION_MINOR;
    var PACKAGE_VERSION_PATCH;
  fi

  export REPO_LATEST_VERSION=$(git tag -l "${BRANCH}\-v${PACKAGE_VERSION_MAJOR}.${PACKAGE_VERSION_MAJOR}.*" | sort -V | tail -n 1)
  var REPO_LATEST_VERSION
}

cb_vars
custom_cb_vars
cicd_vars
version_vars
