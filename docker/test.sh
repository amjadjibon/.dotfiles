#!/usr/bin/env bash
set -euo pipefail

PLAYBOOK="ansible-playbook -i ansible/inventory.ini ansible/setup.yml \
  --extra-vars in_docker=true \
  -e ansible_python_interpreter=/usr/bin/python3"

echo "=== First run ==="
eval "$PLAYBOOK"

echo ""
echo "=== Idempotency check (second run) ==="
output=$(eval "$PLAYBOOK" 2>&1)
echo "$output"

if echo "$output" | grep -qE "changed=[1-9]"; then
  echo ""
  echo "FAIL: not idempotent — changes detected on second run"
  exit 1
fi

echo ""
echo "PASS: no changes on second run"
