yay -S awww-git --needed --noconfirm

create_generic_symlink $NFLUFF_PATH/dotconfig/nfluff $HOME/.config/nfluff
create_generic_symlink $NFLUFF_PATH/dotconfig/quickshell $HOME/.config/quickshell

if [[ ! -d $HOME/.local/share ]]; then
    mkdir -p $HOME/.local/share
fi
create_generic_symlink $NFLUFF_PATH/dotlocal/share $HOME/.local/share/nfluff
#
# set up default theme properly
$HOME/.local/share/nfluff/bin/change-theme $HOME/.config/nfluff/themes/default

export_bin_path=$HOME/.local/share/nfluff/bin
export_bin_line="PATH=$export_bin_path:\$PATH"

if [ -z $(grep "$export_bin_line" "$HOME/.bashrc") ]; 
    then echo $export_bin_line >> "$HOME/.bashrc";
fi
