#!/bin/bash

echo " Hello $USER"
echo " What you want to do ?"
echo " 1. Shutdown OS"
echo " 2. Reboot OS"
echo " 3. OS release"
echo " 4. Flex your OS!"
echo " 5. Checking resource usage"

read -p " Choose you option " option
    if [ "$option" == 1 ]; then
        echo " Are you sure?"
        read -p " yes/no " confirm
            if [[ "$confirm" == "yes" || "$confirm" == "y" ]]; then
                echo " Type your password"
                sudo systemctl poweroff
            elif [[  "$confirm" == "no" || "$confirm" == "n" ]]; then
                echo " You cancel the shutdown"
            else
                echo " Please answer yes/no only"
            fi

    elif [[ "$option" == 2 ]]; then
        echo " Are you sure?"
        read -p " yes/no "  confirm
            if [[ "$confirm" == "yes" || "$confirm" == "y" ]]; then
                echo " Type your password"
                sudo systemctl reboot
            elif [[ "$confirm" == "no" || "$confirm" == "n" ]]; then
                echo " You cancel the reboot"
            else 
                echo " Please answer only yes/no "
            fi

    elif [[ "$option" == 3 ]]; then
        echo "------------------------------------------"
        cat /etc/os-release
        echo "------------------------------------------"
    elif [[ "$option" == 4  ]]; then
        echo "------------------------------------------"
        fastfetch 
        echo "------------------------------------------"
    elif [[ "$option" == 5 ]]; then
        echo "$(uptime -p)"
        echo "$(free -h)"
        echo "$(df -h /)"
    else
        echo " Plase select only 1/2/3/4/5"
    fi