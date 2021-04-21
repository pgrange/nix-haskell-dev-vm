# Development Environment

[Terraform](https://www.hashicorp.com/products/terraform) based code to setup a development environment for hacking Haskell code in general, and
projects using IOHK's infrastructure in particular. The VM will be configured to use:

* Vanilla [Emacs]() for editing code, with [lsp-mode](https://emacs-lsp.github.io/) using [lsp-haskell](https://emacs-lsp.github.io/lsp-haskell/) and [haskell-language-server](https://github.com/haskell/haskell-language-server),
* [nix](https://nixos.org/) for dependencies management and building Haskell code, with nix-shell providing the proper environment for emacs' LSP,
* [cachix](https://cachix.org/) configuration to speed up build,
* [direnv](https://direnv.net/) to provide a per-directory environment that will trigger entering nix.

# Install

## GCP

terraform and packer require access to GCP resources which is controlled by a _Service account_ configuration.

Assuming one has "admin" access to a GCP project, the following steps will create a service account, set the needed permissions and retriev a key file which can then be used to configure the scripts:

Create the service account:

```
$ gcloud iam service-accounts create hydra-poc-builder
```

Add needed permissions:

```
$ gcloud projects add-iam-policy-binding iog-hydra --member "serviceAccount:hydra-poc-builder@iog-hydra.iam.gserviceaccount.com" --role "roles/compute.admin"
$ gcloud projects add-iam-policy-binding iog-hydra --member "serviceAccount:hydra-poc-builder@iog-hydra.iam.gserviceaccount.com" --role "roles/iam.serviceAccountUser"
$ gcloud projects add-iam-policy-binding iog-hydra --member "serviceAccount:hydra-poc-builder@iog-hydra.iam.gserviceaccount.com" --role "roles/compute.instanceAdmin.v1"
$ gcloud projects add-iam-policy-binding iog-hydra --member "serviceAccount:hydra-poc-builder@iog-hydra.iam.gserviceaccount.com" --role "roles/storage.objectAdmin"
```

The service account must be able to create various `compute` instances, to modify the state which is stored inside a _Google Storage_ bucket, and to impersonate a service account user (unsure what this really means...).

Create service account's key file:

```
$ gcloud iam service-accounts keys create hydra-poc-builder.json --iam-account hydra-poc-builder@iog-hydra.iam.gserviceaccount.com
```

## Building the base image

This is not mandatory and can be changed by editing the `image = iog-hydra-xxxx` parameter in [compute.tf](./compute.tf) but this code also provides [Packer](https://www.packer.io/) script to build a base image:

```
$ cd packer
$ packer build build.json -var 'gcp_account_file=xxx' -var 'gcp_project_id=zzz'
... <takes some time>
```

The [builder](https://www.packer.io/docs/templates/builders) depends on two user variables that tells packer how to authenticate to GCP and which project to run the builder in. This base image will be named `iog-hydra-<timestamp>` and available for use once the build finishes. The configuration of the image is done using script [build-env.sh](./packer/build-env.sh).

## Deploying the VM

Initialise Terraform:

```
$ terraform init
```

Create a `compute.tfvars` containing a single variable for `cachix_authentication` token. It can be left empty, in which no additional cachix configuration will be done when the VM spins up.

Update the `ssh_keys` file with public keys that will be allowed to log into the VM, prefixing each key with `curry` or `root` depending on whether one wants to provide normal user or super-user access to the VM. Note the user `curry` will automatically be given `sudo` rights by the packer builder.

Then create a deployment plan and apply it:

```
$ terraform plan -out vm.plan  -var-file compute.tfvars
$ terraform apply vm.plan
... <takes some more time>

Apply complete! Resources: 2 added, 0 changed, 0 destroyed.

Outputs:

instance_id = https://www.googleapis.com/compute/v1/projects/xxx
instance_ip = X.Y.Z.T
```

### Snapshots

Deploying a VM from scratch takes a while, depending on the current set of projects configured (see [configure.sh](scripts/configure.sh)). To speed things up there's provision to replace the VM's image-based disk with a snapshot-based disk, and to create snapshots from a running VM.

Assuming VM is running, creating a snapshot is as simple as :

```
$ scripts/snapshot.sh
```


Using an existing snapshot requires setting the `use_snapshot` in terraform to `1`:

```
$ terraform apply -var-file=dev-vm.tfvars -var use_snapshot=1 -auto-approve
```

# Using the VM

Then one should be able to log into the VM as user `curry`, start tmux and emacs, and then hack some stuff.

To log in to the VM:

```
$ scripts/login.sh curry@haskell-dev-vm-1
```


# Troubleshooting

Most issues boil down to authentication or authorisation problems.

> Packer times out while trying to build an image

```
googlecompute: output will be in this color.

==> googlecompute: Checking image does not exist...
==> googlecompute: Creating temporary rsa SSH key for instance...
==> googlecompute: Using image: ubuntu-2004-focal-v20210112
==> googlecompute: Creating instance...
    googlecompute: Loading zone: europe-west4-a
    googlecompute: Loading machine type: n1-standard-1
    googlecompute: Requesting instance creation...
    googlecompute: Waiting for creation operation to complete...
==> googlecompute: Error creating instance: time out while waiting for instance to create
Build 'googlecompute' errored after 5 minutes 6 seconds: Error creating instance: time out while waiting for instance to create

==> Wait completed after 5 minutes 6 seconds

==> Some builds didn't complete successfully and had errors:
--> googlecompute: Error creating instance: time out while waiting for instance to create

==> Builds finished but no artifacts were created.
```

The `build.json` definition uses a service account which is passed through `gcp_account_file` variable. The service account probably is missing some permissions.

> Cannot log in to the VM using `scripts/login.sh`

This script uses `GOOGLE_APPLICATION_CREDENTIALS` environment variable to activate the corresponding service account and use `gcloud compute ssh` to log in. Check authorizations of the service account.

> Cannot log in to the VM using plain `ssh`

* The set of authorized public keys is defined in the [ssh_keys](./ssh_keys) file: Check there is a private key corresponding to this public key. Changing the `ssh_keys` file and re-running `terraform apply` does not entail recreation of the VM so it's pretty fast
* If `ssh-agent` is running, check that a private key corresponding to an authorized public key is loaded with `ssh-add -l`

> Terraform fails to run `scripts/configure.sh` on the VM

Terraform relies on plain SSH to connect to the VM, so this can be caused by the same problems as the previous issue

> Pushing or pulling to/from GitHub fails

* When log in to the VM, ensures agent forwarding (`ssh -A ...`) is set and that `ssh-agent` is running. Agent forwarding is enabled by default in the `scripts/login.sh`.
* The ordering of keys loaded in `ssh-agent` _matters_: Git will try each key in order until it succeeds to access `git@github.com`, and _then_ will try to access the repository. If a key is known to GitHub but does not have access to the repository, then git will fail without given much information. Check the order using `ssh-add -l` and fix it in case of doubts

> Some keyboard combinations for Emacs/Vim/Tmux are not available

This comes from the terminal and/or OS configuration which might capture certain combinations before sending them to the remote host.
