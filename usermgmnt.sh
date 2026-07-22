#!/bin/bash
#
# usermgmnt.sh - interactive Linux user management menu

set -euo pipefail
IFS=$'\n\t'

LOG_FILE="/var/log/usermgmnt.log"
USERNAME_RE='^[a-z_][a-z0-9_-]{0,31}$'

# ---------- helpers ----------

log() {
    local msg="$1"
    local ts
    ts="$(date '+%Y-%m-%d %H:%M:%S')"
    if [[ -w "$(dirname "$LOG_FILE")" || -w "$LOG_FILE" ]]; then
        echo "$ts [${SUDO_USER:-$USER}] $msg" >>"$LOG_FILE" 2>/dev/null || true
    fi
}

err() { echo "Error: $1" >&2; }

require_root() {
    if [[ "$EUID" -ne 0 ]]; then
        err "this action needs root — restart with: sudo $0"
        return 1
    fi
}

valid_username() {
    [[ "$1" =~ $USERNAME_RE ]]
}

confirm() {
    local prompt="$1" reply
    read -r -p "$prompt [y/N] " reply
    [[ "$reply" =~ ^[Yy]$ ]]
}

ask() {
    local prompt="$1" default="${2:-}" reply
    if [[ -n "$default" ]]; then
        read -r -p "$prompt [$default]: " reply
        echo "${reply:-$default}"
    else
        read -r -p "$prompt: " reply
        echo "$reply"
    fi
}

ask_username() {
    local username
    while true; do
        read -r -p "Username: " username
        if valid_username "$username"; then
            echo "$username"
            return 0
        fi
        err "invalid username (lowercase letters/digits/_/-, must start with letter or _)"
    done
}

pause() {
    read -r -p "Press Enter to continue... " _
}

# ---------- actions ----------

action_add() {
    require_root || { pause; return; }
    local username
    username="$(ask_username)"
    if id "$username" &>/dev/null; then
        err "user '$username' already exists"
        pause; return
    fi

    local shell comment group expiry add_sudo
    shell="$(ask "Login shell" "/bin/bash")"
    comment="$(ask "Full name / comment" "")"
    group="$(ask "Primary group (blank = default)" "")"
    expiry="$(ask "Expiry date YYYY-MM-DD (blank = none)" "")"
    confirm "Add '$username' to sudo group?" && add_sudo=1 || add_sudo=0

    local -a args=(-m -s "$shell")
    [[ -n "$group" ]] && args+=(-g "$group")
    [[ -n "$comment" ]] && args+=(-c "$comment")
    [[ -n "$expiry" ]] && args+=(-e "$expiry")

    if useradd "${args[@]}" "$username"; then
        passwd -l "$username" >/dev/null
        [[ "$add_sudo" -eq 1 ]] && usermod -aG sudo "$username"
        log "added user '$username' (sudo=$add_sudo)"
        echo "User '$username' created (locked)."
        if confirm "Set a password now?"; then
            passwd "$username"
            log "set initial password for '$username'"
        fi
    else
        err "failed to create user '$username'"
    fi
    pause
}

action_del() {
    require_root || { pause; return; }
    local username
    username="$(ask_username)"
    if ! id "$username" &>/dev/null; then
        err "user '$username' does not exist"
        pause; return
    fi

    local remove_home=0
    confirm "Also remove home directory?" && remove_home=1
    if confirm "Really delete user '$username'? This cannot be undone."; then
        local -a args=()
        [[ "$remove_home" -eq 1 ]] && args+=(-r)
        if userdel "${args[@]}" "$username"; then
            log "deleted user '$username' (remove_home=$remove_home)"
            echo "User '$username' deleted."
        else
            err "failed to delete user '$username'"
        fi
    else
        echo "Aborted."
    fi
    pause
}

action_mod() {
    require_root || { pause; return; }
    local username
    username="$(ask_username)"
    if ! id "$username" &>/dev/null; then
        err "user '$username' does not exist"
        pause; return
    fi

    local shell comment group expiry
    shell="$(ask "New login shell (blank = keep)" "")"
    comment="$(ask "New comment (blank = keep)" "")"
    group="$(ask "New primary group (blank = keep)" "")"
    expiry="$(ask "New expiry date YYYY-MM-DD (blank = keep)" "")"

    local -a args=()
    [[ -n "$shell" ]] && args+=(-s "$shell")
    [[ -n "$comment" ]] && args+=(-c "$comment")
    [[ -n "$group" ]] && args+=(-g "$group")
    [[ -n "$expiry" ]] && args+=(-e "$expiry")

    if [[ "${#args[@]}" -eq 0 ]]; then
        echo "No changes given."
    elif usermod "${args[@]}" "$username"; then
        log "modified user '$username' (${args[*]})"
        echo "User '$username' updated."
    else
        err "failed to modify user '$username'"
    fi
    pause
}

action_lock() {
    require_root || { pause; return; }
    local username
    username="$(ask_username)"
    if ! id "$username" &>/dev/null; then
        err "user '$username' does not exist"
    elif passwd -l "$username" >/dev/null; then
        log "locked user '$username'"
        echo "User '$username' locked."
    fi
    pause
}

action_unlock() {
    require_root || { pause; return; }
    local username
    username="$(ask_username)"
    if ! id "$username" &>/dev/null; then
        err "user '$username' does not exist"
    elif passwd -u "$username" >/dev/null; then
        log "unlocked user '$username'"
        echo "User '$username' unlocked."
    fi
    pause
}

action_passwd() {
    require_root || { pause; return; }
    local username
    username="$(ask_username)"
    if ! id "$username" &>/dev/null; then
        err "user '$username' does not exist"
    else
        passwd "$username" && log "changed password for user '$username'"
    fi
    pause
}

action_list() {
    echo
    printf "%-20s %-8s %s\n" "USERNAME" "UID" "SHELL"
    getent passwd | awk -F: '$3 >= 1000 && $3 < 60000 {printf "%-20s %-8s %s\n", $1, $3, $7}'
    pause
}

action_info() {
    local username
    username="$(ask_username)"
    if ! id "$username" &>/dev/null; then
        err "user '$username' does not exist"
        pause; return
    fi
    echo
    id "$username"
    getent passwd "$username" | awk -F: '{print "home:  "$6"\nshell: "$7"\ngecos: "$5}'
    if [[ "$EUID" -eq 0 ]] && command -v chage &>/dev/null; then
        echo
        chage -l "$username"
    fi
    pause
}

# ---------- menu ----------

menu() {
    clear
    cat <<EOF
=========================================
   User Management
   $( [[ "$EUID" -eq 0 ]] && echo "[root]" || echo "[unprivileged - some actions need sudo]" )
=========================================
  1) Add user
  2) Delete user
  3) Modify user
  4) Lock user
  5) Unlock user
  6) Change password
  7) List users
  8) User info
  9) Exit
-----------------------------------------
EOF
}

main() {
    while true; do
        menu
        local choice
        read -r -p "Choose an option [1-9]: " choice
        case "$choice" in
            1) action_add ;;
            2) action_del ;;
            3) action_mod ;;
            4) action_lock ;;
            5) action_unlock ;;
            6) action_passwd ;;
            7) action_list ;;
            8) action_info ;;
            9) echo "Bye."; exit 0 ;;
            *) err "invalid choice"; pause ;;
        esac
    done
}

main
