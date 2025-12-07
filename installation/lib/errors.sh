shitpost_error() {
    echo ""
    echo -e "${RESET}${RED}$(cat ./data/shrok.txt) ${RESET}"
    echo -en "${RESET}${RED}"
    echo "$@"
    echo -en "${RESET}"
    exit 1
}
