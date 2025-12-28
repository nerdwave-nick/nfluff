#!/bin/bash
# exit on error
set -eEo pipefail

NFLUFF_PATH="$(realpath "$(dirname "$0")")"
cd "$NFLUFF_PATH" || exit


source ./install/lib/colors.sh
source ./install/lib/errors.sh
source ./install/lib/install_packages.sh
source ./install/lib/symlinks.sh

clear
source ./install/steps/00_themes.sh

echo_s ":: nfluff installation is complete!"
