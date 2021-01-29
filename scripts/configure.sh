#!/bin/bash
# Configure environment for user curry

# clone .emacs configuration from github
git clone https://github.com/abailly/dotfiles ~/dotfiles
ln -s ~/dotfiles/.emacs ~/.emacs
ln -s ~/dotfiles/.tmux.conf ~/.tmux.conf

emacs --batch -q -l dotfiles/install.el

# clone hydra repositories and update remote to be able
# to push later on
git clone https://github.com/abailly/hydra-sim ~/hydra-sim

if [ -d ~/hydra-sim ]; then
    pushd ~/hydra-sim
    git remote set-url origin git@github.com:abailly/hydra-sim
    popd
fi

# configure cachix
source /etc/profile.d/nix.sh

nix-env -i direnv

if ! [ -z "$CACHIX_AUTHENTICATION" ] ; then
    # we use absolute path to default
    nix-env -iA cachix -f https://cachix.org/api/v1/install
    cachix authtoken "$CACHIX_AUTHENTICATION"
    cachix use hydra-sim
fi

if [ -d ~/hydra-sim ]; then
    pushd ~/hydra-sim
    # ensure everything is built
    nix-build
    direnv allow

    # configure nix-shell then exit
    # there's probably a better way to do this
    ( nix-shell ; exit )
    popd
fi
