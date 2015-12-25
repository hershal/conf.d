git clone https://git@github.com/syl20bnr/spacemacs .emacs.d
git clone https://git@github.com/hershal/conf.d
source ~/conf.d/bashrc
cd ~/
update_links ~/conf.d/bashrc
update_links ~/conf.d/screenrc
update_links ~/conf.d/zsh/zshrc
update_links ~/conf.d/zsh/zprezto
update_links ~/conf.d/zsh/zpreztorc
update_links ~/conf.d/ssh

cd ~/conf.d/
git remote set-url origin ssh://git@github.com/hershal/conf.d
