cd ~/
rm -rf ~/.emacs.d
git clone https://git@github.com/syl20bnr/spacemacs .emacs.d
rm -rf ~/.spacemacs.d
git clone https://git@github.com/hershal/spacemacs.d .spacemacs.d
cd ~/.spacemacs.d
git remote set-url origin ssh://git@github.com/hershal/spacemacs.d
