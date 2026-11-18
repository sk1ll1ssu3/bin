yay -Syu --noconfirm
sudo pacman -Sc --noconfirm
yay -Sc --noconfirm
if [ -n "$(pacman -Qtdq)" ]; then
    sudo pacman -Rns --noconfirm $(pacman -Qtdq)
fi
sudo journalctl --vacuum-time=7d
sudo systemd-tmpfiles --clean
rustup update
if [ "$1" = "--update-ml4w" ]
then
  bash <(curl -s https://ml4w.com/os/stable)
fi
