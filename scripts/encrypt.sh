#!/bin/bash

PROJECT="pankzsoft-terraform-admin"
LOCATION="europe-west4"
KEY_RING="hydra-build-key-ring"
KEY_NAME="hydra-build-crypto-key"

gcloud kms encrypt \
  --project $PROJECT \
  --location $LOCATION  \
  --keyring $KEY_RING \
  --key $KEY_NAME \
  --plaintext-file - \
  --ciphertext-file - \
  | base64
