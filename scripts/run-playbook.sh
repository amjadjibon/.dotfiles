#!/usr/bin/env bash
set -euo pipefail

PLAYBOOK="ansible-playbook -i ansible/inventory.ini ansible/setup.yml \
  --extra-vars headless=true \
  -e ansible_python_interpreter=/usr/bin/python3"

eval "$PLAYBOOK"
