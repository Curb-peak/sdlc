#!/bin/bash

set -e

source ./display_vars.sh

die () {
  echo $1
  exit 1
}

validate_input_vars () {
  echo "${MAJOR_VERSION}-${MINOR_VERSION}-${Service}-${Service}"

  if [ -z "$MAJOR_VERSION" ]; then
    die "The 'MAJOR_VERSION' Environment variable is required";
  fi

  if [ -z "$MINOR_VERSION" ]; then
    die "The 'MINOR_VERSION' environment variable is required";
  fi

  if [ -z "$SERVICE" ]; then
    die "The 'Service' environment variable is required";
  fi

  if [ -z "$DEFAULT_BRANCH" ]; then
    die "The 'DEFAULT_BRANCH' environment variable is required";
  fi
}


configure_phases () {
  # if a version tag already exists on this commit and it matches the current branch
  if ! [ -z "$COMMIT_HAS_VERSION_TAG" ]; then
      ! if [ -z "$COMMIT_IN_BRANCH" ]; then
        export SKIP_VERSIONING=true
      fi
  fi

  if ! [ -z "$EXISTING_AMI_ID" ]; then
    export SKIP_BUILD=true
  fi
}

process_event_type_tag () {
  var EVENT_TYPE
  if [ "$EVENT_TYPE" == tag ]; then
    # verify this tag belongs on the main branch otherwise don't deploy it to staging or prod
    if [ "$COMMIT_BRANCHES" == *"main"* ]; then
      die "staging and prod builds can only be deployed from the main branch"
    fi
  fi
}

validate_input_vars
configure_phases
process_event_type_tag