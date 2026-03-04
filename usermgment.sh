#!/bin/bash


echo " Hello $USER"
echo " This is User management menu V1.0"
echo " Select action"
echo " 1. List user"
echo " 2. Add user"
echo " 3. Delete user"
echo " 4. Lock user"
echo " 5. Unlock user"
echo " 6. Change password"
echo " 7. Add to sudoers"
read -p " Select action. " action

    if [[ "$action" == "1" ]]; then
        echo " Here's user list"
        awk -F: '$3 >= 1000 {print $1}' /etc/passwd
    elif [[ "$action" == "2" ]]; then
        echo " Add user"
        echo " You want to add home?"
            read -p " yes/no" addhome
                if [[ "$addhome" == "yes" || "$addhome" == "y" ]]; then
                    homeuser="-m"
                elif [[ "$addhome" == "no" || "$addhome" == "n" ]]; then
                    homeuser=""
                else echo " Please choose only yes/no"
                fi
        echo " You want to custom uid?"
            read -p " yes / no" customidd
                if [[ "$customid" == "yes" || "$customid" == "y" ]]; then
                    echo " Type your custom id"
                    read -p " custom id " userid
                        if [[ "$userid" =~ ^[0-9]+$ ]]; then
                        echo " Your custom uid is "$userid""
                        customid="-G "$userid""
                        else echo " Invalid input please input number only"
                        fi
                elif [[ "$customid" == "no" || "$customid" == "n" ]]; then
                    echo " You choose no"
                    customid=""
        echo " You want to add to secondary groups?"
        echo " Select Shell for user"
        echo " type name of user"
        useradd $homeuser 
    elif [[ "$action" == "3" ]]; then
        echo " Delete user"
    elif [[ "$action" == "4" ]]; then
        echo " Lock user"
    elif [[ "$action" == "5" ]]; then
        echo " Unlock user"
    elif [[ "$action" == "6" ]]; then
        echo " Change user password"
    elif [[ "$action" == "7" ]]; then
        echo " Add to sudoers"
    else
        echo " Please select only avaliable actions"
    fi
    
    