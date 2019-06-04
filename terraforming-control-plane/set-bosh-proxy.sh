#!/bin/bash
set -e

export EXTERNAL_HOST=$(terraform output control_plane_domain)
export OM_KEY=om.pem
terraform output ops_manager_ssh_private_key > $OM_KEY
chmod 0600 $OM_KEY
export OM_TARGET=$(terraform output ops_manager_dns)
CREDS=$(om -t $OM_TARGET -u $(terraform output ops_manager_username) \
-p $(terraform output ops_manager_password) --skip-ssl-validation curl --silent \
     -p /api/v0/deployed/director/credentials/bosh_commandline_credentials | \
  jq -r .credential | sed 's/bosh //g')
array=($CREDS)
for VAR in ${array[@]}; do
    export $VAR
done
export BOSH_CA_CERT="$(om -t $OM_TARGET -u $(terraform output ops_manager_username) \
-p $(terraform output ops_manager_password) --skip-ssl-validation certificate-authorities -f json | \
    jq -r '.[] | select(.active==true) | .cert_pem')"
export BOSH_ALL_PROXY="ssh+socks5://ubuntu@$OM_TARGET:22?private-key=$OM_KEY"
export CREDHUB_PROXY=$BOSH_ALL_PROXY
export CREDHUB_CLIENT=$BOSH_CLIENT
export CREDHUB_SECRET=$BOSH_CLIENT_SECRET
export CREDHUB_CA_CERT=$BOSH_CA_CERT
export CREDHUB_SERVER="https://$BOSH_ENVIRONMENT:8844"