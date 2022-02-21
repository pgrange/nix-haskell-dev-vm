#!/bin/bash
# Configure environment for user curry

# fail if something goes wrong
set -e

# clone dotfiles from github
git clone https://github.com/abailly-iohk/dotfiles ~/dotfiles
[[ -L ~/.emacs ]] || ln -s ~/dotfiles/.emacs ~/.emacs
[[ -L ~/.tmux.conf ]] || ln -s ~/dotfiles/.tmux.conf ~/.tmux.conf
[[ -L ~/.gitconfig ]] || ln -s ~/dotfiles/.gitconfig ~/.gitconfig
[[ -L ~/.git-completion.sh ]] || ln -s ~/dotfiles/bash-completion.sh ~/.git-completion.sh

if [[ -f ~/.bashrc ]]; then
    rm ~/.bashrc
fi
ln -s ~/dotfiles/.bashrc ~/.bashrc

if [[ -f ~/.bash_aliases ]]; then
    rm ~/.bash_aliases
fi
ln -s ~/dotfiles/.bash_aliases ~/.bash_aliases

# run Emacs installation script, mostly for preinstalling a bunch of
# packages
emacs --batch -q -l dotfiles/install.el

# accept github.com key
ssh-keyscan github.com >> ~/.ssh/known_hosts

# download public keys of interest
gpg --keyserver keys.openpgp.org --recv 39AF57FB92B465F8AE6FD1BCCB4571C05D7B9E12 B73C82125079C8FC79666FFA59FAA903C906659A
curl https://api.github.com/users/KtorZ/gpg_keys | jq -r '.[] | .raw_key' | gpg --import
curl https://keybase.io/ktorz/pgp_keys.asc | gpg --import

# clone or update hydra repositories
for repo in hydra-poc cardano-ledger-specs ouroboros-network hydra-sim plutus plutus-apps cardano-node; do
    if [[ -d "$repo" ]]; then
        pushd "$repo"
        git pull
        popd
    else
        git clone "git@github.com:input-output-hk/$repo" || { echo "Failed to clone $repo, check 'ssh-add -l' shows up valid SSH keys"; exit 1 ; }
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
    nix-shell --run 'cabal update && cabal build all --enable-tests'

    # update cachix cache
    # from  https://github.com/cachix/cachix/issues/52#issuecomment-409515133
    nix-store -qR --include-outputs $(nix-instantiate shell.nix) | cachix push hydra-node
    popd
}

# configure_source ~/hydra-poc
