#!/bin/bash
# Connect to remote VM using creds/names given by $1

CONNECT_AS=$1
PROJECT=$(terraform output -raw project)

gcloud auth activate-service-account --key-file=${GOOGLE_APPLICATION_CREDENTIALS}

gcloud "--project=${PROJECT}" compute ssh "$CONNECT_AS" -- -A -o StreamLocalBindUnlink=yes \
       -o ForwardAgent=yes \
       -R /run/user/1001/gnupg/S.gpg-agent:/Users/arnaud/.gnupg/S.gpg-agent.extra \
       -L 8000:localhost:8000
