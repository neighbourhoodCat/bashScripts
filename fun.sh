#!/bin/bash
#what the dog doing?

RED=$'\e[31m'; GREEN=$'\e[32m'; YELLOW=$'\e[33m'; CYAN=$'\e[36m'; BOLD=$'\e[1m'; RESET=$'\e[0m'
LINE="------------------------------------------"

confirm() {
    read -p " Are you sure? (yes/no) " answer
    case "$answer" in
        yes|y) return 0 ;;
        no|n)  echo " ${YELLOW}Cancelled, phew.${RESET}"; return 1 ;;
        *)     echo " Please answer yes/no only"; return 1 ;;
    esac
}

show_menu() {
    echo
    echo "${BOLD}${CYAN} Hello $USER, what you want to do?${RESET}"
    echo " 1. Shutdown OS"
    echo " 2. Reboot OS"
    echo " 3. OS release"
    echo " 4. Flex your OS!"
    echo " 5. Checking resource usage"
    echo " 0. Quit"
}

flex_os() {
    if command -v fastfetch >/dev/null; then
        fastfetch
    elif command -v neofetch >/dev/null; then
        neofetch
    else
        echo " No fastfetch installed, so here's the basics:"
        echo " Kernel: $(uname -sr)"
        echo " Shell:  $SHELL"
        echo " Host:   $(hostname)"
    fi
}

while true; do
    show_menu
    read -p " Choose your option: " option
    echo
    case "$option" in
        1) confirm && { echo " Type your password"; sudo systemctl poweroff; } ;;
        2) confirm && { echo " Type your password"; sudo systemctl reboot; } ;;
        3) echo "$LINE"; cat /etc/os-release; echo "$LINE" ;;
        4) echo "$LINE"; flex_os; echo "$LINE" ;;
        5) uptime -p; free -h; df -h / ;;
        0|q|quit) echo " ${CYAN}Bye $USER!${RESET}"; exit 0 ;;
        *) echo " ${RED}Please select only 0-5${RESET}" ;;
    esac
done
