#!/bin/bash

set -eu

ROOT=$PWD

  local haproxy_floating_ip=$(terraform output \
    -state "$ROOT/create-infrastructure-output/terraform.tfstate" \
    haproxy_floating_ip)
  local opsman_floating_ip=$(terraform output \
    -state "$ROOT/create-infrastructure-output/terraform.tfstate" \
    opsman_floating_ip)

  echo "=========== Floating IPs ==========="
  echo "OpsMan: ${opsman_floating_ip}"
  echo "HA Proxy: ${haproxy_floating_ip}"
  echo "${opsman_floating_ip}" > $ROOT/ip-adresses/opsman_ip
  echo "${haproxy_floating_ip}" > $ROOT/ip-adresses/haproxy_ip
