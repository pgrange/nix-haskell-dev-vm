# Development Environment

[Terraform](https://www.hashicorp.com/products/terraform) based code to setup a development environment for hacking Haskell code in general, and
projects using IOHK's infrastructure in particular. The VM will be configured to use:

* Vanilla [Emacs]() for editing code, with [lsp-mode](https://emacs-lsp.github.io/) using [lsp-haskell](https://emacs-lsp.github.io/lsp-haskell/) and [haskell-language-server](https://github.com/haskell/haskell-language-server),
* [nix](https://nixos.org/) for dependencies management and building Haskell code, with nix-shell providing the proper environment for emacs' LSP,
* [cachix](https://cachix.org/) configuration to speed up build,
* [direnv](https://direnv.net/) to provide a per-directory environment that will trigger entering nix.

# Install

## Building the base image

This is not mandatory and can be changed by editing the `image = dev-xxxx` parameter in [compute.tf](./compute.tf) but this code also provides [Packer](https://www.packer.io/) script to build a base image:

```
$ cd packer
$ packer build build.json
... <takes some time>
```

This base image will be named `dev-<timestamp>` and available for use once the build finishes. The configuration of the image is done using script [build-env.sh](./packer/build-env.sh).

## Deploying the VM

Initialise Terraform:

```
$ terraform init
```

Create a `compute.tfvars` containing a single variable for `cachix_authentication` token. It can be left empty, in which no additional cachix configuration will be done when the VM spins up.

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

The deployment takes about 14 minutes as it builds and configures nix-shell for the [hydra-sim](https://github.com/abailly/hydra-sim) project which, even with caching enabled, takes a while.

Then one should be able to log into the VM, start tmux and emacs, and then hack some stuff.
