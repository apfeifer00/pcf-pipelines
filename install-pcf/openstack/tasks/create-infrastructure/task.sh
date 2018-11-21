#!/bin/bash

set -eu

ROOT=$PWD

### try to fix aws upload 2. 
#function finish {
#  t=$?
#  cp  $ROOT/terraform.tfstate $ROOT/create-infrastructure-output/terraform.tfstate
#  exit "$t"
#}
# trap finish EXIT

function get_opsman_version() {
  cut -d\# -f 1 ops-manager/version
}

function main() {

  #mkdir -p terraform-state/
  #[  -z “$(ls -A  terraform-state/)” ] && mv terraform-state/* create-infrastructure-output/ || echo "no tfstate file"

  local opsman_image_name="ops-manager-$(get_opsman_version)"
  local opsman_fixed_ip=$(echo $INFRA_SUBNET_CIDR|cut -d. -f 1,2,3).5
  echo "Opsman Image: ${opsman_image_name}"

  terraform init "$ROOT/pcf-pipelines/install-pcf/openstack/terraform"

  terraform plan \
    -var "os_tenant_name=${OS_PROJECT_NAME}" \
    -var "os_username=${OS_USERNAME}" \
    -var "os_password=${OS_PASSWORD}" \
    -var "os_auth_url=${OS_AUTH_URL}" \
    -var "os_region=${OS_REGION_NAME}" \
    -var "os_domain_name=${OS_USER_DOMAIN_NAME}" \
    -var "prefix=${OS_RESOURCE_PREFIX}" \
    -var "infra_subnet_cidr=${INFRA_SUBNET_CIDR}" \
    -var "opsman_fixed_ip"=${opsman_fixed_ip} \
    -var "ert_subnet_cidr=${ERT_SUBNET_CIDR}" \
    -var "services_subnet_cidr=${SERVICES_SUBNET_CIDR}" \
    -var "dynamic_services_subnet_cidr=${DYNAMIC_SERVICES_SUBNET_CIDR}" \
    -var "infra_dns=${INFRA_DNS}" \
    -var "ert_dns=${ERT_DNS}" \
    -var "services_dns=${SERVICES_DNS}" \
    -var "dynamic_services_dns=${DYNAMIC_SERVICES_DNS}" \
    -var "external_network=${EXTERNAL_NETWORK}" \
    -var "external_network_id=${EXTERNAL_NETWORK_ID}" \
    -var "opsman_image_name=${opsman_image_name}" \
    -var "opsman_public_key=${OPSMAN_PUBLIC_KEY}" \
    -var "opsman_volume_size=${OPSMAN_VOLUME_SIZE}" \
    -var "opsman_flavor=${OPSMAN_FLAVOR}" \
    -out "terraform.tfplan" \
    -state "$ROOT/create-infrastructure-output/terraform.tfstate" \
    "$ROOT/pcf-pipelines/install-pcf/openstack/terraform"

  terraform apply \
    -state-out "$ROOT/create-infrastructure-output/terraform.tfstate" \
    -parallelism=5 \
    terraform.tfplan
 
 ### try to fix aws upload 1.
#  aws s3 --endpoint-url $S3_ENDPOINT --region $S3_REGION cp terraform.tfstate "s3://${S3_BUCKET_TERRAFORM}/terraform.tfstate"

  local haproxy_floating_ip=$(terraform output \
    -state "$ROOT/create-infrastructure-output/terraform.tfstate" \
    haproxy_floating_ip)
  local opsman_floating_ip=$(terraform output \
    -state "$ROOT/create-infrastructure-output/terraform.tfstate" \
    opsman_floating_ip)

  echo "=========== Floating IPs ==========="
  echo "OpsMan: ${opsman_floating_ip}"
  echo "HA Proxy: ${haproxy_floating_ip}"
}

main
