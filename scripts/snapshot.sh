#!/bin/sh
# Updates a snapshot from VM disk
# This first deletes the previous snapshot, which might not be a great idea.
# Should probably have rolling upgrades?

SNAPSHOT_NAME=haskell-dev-vm-snapshot
DISK_NAME=haskell-dev-vm-disk
PROJECT=$(terraform output -raw project)

gcloud auth activate-service-account --key-file=${GOOGLE_APPLICATION_CREDENTIALS}

# Ensure disk exists before creating snapshot
if gcloud "--project=${PROJECT}" compute disks list | grep $DISK_NAME ; then
    gcloud "--project=${PROJECT}" compute snapshots delete $SNAPSHOT_NAME
    gcloud "--project=${PROJECT}" compute disks snapshot $DISK_NAME --snapshot-names=$SNAPSHOT_NAME  --description="Snapshot - $(date "+%Y-%m-%d")" --zone europe-west4-b
fi
