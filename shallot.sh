#!/bin/sh

# Program details
PROGRAM_NAME="Shallot"
VERSION="0.0.2"
RSYNC_SERVER="rsync.myrient.erista.me"
REMOTE_DIR="files/No-Intro/Nintendo - Game Boy Advance/"
SCRIPT_DIR=$(dirname "$0")
FILE_LIST="$SCRIPT_DIR/file_list.txt"
ROMS_DIR="$SCRIPT_DIR/Roms"  # Folder to store downloaded ROMs
DEST_DIR="/mnt/SDCARD/Roms/GBA" # Destination directory for transferred ROMs

# Function to display the main menu
display_menu() {
    clear
    echo "===================================================="
    echo "        Welcome to $PROGRAM_NAME v$VERSION    "
    echo "        Created by @Grydot / ROMs by Erista    "
    echo "===================================================="
    echo " 1. Download ROMs"
    echo " 2. Transfer"
    echo " 3. Settings"
    echo " 4. Exit"
    echo "===================================================="
}

# Function to fetch list of files in remote directory using rsync
fetch_files() {
    [ -f "$FILE_LIST" ] && rm "$FILE_LIST"
    if rsync --list-only "rsync://$RSYNC_SERVER/$REMOTE_DIR" | awk 'NR > 6 { $1=$2=$3=$4=""; print substr($0,5); }' > "$FILE_LIST"; then
        return 0
    else
        echo "Failed to fetch file list."
        return 1
    fi
}

# Function to download ROMs
download_roms() {
    if ! fetch_files; then
        echo "Retry fetching file list..."
        return
    fi

    local choice
    while true; do
        display_file_list
        printf "Enter the file number to download (or 'q' to quit): "
        read choice
        case $choice in
            q)
                echo "Exiting..."
                return
                ;;
            *[!0-9]*)
                echo "Invalid selection. Please enter a number."
                ;;
            *)
                local selected_file=$(awk "NR==$choice" "$FILE_LIST")
                if [ -z "$selected_file" ]; then
                    echo "Invalid file number. Please try again."
                else
                    mkdir -p "$ROMS_DIR"
                    rsync "rsync://$RSYNC_SERVER/$REMOTE_DIR$selected_file" "$ROMS_DIR/"
                    echo "File '$selected_file' downloaded successfully to '$ROMS_DIR'."
                    unzip -q "$ROMS_DIR/$selected_file" -d "$ROMS_DIR/"
                    echo "File '$selected_file' unzipped successfully."
                    rm -f "$ROMS_DIR/$selected_file"
                    echo "File '$selected_file' deleted."
                    read -n 1 -s -r -p "Press any key to continue..."
                    return
                fi
                ;;
        esac
    done
}

# Function to display the full file list
display_file_list() {
    clear
    echo "=== Full File List ==="
    awk '{print NR ". " $0}' "$FILE_LIST"
    echo "q. Quit"
}


# Function for Transfer menu option
transfer() {
    echo "Transfer option selected."
    echo "Listing downloaded ROMs..."
    cd "$ROMS_DIR" || { echo "Failed to access ROMs directory."; return; }
    local rom_files
    rom_files=$(find . -maxdepth 1 -type f -exec basename {} \;)
    if [ -z "$rom_files" ]; then
        echo "No ROMs downloaded."
    else
        echo "The following ROMs are downloaded:"
        echo "$rom_files"
        read -p "Are you sure you want to transfer these ROMs to $DEST_DIR? (y/n): " confirm
        if [ "$confirm" = "y" ]; then
            echo "Transferring ROMs to $DEST_DIR..."
            mkdir -p "$DEST_DIR"
            for rom in *; do
                echo "Moving '$rom' to '$DEST_DIR'..."
                mv "$rom" "$DEST_DIR/"
            done
            echo "ROMs transferred successfully."
        else
            echo "Transfer canceled."
        fi
    fi
    read -n 1 -s -r -p "Press any key to continue..."
}

# Main function
main() {
    while true; do
        display_menu
        printf "Enter your choice: "
        read choice
        case $choice in
            1)
                download_roms
                ;;
            2)
                transfer
                ;;
            3)
                echo "Opening settings..."
                # Call your settings function here
                read -n 1 -s -r -p "Press any key to continue..."
                ;;
            4)
                echo "Exiting..."
                exit 0
                ;;
            *)
                echo "Invalid choice. Please try again."
                read -n 1 -s -r -p "Press any key to continue..."
                ;;
        esac
    done
}

# Run main function
main
