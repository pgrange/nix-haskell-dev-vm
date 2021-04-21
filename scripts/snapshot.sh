#!/bin/sh
# Updates a snapshot from VM disk
# This first deletes the previous snapshot, which might not be a great idea.
# Should probably have rolling upgrades?

SNAPSHOT_NAME=iog-hydra-dev-vm-snapshot
BASE_DISK_NAME=haskell-dev-vm-disk

# extract project name from terraform's output or environment
PROJECT=${PROJECT:-$(terraform output -raw project)}

gcloud auth activate-service-account --key-file=${GOOGLE_APPLICATION_CREDENTIALS}

DISK_NAME=$(gcloud --project ${PROJECT} compute disks list | grep $BASE_DISK_NAME | head | cut -d ' ' -f1)

# Ensure disk exists before creating snapshot
if ! [ -z ${DISK_NAME} ] ; then
    gcloud "--project=${PROJECT}" compute snapshots delete $SNAPSHOT_NAME
    gcloud "--project=${PROJECT}" compute disks snapshot $DISK_NAME --snapshot-names=$SNAPSHOT_NAME  --description="Snapshot - $(date "+%Y-%m-%d")" --zone europe-west4-b
fi
