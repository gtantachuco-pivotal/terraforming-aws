#!/bin/bash
set -e

om -t $(terraform output ops_manager_dns) --skip-ssl-validation \
  configure-authentication \
    --decryption-passphrase $(terraform output ops_manager_decryption_phrase) \
    --username $(terraform output ops_manager_username) \
    --password $(terraform output ops_manager_password)

echo "Configuring Ops Manager Director"

om -t $(terraform output ops_manager_dns) -u $(terraform output ops_manager_username) \
-p $(terraform output ops_manager_password) -k configure-director \
--config <(texplate execute ../ci/assets/template/director-config.yml -f  <(jq -e --raw-output '.modules[0].outputs | map_values(.value)' terraform.tfstate) -o yaml)

om -t $(terraform output ops_manager_dns) -u $(terraform output ops_manager_username) \
-p $(terraform output ops_manager_password) -k apply-changes

