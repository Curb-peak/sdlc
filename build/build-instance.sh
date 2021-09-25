#!/bin/bash

set -e

# print variable regex: (.*?)\n
# echo "$1: [\$$1]"\n

#git tag -d $(git tag -l) > /dev/null
#git fetch --tags --quiet

source ./display_vars.sh
#
#install_node_modules() {
#  npm i --loglevel=error
#
#  if [ -f "./tsconfig.json" ]; then
#    npm run build
#  fi
#}

build_ami() {

  echo "$VERSION|$SERVICE|$Environment|$COMMIT|$BRANCH"
  export PKR_VAR_VERSION="$VERSION"
  export PKR_VAR_SERVICE="$SERVICE"
  export PKR_VAR_Environment="$Environment"
  export PKR_VAR_COMMIT="$COMMIT"
  export PKR_VAR_BRANCH="$BRANCH"
  echo version: "${PKR_VAR_Environment}-${PKR_VAR_SERVICE}-${PKR_VAR_BRANCH}-${PKR_VAR_VERSION}"

  echo $(pwd)

  # build the ami with packer
  packer init ./peak.pkr.hcl
  packer build ./peak.pkr.hcl

}

update_service () {
  echo "update instances for $Environment-$SERVICE"

  AMI_ID=$(aws ec2 describe-images --filters "Name=tag:Service,Values=${Service}" "Name=tag:Environment,Values=${Environment}" --query 'sort_by(Images,&CreationDate)[-1].ImageId' --output text)
  if [[ "${AMI_ID}" == None ]]; then
    echo "No images available for [${Service}] on [${Environment}]";
    exit 3;
  fi

  var AMI_ID

  OLD_LAUNCH_TEMPLATE_REF=$(aws ec2 describe-launch-templates --filter "Name=tag:Service,Values=${Service}" "Name=tag:Environment,Values=${Environment}" --query "LaunchTemplates[0]")
  if [[ "${OLD_LAUNCH_TEMPLATE_REF}" == None ]]; then
    echo "No existing launch template matches for [${Service}] on [${Environment}]"
    exit 4
  fi
  echo "OLD_LAUNCH_TEMPLATE_REF=${OLD_LAUNCH_TEMPLATE_REF}"
  LAUNCH_TEMPLATE_ID=$(echo $OLD_LAUNCH_TEMPLATE_REF | jq -r '.LaunchTemplateId')
  LAUNCH_TEMPLATE_DEFAULT_VERSION=$(echo $OLD_LAUNCH_TEMPLATE_REF | jq -r '.DefaultVersionNumber')

  ENV_BRANCH_VERSION=${Environment}-${Service}-${VERSION}
  var ENV_BRANCH_VERSION
  var Service
  var Environment
  var OLD_LAUNCH_TEMPLATE_REF

  OLD_LAUNCH_TEMPLATE=$(aws ec2  describe-launch-template-versions --launch-template-id ${LAUNCH_TEMPLATE_ID} --filters "Name=is-default-version,Values=true" --query "LaunchTemplateVersions[0]")
  echo -e "\nold launch template: $LAUNCH_TEMPLATE_ID v$LAUNCH_TEMPLATE_DEFAULT_VERSION:\n"
  echo "$OLD_LAUNCH_TEMPLATE"

  echo "creating new launch template version: $LAUNCH_TEMPLATE_ID"
  LAUNCH_TEMPLATE=$(aws ec2 create-launch-template-version --launch-template-id ${LAUNCH_TEMPLATE_ID} --launch-template-data "ImageId=${AMI_ID},TagSpecifications=[{ResourceType=instance,Tags=[{Key=Name,Value=$Environment-$SERVICE-$VERSION},{Key=Service,Value=$SERVICE},{Key=Environment,Value=$Environment}]}]" --source-version $LAUNCH_TEMPLATE_DEFAULT_VERSION --query "LaunchTemplateVersion")
  LAUNCH_TEMPLATE_VERSION=$(echo $LAUNCH_TEMPLATE | jq -r '.VersionNumber')

  echo -e "\nnew launch template $LAUNCH_TEMPLATE_ID v$LAUNCH_TEMPLATE_VERSION:\n"
  echo "$LAUNCH_TEMPLATE"

  #modify the old launch template to set the vars we need
  echo "update default version of launch template $LAUNCH_TEMPLATE_ID to v$LAUNCH_TEMPLATE_VERSION"
  aws ec2 modify-launch-template --launch-template-id $LAUNCH_TEMPLATE_ID --default-version $LAUNCH_TEMPLATE_VERSION >> /dev/null
  AUTO_SCALING_GROUP_NAME=$(aws autoscaling describe-auto-scaling-groups --query "AutoScalingGroups[? Tags[? (Key=='Environment') && Value=='"${Environment}"']] | [? Tags[? Key=='Service' && Value == '"${Service}"']]".AutoScalingGroupName | jq -r '. [0]')

  echo "refresh instances: $AUTO_SCALING_GROUP_NAME"
  aws autoscaling start-instance-refresh --auto-scaling-group-name "${AUTO_SCALING_GROUP_NAME}" --preferences "MinHealthyPercentage=100,InstanceWarmup=30" >> /dev/null
}

if ! [ -z "$SKIP_BUILD" ]; then
  echo "build artifacts already exist.. skipping build"
else
  #install_node_modules
  build_ami
  update_service
fi
