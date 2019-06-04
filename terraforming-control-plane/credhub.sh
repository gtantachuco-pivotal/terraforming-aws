#!/bin/bash
set -e

source ./set-bosh-proxy.sh

credhub login
credhub import --file ./credhub-import-pks.yml
