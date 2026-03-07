#!/bin/bash

echo " Hello $USER"
sleep 1
echo " This is user management script"
sleep 1
echo " Choose you options"
sleep 2

function adduser () {

	echo " you choose add user option"
	echo " want to add home?" 
	read -rp " yes/no" add_home
		if [[  "$add_home" == "yes" || "$add_home" == "y" ]]
			then
			add_home="-m"
		elif [[  "$add_home" == "no" || "$add_home" == "n" ]]
			then
			add_home=""
		else echo " Please input only yes/no"
		fi
	# echo " want to specify home directory?"
	# read -rp " yes/no" home_dir
	# echo " want to specify primary group?"
	# read -rp " yes/no" pri_group
	# echo " want to append secondary group?"
	# read -rp " yes/no" sec_group
	# echo " want to specify shell login?"
	# read -rp " yes/no" shell_login
	# echo " want to add comment to account?"
	# read -rp " yes/no" comment_acc
	# echo " want to specify user ID?"
	# read -rp " yes/no" user_id
	# echo " want to Specifies an expiration date for the user account?"
	# read -rp " yes/no" exp_date
	# echo " want to Specifies the number of days after which the user account will be disabled if the user doesn't log in?"
	# read -rp " yes/no" exp_num
	#command result output
	#sudo useradd "$add_home" "$home_dir" "$pri_group" "$sec_group" "$shell_login" "$comment_acc" "$user_id" "$exp_date" "$exp_num"
}