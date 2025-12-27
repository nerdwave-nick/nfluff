#!/bin/bash
install_from_file() {
    mapfile -t packages < <(grep -v '^#' "$NKISS_PATH/packages/$1" | grep -v '^$')
    echo_g ":: Installing ${packages[@]}"
    sudo pacman -S --noconfirm --needed "${packages[@]}"
}

install_from_file_yay() {
    mapfile -t packages < <(grep -v '^#' "$NKISS_PATH/packages/$1" | grep -v '^$')
    echo_g ":: Installing ${packages[@]}"
    yay -S --noconfirm --needed "${packages[@]}"
}

install_with_pacman() {
    read -a array <<< "$1"
    echo_g ":: Installing ${array[@]}"
    sudo pacman -S --noconfirm --needed "${array[@]}"
}
