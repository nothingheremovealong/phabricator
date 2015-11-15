#!/bin/bash

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# Install unzip
sudo apt-get install -y unzip

# Remove any existing zip first
rm -f google-cloud-sdk.zip

# Download google-cloud_sdk
wget https://dl.google.com/dl/cloudsdk/release/google-cloud-sdk.zip

# Unzip sdk into google directory
unzip google-cloud-sdk.zip -d /google/

rm -f google-cloud-sdk.zip

if [ $(grep -c "\/google\/google-cloud-sdk\/bin" /etc/profile) -eq 0  ]; then
  echo "Adding google cloud SDK to path...";
  echo PATH=/google/google-cloud-sdk/bin:\$PATH >> /etc/profile
fi
