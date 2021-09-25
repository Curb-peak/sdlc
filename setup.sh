ssh-keygen -t rsa -q -f "$HOME/.ssh/sdlc" -N ""
terraform14 -chdir=./terraform/init init
terraform14 -chdir=./terraform/init apply -auto-approve

terraform14 -chdir=./terraform/services init
terraform14 -chdir=./terraform/services apply -auto-approve
