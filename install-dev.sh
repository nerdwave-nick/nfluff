#!/bin/bash
# exit on error
set -eEo pipefail

NFLUFF_PATH="$(realpath "$(dirname "$0")")"
cd "$NFLUFF_PATH" || exit


source ./installation/lib/colors.sh
source ./installation/lib/errors.sh
source ./installation/lib/install_packages.sh
source ./installation/lib/symlinks.sh

clear
source ./installation/steps/00_themes.sh

echo_s ":: nfluff installation is complete!"
