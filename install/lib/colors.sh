#!/bin/bash

RESET='\033[0m'

BLACK='\033[0;30m'
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
PURPLE="\033[0;35m"
CYAN='\033[0;36m'
GREY='\033[0;37m'

BBLACK='\033[1;30m'
BRED='\033[1;31m'
BGREEN='\033[1;32m'
BYELLOW='\033[1;33m'
BBLUE='\033[1;34m'
BPURPLE="\033[1;35m"
BCYAN='\033[1;36m'
BGREY='\033[1;37m'

DBLACK='\033[2;30m'
DRED='\033[2;31m'
DGREEN='\033[2;32m'
DYELLOW='\033[2;33m'
DBLUE='\033[2;34m'
DPURPLE="\033[2;35m"
DCYAN='\033[2;36m'
DGREY='\033[2;37m'

IBLACK='\033[3;30m'
IRED='\033[3;31m'
IGREEN='\033[3;32m'
IYELLOW='\033[3;33m'
IBLUE='\033[3;34m'
IPURPLE="\033[3;35m"
ICYAN='\033[3;36m'
IGREY='\033[3;37m'

echo_s() {
    echo -en "${RESET}${GREEN}"
    echo "$@"
    echo -en "${RESET}"
}
echo_e() {
    echo -en "${RESET}${RED}"
    echo "$@"
    echo -en "${RESET}"
}

echo_i() {
    echo -en "${RESET}${BPURPLE}"
    echo "$@"
    echo -en "${RESET}"
}
echo_g() {
    echo -en "${RESET}${DGREY}"
    echo "$@"
    echo -en "${RESET}"
}
