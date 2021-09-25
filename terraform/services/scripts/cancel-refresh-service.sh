
env=$1
service=$2

! [[ $env ]] && env="${Environment}"
! [[ $env ]] && (echo "refresh-services: first argument missing [Environment]"; exit 2)

! [[ $service ]] && service="${Service}"
! [[ $service ]] && (echo "refresh-services: second argument missing [Service]"; exit 3)

AUTO_SCALING_GROUP_NAME=$(aws autoscaling describe-auto-scaling-groups --query "AutoScalingGroups[? Tags[? (Key=='Environment') && Value=='"${env}"']] | [? Tags[? Key=='Service' && Value == '"${service}"']]".AutoScalingGroupName --output text)

echo "cancel refresh instances: $AUTO_SCALING_GROUP_NAME"
aws autoscaling cancel-instance-refresh --auto-scaling-group-name "${AUTO_SCALING_GROUP_NAME}"