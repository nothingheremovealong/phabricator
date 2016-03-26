#!/bin/bash

set -e

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# Install unzip
sudo apt-get install -y unzip

# Remove any existing zip first
sudo rm -f google-cloud-sdk.zip

# Download google-cloud_sdk
sudo wget https://dl.google.com/dl/cloudsdk/release/google-cloud-sdk.zip

# Unzip sdk into google directory
sudo unzip -uo google-cloud-sdk.zip -d /google/

sudo rm -f google-cloud-sdk.zip

if [ $(grep -c "\/google\/google-cloud-sdk\/bin" /etc/profile) -eq 0  ]; then
  echo "Adding google cloud SDK to path...";
  echo PATH=/google/google-cloud-sdk/bin:\$PATH | sudo tee /etc/profile
fi

sudo /google/google-cloud-sdk/install.sh \
  --rc-path=/etc/bash.bashrc \
  --usage-reporting=false \
  --command-completion=true \
  --path-update=true

sudo /google/google-cloud-sdk/bin/gcloud config set --installation component_manager/disable_update_check True
