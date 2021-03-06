#!/bin/bash
# Configure environment for user curry

# clone .emacs configuration from github
git clone https://github.com/abailly-iohk/dotfiles ~/dotfiles
ln -s ~/dotfiles/.emacs ~/.emacs
ln -s ~/dotfiles/.tmux.conf ~/.tmux.conf

emacs --batch -q -l dotfiles/install.el

# clone hydra repositories and update remote to be able
# to push later on
git clone https://github.com/abailly-iohk/hydra-sim ~/hydra-sim

if [ -d ~/hydra-sim ]; then
    pushd ~/hydra-sim
    git remote set-url origin git@github.com:abailly-iohk/hydra-sim
    popd
fi

# clone hydra repositories and update remote to be able
# to push later on
git clone https://github.com/input-output-hk/hydra-node ~/hydra-node

if [ -d ~/hydra-sim ]; then
    pushd ~/hydra-sim
    git remote set-url origin git@github.com:input-output-hk/hydra-node
    popd
fi

# configure nix stuff
source /etc/profile.d/nix.sh

# direnv is used on a per-directory basis in projects, better
# install it now
nix-env  -f '<nixpkgs>' -iA direnv nix-direnv

if ! [ -z "$CACHIX_AUTHENTICATION" ] ; then
    nix-env -iA cachix -f https://cachix.org/api/v1/install
    cachix authtoken "$CACHIX_AUTHENTICATION"
    cachix use hydra-sim
fi

# Configure some source directory
function configure_source() {
    source_dir=$1
    pushd $source_dir

    # ensure everything is built
    nix-build
    direnv allow

    # configure nix-shell
    # there's probably a better way to do this
    nix-shell --run true
    popd
}

configure_source ~/hydra-sim
configure_source ~/hydra-node
