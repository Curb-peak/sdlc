#!/bin/bash

set -e

# S: echo \"([A-Z_]*)\=\\\"\$[A-Z_]*\\""
# R: var $1

source ./display_vars.sh

install_service () {
  heading "INSTALL_SYSTEMD_SERVICE"
  echo "${Environment}.${Service}.service"
  SECRET="$(aws secretsmanager get-secret-value --secret-id "${Environment}.${Service}.service")"
  if ! [[ -z "$SECRET" ]]; then
    SECRET=$(echo $SECRET | jq -r ".SecretString")
    echo "$SECRET" > ../${Service}.service
    if [ -f "../next-env.d.ts" ]; then
      ENV_VARS=$(sed -n -e '/^Environment\=/p' ../${Service}.service)
      echo $ENV_VARS | tr " " "\n" > ../.env.local
    fi
  fi
}

# aws secretsmanager create-secret --name dev.meitner.postinstall.smartrent-organization-credentials.json --secret-string "$SECRET" --tags Key=PostInstall,Value=meitner Key=Environment,Value=staging Key=Service,Value=meitner --profile sdlc
post_install () {
  heading "POST_INSTALL_SERVICE"

  echo "aws secretsmanager list-secrets --filters Key=tag-key,Values=PostInstall Key=tag-value,Values=$SERVICE Key=tag-key,Values=Environment Key=tag-value,Values=$Environment Key=tag-key,Values=Service Key=tag-value,Values=$SERVICE"
  POST_BUILD_FILES=$(aws secretsmanager list-secrets --filters Key=tag-key,Values=PostInstall Key=tag-value,Values=$SERVICE Key=tag-key,Values=Environment Key=tag-value,Values=$Environment Key=tag-key,Values=Service Key=tag-value,Values=$SERVICE | jq -r ".SecretList")
  FILE_COUNT=$(echo $POST_BUILD_FILES | jq -r '. | length')
  echo "post install file count: $FILE_COUNT"

  for (( c=0; c<=$FILE_COUNT-1; c++ ));
  do
    FILE=$(echo $POST_BUILD_FILES | jq -r ".[$c]")
    FILE_NAME=$(echo $FILE | jq -r ".Name")
    SECRET_VALUE=$(aws secretsmanager get-secret-value --secret-id $FILE_NAME)
    FILE_NAME_ACTUAL="${FILE_NAME/${Environment}\.${Service}\.postinstall\.}"
    echo "writing secrets file: $FILE_NAME_ACTUAL"
    echo "$SECRET_VALUE" > ./"$FILE_NAME_ACTUAL"
  done

  if (( $FILE_COUNT > 0 )); then
      chmod +x ../post-install.sh
      ../post-install.sh
  fi
}

install_service
post_install
