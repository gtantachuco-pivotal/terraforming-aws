#!/bin/bash
set -e

source ./set-bosh-proxy.sh

cat > vars/concourse-vars-file.yml <<EOL
external_host: "${EXTERNAL_HOST}"
external_url: "https://${EXTERNAL_HOST}"
local_user:
  username: "concourse"
  password: "concourse"
network_name: 'control-plane'
web_instances: 1
web_network_name: 'control-plane'
web_vm_type: 'c4.xlarge'
web_network_vm_extension: 'control-plane-lb-cloud-properties'
db_vm_type: 'c4.xlarge'
db_persistent_disk_type: '51200'
worker_instances: 2
worker_vm_type: 'c4.xlarge'
worker_ephemeral_disk: '512000'
deployment_name: 'concourse'
credhub_url: "${CREDHUB_SERVER}"
credhub_client_id: "${CREDHUB_CLIENT}"
credhub_client_secret: "${CREDHUB_SECRET}"
az: ["us-east-1a"]
EOL

echo "$CREDHUB_CA_CERT" >> credhub_ca_cert 

export STEMCELL_URL="https://bosh.io/d/stemcells/bosh-aws-xen-hvm-ubuntu-xenial-go_agent"
bosh upload-stemcell $STEMCELL_URL

bosh update-config --type=cloud --name=concourse \
  -v lb_target_groups="[$(terraform output control_plane_web_target_group)]" \
   ./concourse-cloud-config.yml

bosh deploy -d concourse concourse-bosh-deployment/cluster/concourse.yml \
    -l concourse-bosh-deployment/versions.yml \
    -l vars/concourse-vars-file.yml \
    -o concourse-bosh-deployment/cluster/operations/basic-auth.yml \
    -o concourse-bosh-deployment/cluster/operations/privileged-http.yml \
    -o concourse-bosh-deployment/cluster/operations/privileged-https.yml \
    -o concourse-bosh-deployment/cluster/operations/tls.yml \
    -o concourse-bosh-deployment/cluster/operations/tls-vars.yml \
    -o concourse-bosh-deployment/cluster/operations/web-network-extension.yml \
    -o concourse-bosh-deployment/cluster/operations/scale.yml \
    -o concourse-bosh-deployment/cluster/operations/credhub.yml \
    --var-file credhub_ca_cert=./credhub_ca_cert
