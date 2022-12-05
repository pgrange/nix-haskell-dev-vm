#!/bin/bash -e
# Bootstrap a Debian machine with what's needed for pgrange to try
# to develop IOHK haskell code
#
# Run this script once when initializing your development machine

# ensure apt does not try to 'Dialog' with a user
export DEBIAN_FRONTEND=noninteractive

# Upgrade the machine
sudo apt-get -y update
sudo apt-get -y upgrade

# install smoother terminal interactions tools
sudo apt install -y tmux mosh

# Install doom emacs to code
sudo apt install -y emacs git ripgrep
git clone --depth 1 --single-branch https://github.com/doomemacs/doomemacs ~/.config/emacs
~/.config/emacs/bin/doom install
export PATH=$PATH:~/.config/emacs/bin

# Configure Doom Emacs for haskell
cat <<EOF >> ~/.config/doom/config.el
(setq lsp-enable-file-watchers nil
      lsp-ui-doc-enable nil
      lsp-ui-sideline-diagnostic-max-lines 5
      lsp-treemacs-errors-position-params '((side . right)))

;; Additional haskell mode key bindings
(map! :after haskell-mode
      :map haskell-mode-map
      :localleader
      "h" #'haskell-hoogle-lookup-from-local
      "H" #'haskell-hoogle)

(setq-hook! 'haskell-mode-hook +format-with-lsp nil)

;; Appropriate HLS is assumed to be in scope (by nix-shell)
(setq lsp-haskell-server-path "haskell-language-server"
      lsp-lens-enable nil
      lsp-signature-render-documentation 1
      lsp-headerline-breadcrumb-enable 1
      )
(defun add-autoformat-hook ()
  (add-hook 'before-save-hook '+format-buffer-h nil 'local))
(add-hook! (haskell-mode haskell-cabal-mode) 'add-autoformat-hook)

(set-formatter! 'fourmolu "fourmolu"
  :modes 'haskell-mode
  :filter
  (lambda (output errput)
    (list output
          (replace-regexp-in-string "Loaded config from:[^\n]*\n*" "" errput))))
EOF
sed  -i -e 's:;;helm:helm:' ~/.config/doom/init.el
sed  -i -e 's:;;ivy:ivy:' ~/.config/doom/init.el
sed  -i -e 's:;;lsp:lsp:' ~/.config/doom/init.el
sed  -i -e 's:;;(format +onsave):(format +onsave):' ~/.config/doom/init.el
sed  -i -e 's:;;(haskell +lsp):(haskell +lsp):' ~/.config/doom/init.el
sed  -i -e 's:;;multiple-cursors:multiple-cursors:' ~/.config/doom/init.el
sed  -i -e 's:;;direnv:direnv:' ~/.config/doom/init.el
doom sync

# install nix as per https://nixos.org/download.html
sh <(curl -L https://nixos.org/nix/install) --daemon
cat << EOF | sudo tee /etc/nix/nix.conf
trusted-users = root $(whoami)
substituters = https://cache.nixos.org https://hydra.iohk.io https://iohk.cachix.org
trusted-public-keys = iohk.cachix.org-1:DpRUyj7h7V830dp/i6Nti+NEO2/nhblbov/8MW7Rqoo= hydra.iohk.io:f/Ea+s+dFdN+3Y/G+FDgSq+a5NEWhJGzdjvKNGv0/EQ= cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY=
experimental-features = nix-command flakes
EOF
sudo systemctl restart nix-daemon.service

# install direnv
sudo apt install -y direnv
cat <<EOF >> $HOME/.bashrc

# load direnv in the shell
eval "\$(direnv hook bash)"
EOF

#install nix-direnv
mkdir -p $HOME/.config/direnv
cat <<EOF > $HOME/.config/direnv/direnvrc
if ! has nix_direnv_version || ! nix_direnv_version 2.1.1; then
  source_url "https://raw.githubusercontent.com/nix-community/nix-direnv/2.1.1/direnvrc" "sha256-b6qJ4r34rbE23yWjMqbmu3ia2z4b2wIlZUksBke/ol0="
fi
EOF


# Remember, the first time you want compile hskall project you might have to do:
# $> cabal update
