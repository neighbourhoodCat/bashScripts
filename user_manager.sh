#!/usr/bin/env bash
#
# user_manager.sh - Interactive Linux user management menu
#
# Lets you add, delete, modify, lock/unlock, and inspect system users
# without having to remember useradd/usermod/userdel/passwd syntax.
#
# Usage: ./user_manager.sh   (will re-run itself with sudo if needed)

set -uo pipefail

# ---------------------------------------------------------------------------
# Re-exec with sudo if not root, since all user-management commands need it.
# ---------------------------------------------------------------------------
if [[ $EUID -ne 0 ]]; then
    exec sudo -- "$0" "$@"
fi

# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

pause() {
    echo
    read -rp "Press Enter to continue..." _
}

divider() { printf '%s\n' "------------------------------------------------------------"; }

# Prompt for a username and make sure it's not empty.
read_username() {
    local prompt="$1" varname="$2" input
    while true; do
        read -rp "$prompt" input
        if [[ -z "$input" ]]; then
            echo "Username cannot be empty."
            continue
        fi
        printf -v "$varname" '%s' "$input"
        return 0
    done
}

user_exists() { id "$1" &>/dev/null; }

confirm() {
    local prompt="$1" reply
    read -rp "$prompt [y/N]: " reply
    [[ "$reply" =~ ^[Yy]$ ]]
}

# ---------------------------------------------------------------------------
# Actions
# ---------------------------------------------------------------------------

list_users() {
    divider
    printf '%-20s %-6s %-6s %-25s %-10s %s\n' "USERNAME" "UID" "GID" "HOME" "SHELL" "FULL NAME"
    divider
    awk -F: '$3 >= 1000 && $1 != "nobody" {print $1, $3, $4, $6, $7, $5}' /etc/passwd |
        while read -r name uid gid home shell comment; do
            printf '%-20s %-6s %-6s %-25s %-10s %s\n' "$name" "$uid" "$gid" "$home" "$shell" "$comment"
        done
    divider
    echo "(Only regular users with UID >= 1000 are shown. Use option 9 to see all users.)"
}

list_all_users() {
    divider
    printf '%-20s %-6s %-6s %-25s %s\n' "USERNAME" "UID" "GID" "HOME" "SHELL"
    divider
    awk -F: '{print $1, $3, $4, $6, $7}' /etc/passwd |
        while read -r name uid gid home shell; do
            printf '%-20s %-6s %-6s %-25s %s\n' "$name" "$uid" "$gid" "$home" "$shell"
        done
    divider
}

add_user() {
    local username fullname create_home shell make_admin pass

    read_username "New username: " username
    if user_exists "$username"; then
        echo "User '$username' already exists."
        return
    fi

    read -rp "Full name / comment (optional): " fullname
    read -rp "Create home directory? [Y/n]: " create_home
    local shell="/bin/bash"

    local -a args=(-m -c "$fullname" -s "$shell")
    if [[ "$create_home" =~ ^[Nn]$ ]]; then
        args=(-M -c "$fullname" -s "$shell")
    fi

    if useradd "${args[@]}" "$username"; then
        echo "User '$username' created."
    else
        echo "Failed to create user '$username'."
        return
    fi

    if confirm "Set a password for '$username' now?"; then
        passwd "$username"
    else
        echo "No password set. Account is locked until a password is set."
    fi

    if confirm "Grant this user sudo/admin privileges?"; then
        local admin_group="sudo"
        getent group sudo &>/dev/null || admin_group="wheel"
        usermod -aG "$admin_group" "$username" && echo "Added '$username' to '$admin_group' group."
    fi
}

delete_user() {
    local username

    read_username "Username to delete: " username
    if ! user_exists "$username"; then
        echo "User '$username' does not exist."
        return
    fi

    echo "User info:"
    id "$username"

    if ! confirm "Are you SURE you want to delete '$username'?"; then
        echo "Cancelled."
        return
    fi

    local remove_home="-r"
    if ! confirm "Also delete home directory and mail spool?"; then
        remove_home=""
    fi

    if userdel $remove_home "$username"; then
        echo "User '$username' deleted."
    else
        echo "Failed to delete '$username' (they may be logged in; check with 'who')."
    fi
}

modify_user() {
    local username choice

    read_username "Username to modify: " username
    if ! user_exists "$username"; then
        echo "User '$username' does not exist."
        return
    fi

    while true; do
        divider
        id "$username"
        echo "Current shell: $(getent passwd "$username" | cut -d: -f7)"
        divider
        cat <<MENU
1) Change full name / comment
2) Rename user
3) Change home directory
4) Add to a group
5) Remove from a group
0) Back to main menu
MENU
        read -rp "Choose an option: " choice
        case "$choice" in
            1)
                read -rp "New full name: " val
                usermod -c "$val" "$username" && echo "Updated."
                ;;
            2)
                read -rp "New username: " val
                usermod -l "$val" "$username" && { echo "Renamed to '$val'."; username="$val"; }
                ;;
            3)
                read -rp "New home directory: " val
                if confirm "Move contents of old home to new location?"; then
                    usermod -d "$val" -m "$username" && echo "Updated."
                else
                    usermod -d "$val" "$username" && echo "Updated."
                fi
                ;;
            4)
                read -rp "Group to add user to: " val
                usermod -aG "$val" "$username" && echo "Added to '$val'."
                ;;
            5)
                read -rp "Group to remove user from: " val
                gpasswd -d "$username" "$val" && echo "Removed from '$val'."
                ;;
            0) return ;;
            *) echo "Invalid option." ;;
        esac
        pause
    done
}

change_password() {
    local username

    read_username "Username: " username
    if ! user_exists "$username"; then
        echo "User '$username' does not exist."
        return
    fi
    passwd "$username"
}

lock_user() {
    local username
    read_username "Username to lock: " username
    if ! user_exists "$username"; then
        echo "User '$username' does not exist."
        return
    fi
    usermod -L "$username" && echo "Account '$username' locked (password disabled)."
}

unlock_user() {
    local username
    read_username "Username to unlock: " username
    if ! user_exists "$username"; then
        echo "User '$username' does not exist."
        return
    fi
    usermod -U "$username" && echo "Account '$username' unlocked."
}

change_shell() {
    local username current choice shell

    read_username "Username: " username
    if ! user_exists "$username"; then
        echo "User '$username' does not exist."
        return
    fi

    current=$(getent passwd "$username" | cut -d: -f7)
    echo "Current shell for '$username': $current"
    divider

    local -a shells=()
    if [[ -r /etc/shells ]]; then
        while IFS= read -r line; do
            [[ "$line" =~ ^# ]] && continue
            [[ -z "$line" ]] && continue
            shells+=("$line")
        done < /etc/shells
    fi
    [[ ${#shells[@]} -eq 0 ]] && shells=(/bin/bash /bin/sh /usr/sbin/nologin)

    local i=1
    for s in "${shells[@]}"; do
        printf '%2d) %s\n' "$i" "$s"
        ((i++))
    done
    printf '%2d) Enter a custom path\n' "$i"

    read -rp "Choose a shell [1-$i]: " choice
    if [[ "$choice" == "$i" ]]; then
        read -rp "Custom shell path: " shell
    elif [[ "$choice" =~ ^[0-9]+$ ]] && (( choice >= 1 && choice < i )); then
        shell="${shells[$((choice-1))]}"
    else
        echo "Invalid choice."
        return
    fi

    usermod -s "$shell" "$username" && echo "Shell for '$username' set to '$shell'."
}

show_user_info() {
    local username
    read_username "Username to inspect: " username
    if ! user_exists "$username"; then
        echo "User '$username' does not exist."
        return
    fi
    divider
    id "$username"
    echo "Groups    : $(groups "$username" | cut -d: -f2)"
    echo "Home      : $(getent passwd "$username" | cut -d: -f6)"
    echo "Shell     : $(getent passwd "$username" | cut -d: -f7)"
    echo "Full name : $(getent passwd "$username" | cut -d: -f5)"
    echo "Password/account status:"
    passwd -S "$username" 2>/dev/null || chage -l "$username"
    divider
}

main_menu() {
    while true; do
        clear
        cat <<MENU
============================================================
                 USER MANAGEMENT MENU
============================================================
 1) List users (regular accounts)
 2) Add a new user
 3) Delete a user
 4) Modify a user (name, groups, home...)
 5) Change a user's password
 6) Change a user's default shell
 7) Lock a user account
 8) Unlock a user account
 9) Show detailed info for a user
10) List ALL users (including system accounts)
 0) Exit
============================================================
MENU
        read -rp "Choose an option: " choice
        echo
        case "$choice" in
            1) list_users ;;
            2) add_user ;;
            3) delete_user ;;
            4) modify_user ;;
            5) change_password ;;
            6) change_shell ;;
            7) lock_user ;;
            8) unlock_user ;;
            9) show_user_info ;;
            10) list_all_users ;;
            0) echo "Bye."; exit 0 ;;
            *) echo "Invalid option." ;;
        esac
        pause
    done
}

main_menu
