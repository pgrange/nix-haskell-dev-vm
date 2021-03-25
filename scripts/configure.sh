#!/bin/bash
# Configure environment for user curry

# clone .emacs configuration from github
git clone https://github.com/abailly-iohk/dotfiles ~/dotfiles
ln -s ~/dotfiles/.emacs ~/.emacs
ln -s ~/dotfiles/.tmux.conf ~/.tmux.conf
ln -s ~/dotfiles/.gitconfig ~/.gitconfig

emacs --batch -q -l dotfiles/install.el

# accept github.com key
ssh-keyscan github.com >> ~/.ssh/known_hosts

# download public keys of interest
gpg --keyserver keys.openpgp.org --recv 39AF57FB92B465F8AE6FD1BCCB4571C05D7B9E12 B73C82125079C8FC79666FFA59FAA903C906659A

# clone hydra repositories
git clone git@github.com:input-output-hk/hydra-node ~/hydra-node
git clone git@github.com:input-output-hk/cardano-ledger-specs ~/cardano-ledger-specs
git clone git@github.com:input-output-hk/ouroboros-network ~/ouroboros-network
git clone git@github.com:abailly-iohk/hydra-sim ~/hydra-sim
git clone git@github.com:abailly-iohk/plutus ~/plutus

# configure nix stuff
source /etc/profile.d/nix.sh

# direnv is used on a per-directory basis in projects, better
# install it now
nix-env  -f '<nixpkgs>' -iA direnv nix-direnv

# per https://github.com/nix-community/nix-direnv
cat > $HOME/.direnvrc <<EOF
source $HOME/.nix-profile/share/nix-direnv/direnvrc
EOF

# Ensure gpg socket is cleaned up on logout so that it can be forwarded again
cat >> ~/.bash_logout <<EOF
rm -f /run/user/$(id -u)/gnupg/S.gpg-agent
EOF

if ! [ -z "$CACHIX_AUTHENTICATION" ] ; then
    nix-env -iA cachix -f https://cachix.org/api/v1/install
    cachix authtoken "$CACHIX_AUTHENTICATION"
    cachix use hydra-node
fi

# Configure some source directory
function configure_source() {
    source_dir=$1
    pushd $source_dir

    # this is needed otherwise direnv will ignore it and LSP won't kickoff
    direnv allow .envrc

    # we still don't handle dependencies in nix so need to update cabal
    # lest we pay the price first time we build
    nix-shell --run 'cabal update && cabal test all'

    # update cachix cache
    # from  https://github.com/cachix/cachix/issues/52#issuecomment-409515133
    nix-store -qR --include-outputs $(nix-instantiate shell.nix) | cachix push hydra-node
    popd
}

configure_source ~/hydra-node

