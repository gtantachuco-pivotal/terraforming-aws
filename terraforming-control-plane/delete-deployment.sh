set -e

source ./set-bosh-proxy.sh

bosh delete-deployment -d concourse

om -t $OM_TARGET -u $(terraform output ops_manager_username) \
-p $(terraform output ops_manager_password) --skip-ssl-validation delete-installation

terraform destroy -auto-approve