#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")"

export AWS_PROFILE="${AWS_PROFILE:-default}"

terraform plan -out=tfplan-bg
terraform apply -auto-approve tfplan-bg
terraform output -raw ansible_inventory > ../ansible/inventory.ini
terraform output
