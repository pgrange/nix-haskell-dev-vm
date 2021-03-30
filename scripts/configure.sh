#!/bin/bash
# Configure environment for user curry

# clone .emacs configuration from github
git clone https://github.com/abailly-iohk/dotfiles ~/dotfiles
[[ -L ~/.emacs ]] || ln -s ~/dotfiles/.emacs ~/.emacs
[[ -L ~/.tmux.conf ]] || ln -s ~/dotfiles/.tmux.conf ~/.tmux.conf
[[ -L ~/.gitconfig ]] || ln -s ~/dotfiles/.gitconfig ~/.gitconfig

emacs --batch -q -l dotfiles/install.el

# accept github.com key
ssh-keyscan github.com >> ~/.ssh/known_hosts

# download public keys of interest
gpg --keyserver keys.openpgp.org --recv 39AF57FB92B465F8AE6FD1BCCB4571C05D7B9E12 B73C82125079C8FC79666FFA59FAA903C906659A

# clone or update hydra repositories
for repo in "hydra-node cardano-ledger-specs ouroboros-network hydra-sim plutus"; do
    if [[ ! -d "~/$repo" ]]; then
        git clone "git@github.com:input-output-hk/$repo"
    else
        pushd "~/$repo"
        git pull
        popd
    fi
done

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

