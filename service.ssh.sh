#!/bin/sh
die () {
    echo >&2 "$@"
    exit 1
}

export AWS_PROFILE=sdlc

[ "$#" -eq 2 ] || die "2 argument required, $# provided.. the first argument should be the Environment name.. the second needs to be the service name"

ipaddress=$(aws ec2 describe-instances --filter "Name=instance-state-name,Values=running" "Name=instance-state-code,Values=16" --query "Reservations[*].Instances[*].[PublicIpAddress, Tags[?Key=='Name'].Value|[0]][0]" | jq -r '.[] | select(.[1] != null) | select(.[1] | startswith( "'$1'-'$2'")) | .[0]')
ssh -i ~/.ssh/curb ubuntu@$ipaddress
