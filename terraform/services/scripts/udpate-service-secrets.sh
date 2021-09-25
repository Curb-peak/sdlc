#!/bin/bash

export AWS_PROFILE=sdlc
env=$1
service=$2

! [[ $env ]] && env="${Environment}"
! [[ $env ]] && ALL_EnvironmentS=true

! [[ $service ]] && service="${Service}"
! [[ $service ]] && ALL_SERVICES=true

updateServiceSecret () {
  FILE=$1
  SECRET_ID=${FILE:2}
  SECRET_VALUE="$(cat $FILE)"

  echo "secret id: $SECRET_ID"
  aws secretsmanager get-secret-value --secret-id $SECRET_ID
  GET_SECRET_RESULT=$?

  # if our secret doesn't exist create it else update it
  if [ "${GET_SECRET_RESULT}" == 254 ]; then
    aws secretsmanager create-secret --name $SECRET_ID --secret-string "$SECRET_VALUE"
  else
    aws secretsmanager update-secret --secret-id $SECRET_ID --secret-string "$SECRET_VALUE"
  fi
}

updateServiceEnvironments () {
  find . -iname "$1.*" | while read line
  do
    updateServiceSecret $line
  done
}

cd services

if [[ "$ALL_EnvironmentS" ]] && [[ "$ALL_SERVICES" ]]
then
  updateServiceEnvironments dev;
  updateServiceEnvironments staging;
elif [[ "$ALL_SERVICES" ]]
then
  updateServiceEnvironments $env;
else
  updateServiceSecret "./$env.$service.service"
fi
