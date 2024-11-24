#!/usr/bin/env bash

set -euo pipefail

# Default values for the arguments
worker_ip=""
k8s_token=""
k8s_master_addr=""
k8s_ca_cert_hash=""
vars_path="infrastructure/inventories/prod/group_vars/all.yml"

usage() {
  printf "Usage: %s -i <worker_ip> -t <k8s_token> -m <k8s_master_addr> -c <k8s_ca_cert_hash> -v <vars_path>\n" "$0"
  printf "\n"
  printf "  -i <worker_ip>            IP address of the worker node\n"
  printf "  -t <k8s_token>            Kubernetes join token\n"
  printf "  -m <k8s_master_addr>      IP or hostname of the Kubernetes master node\n"
  printf "  -c <k8s_ca_cert_hash>     CA certificate hash for the Kubernetes master\n"
  printf "  -v <vars_path>            Path to the variables file (default: %s)\n" "$vars_path"
  exit 1
}

# Parse command-line options
while getopts "i:t:m:c:v:" opt; do
  case "${opt}" in
    i)
      worker_ip="${OPTARG}"
      ;;
    t)
      k8s_token="${OPTARG}"
      ;;
    m)
      k8s_master_addr="${OPTARG}"
      ;;
    c)
      k8s_ca_cert_hash="${OPTARG}"
      ;;
    v)
      vars_path="${OPTARG}"
      ;;
    ?)
      usage
      ;;
  esac
done
shift $((OPTIND - 1))

if [[ -z "${worker_ip}" || -z "${k8s_token}" || -z "${k8s_master_addr}" || -z "${k8s_ca_cert_hash}" ]]; then
  printf "Error: All arguments are required.\n" >&2
  usage
fi

ansible-playbook -i "${worker_ip}," -e "@$vars_path" -e "k8s_token=${k8s_token}" -e "k8s_master_addr=${k8s_master_addr}" -e "k8s_ca_cert_hash=${k8s_ca_cert_hash}" infrastructure/k8s-worker.yml

