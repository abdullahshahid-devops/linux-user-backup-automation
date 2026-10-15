#!/bin/bash

# Linux User Management and Backup Automation

echo "======================================"
echo " Linux User Management & Backup Tool"
echo "======================================"

while true
do
    echo ""
    echo "1. Show Current User"
    echo "2. Check Disk Usage"
    echo "3. Create Backup"
    echo "4. Add Linux User"
    echo "5. Manage Linux Groups"
    echo "6. Delete Linux User"
    echo "7. Modify User Login Shell"
    echo "8. Exit"
    echo ""

    read -r -p "Enter your choice (1-8): " choice

    case "$choice" in
        1)
            echo "Current Linux user:"
            whoami
            ;;

        2)
            echo "Disk usage of the root filesystem:"
            df -h /
            ;;

        3)
            echo "Starting backup..."

            source_dir="$HOME/linux-user-backup/test-data"
            backup_dir="$HOME/linux-user-backup/backups"
            timestamp=$(date +%Y%m%d_%H%M%S)
            archive="$backup_dir/backup_${timestamp}.tar.gz"

            if [[ ! -d "$source_dir" ]]; then
                echo "Error: Source directory does not exist."
            else
                mkdir -p "$backup_dir"

                if tar -czf "$archive" \
                    -C "$HOME/linux-user-backup" test-data; then
                    echo "Backup completed successfully!"
                    echo "Backup file: $archive"
                else
                    echo "Backup failed."
                fi
            fi
            ;;

        4)
            read -r -p "Enter a new username: " new_user

            if [[ ! "$new_user" =~ ^[a-z_][a-z0-9_-]*$ ]]; then
                echo "Invalid username format."
            elif getent passwd "$new_user" > /dev/null; then
                echo "User already exists."
            else
                if sudo adduser "$new_user"; then
                    echo "User created successfully."
                else
                    echo "User creation failed."
                fi
            fi
            ;;

        5)
            echo ""
            echo "Linux Group Management"
            echo "1. Create a group"
            echo "2. Add a user to a group"
            read -r -p "Choose an option (1-2): " group_choice

            case "$group_choice" in
                1)
                    read -r -p "Enter the new group name: " group_name

                    if [[ ! "$group_name" =~ ^[a-z_][a-z0-9_-]*$ ]]; then
                        echo "Invalid group name format."
                    elif getent group "$group_name" > /dev/null; then
                        echo "Group already exists."
                    elif sudo groupadd "$group_name"; then
                        echo "Group created successfully."
                    else
                        echo "Group creation failed."
                    fi
                    ;;

                2)
                    read -r -p "Enter an existing username: " member_user
                    read -r -p "Enter an existing group name: " member_group

                    if ! getent passwd "$member_user" > /dev/null; then
                        echo "Error: User does not exist."
                    elif ! getent group "$member_group" > /dev/null; then
                        echo "Error: Group does not exist."
                    elif id -nG "$member_user" | tr ' ' '\n' \
                        | grep -Fxq -- "$member_group"; then
                        echo "User is already a member of this group."
                    elif sudo usermod -aG "$member_group" "$member_user"; then
                        echo "User added to group successfully."
                    else
                        echo "Failed to add user to group."
                    fi
                    ;;

                *)
                    echo "Invalid group management option."
                    ;;
            esac
            ;;

        6)
            read -r -p "Enter the username to delete: " delete_user

            if [[ ! "$delete_user" =~ ^[a-z_][a-z0-9_-]*$ ]]; then
                echo "Invalid username format."
            elif [[ "$delete_user" == "root" ||
                    "$delete_user" == "$USER" ]]; then
                echo "Error: Refusing to delete root or the current user."
            elif ! getent passwd "$delete_user" > /dev/null; then
                echo "Error: User does not exist."
            else
                user_uid=$(id -u "$delete_user")

                if [[ "$user_uid" -lt 1000 ]]; then
                    echo "Error: Refusing to delete a system account."
                else
                    echo "WARNING: This deletes the account and its home directory."
                    read -r -p "Type DELETE to confirm: " confirmation

                    if [[ "$confirmation" == "DELETE" ]]; then
                        if sudo deluser --remove-home "$delete_user"; then
                            echo "User deleted successfully."
                        else
                            echo "User deletion failed."
                        fi
                    else
                        echo "Deletion cancelled."
                    fi
                fi
            fi
            ;;

        7)
            read -r -p "Enter the username to modify: " modify_user

            if ! getent passwd "$modify_user" > /dev/null; then
                echo "Error: User does not exist."
            elif [[ "$modify_user" == "root" ||
                    "$modify_user" == "$USER" ]]; then
                echo "Error: Refusing to modify root or the current user."
            elif [[ "$(id -u "$modify_user")" -lt 1000 ]]; then
                echo "Error: Refusing to modify a system account."
            else
                echo "Available login shells:"
                cat /etc/shells
                read -r -p "Enter the full path of the new shell: " new_shell

                if [[ ! -x "$new_shell" || ! -f "$new_shell" ]]; then
                    echo "Error: Shell must be an existing executable file."
                elif ! grep -Fxq -- "$new_shell" /etc/shells; then
                    echo "Error: Shell is not listed in /etc/shells."
                else
                    if sudo usermod -s "$new_shell" "$modify_user"; then
                        echo "Login shell updated successfully."
                        getent passwd "$modify_user"
                    else
                        echo "Failed to update login shell."
                    fi
                fi
            fi
            ;;

        8)
            echo "Goodbye, DevOps Engineer!"
            break
            ;;

        *)
            echo "Invalid choice. Please enter a number from 1 to 8."
            ;;
    esac
done
