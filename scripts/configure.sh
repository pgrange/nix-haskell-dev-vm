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

# clone hydra repositories and update remote to be able
# to push later on
git clone git@github.com:input-output-hk/hydra-node ~/hydra-node

# configure nix stuff
source /etc/profile.d/nix.sh

# direnv is used on a per-directory basis in projects, better
# install it now
nix-env  -f '<nixpkgs>' -iA direnv nix-direnv

# per https://github.com/nix-community/nix-direnv
cat > $HOME/.direnvrc <<EOF
source $HOME/.nix-profile/share/nix-direnv/direnvrc
EOF

cat | sudo tee /etc/nix/nix.conf <<EOF
keep-derivations = true
keep-outputs = true
EOF

if ! [ -z "$CACHIX_AUTHENTICATION" ] ; then
    nix-env -iA cachix -f https://cachix.org/api/v1/install
    cachix authtoken "$CACHIX_AUTHENTICATION"
    # TODO create dedicated cache?
    cachix use hydra-sym
fi

# Configure some source directory
function configure_source() {
    source_dir=$1
    pushd $source_dir

    # this is needed otherwise direnv will ignore it and LSP won't kickoff
    direnv allow .envrc

    # configure nix-shell
    # there's probably a better way to do this
    nix-shell --run true

    # we still don't handle dependencies in nix so need to update cabal
    # lest we pay the price first time we build
    cabal update && cabal test local-cluster
    popd
}

configure_source ~/hydra-node
