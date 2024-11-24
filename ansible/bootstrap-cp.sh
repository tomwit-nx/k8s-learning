#!/usr/bin/env bash

set -euo pipefail

target_host=""
vars_path="infrastructure/inventories/prod/group_vars/all.yml"
playbook="infrastructure/k8s-cp.yml"

usage() {
  printf "Usage: %s -t <target_host> -v <vars_path> -p <playbook>\n" "$0"
  printf "\n"
  printf "  -t    <target_host>      Target host (default: %s)\n" "$target_host"
  printf "  -v    <vars_path>        Path to the variables file (default: %s)\n" "$vars_path"
  printf "  -p    <playbook>         Path to the playbook (default: %s)\n" "$playbook"
  exit 1
}

while getopts "t:v:p:" opt; do
  case "${opt}" in
    t)
      target_host="${OPTARG}"
      ;;
    v)
      vars_path="${OPTARG}"
      ;;
    p)
      playbook="${OPTARG}"
      ;;
    ?)
      usage
      ;;
  esac
done
shift "$((OPTIND - 1))"

# Ensure the host is set
if [[ -z "$target_host" ]]; then
  printf "Error: Host is not set.\n" "$playbook" >&2 && usage
fi

# Ensure the playbook exists
if [[ ! -f "$playbook" ]]; then
  printf "Error: Playbook file %s does not exist.\n" "$playbook" >&2
  exit 1
fi

# Ensure the inventory file exists
if [[ ! -f "$vars_path" ]]; then
  printf "Error: Inventory file %s does not exist.\n" "$vars_path" >&2
  exit 1
fi

ansible-playbook -i "$target_host," -e "@$vars_path" "$playbook"

