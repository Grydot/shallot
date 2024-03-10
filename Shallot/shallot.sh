#!/bin/sh

# Program details
PROGRAM_NAME="Shallot"
VERSION="0.0.4"
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

# Function to display the full file list
display_file_list() {
    clear
    echo "=== Full File List ==="
    awk '{print NR ". " $0}' "$FILE_LIST"
    echo "q. Quit"
}

# Function to display search results
display_search_results() {
    clear
    echo "=== Search Results ==="
    awk '{print NR ". " $0}' "$SCRIPT_DIR/search_results.txt"
    echo "q. Quit"
}

# Function to download ROMs
download_roms() {
    if ! fetch_files; then
        echo "Retry fetching file list..."
        return
    fi

    # Delete search results upon first start
    rm -f "$SCRIPT_DIR/search_results.txt"

    local choice
    local search_term=""
    local display_search=false
    while true; do
        if [ -s "$SCRIPT_DIR/search_results.txt" ]; then
            display_search=true
            display_search_results
        else
            display_file_list
        fi
        printf "Enter the file number to download, 's' to search, or 'q' to quit: "
        read choice
        case $choice in
            q)
                echo "Exiting..."
                return
                ;;
            s)
                printf "Enter search term: "
                read search_term
                if [ -z "$search_term" ]; then
                    echo "Search term cannot be empty."
                    continue
                fi
                grep -i "$search_term" "$FILE_LIST" > "$SCRIPT_DIR/search_results.txt"
                ;;
            *[!0-9]*)
                echo "Invalid selection. Please enter a number, 's' to search, or 'q' to quit."
                ;;
            *)
                if [ "$display_search" = true ]; then
                    selected_file=$(awk "NR==$choice" "$SCRIPT_DIR/search_results.txt")
                else
                    selected_file=$(awk "NR==$choice" "$FILE_LIST")
                fi
                if [ -z "$selected_file" ]; then
                    echo "Invalid file number. Please try again."
                else
                    mkdir -p "$ROMS_DIR"
                    # Integrate rsync progress here
                    echo "Downloading '$selected_file' to '$ROMS_DIR'..."
                    rsync --progress "rsync://$RSYNC_SERVER/$REMOTE_DIR$selected_file" "$ROMS_DIR/"
                    echo "File '$selected_file' downloaded successfully to '$ROMS_DIR'."
                    unzip -q "$ROMS_DIR/$selected_file" -d "$ROMS_DIR/"
                    echo "File '$selected_file' unzipped successfully."
                    rm -f "$ROMS_DIR/$selected_file"
                    echo "File '$selected_file' deleted."
                    # Reset search results and search term after successful download
                    rm -f "$SCRIPT_DIR/search_results.txt"
                    search_term=""
                    read -n 1 -s -r -p "Press any key to continue..."
                    return
                fi
                ;;
        esac
    done
}

# Function for Transfer menu option
transfer() {
    echo "Transfer option selected."
    echo "Listing downloaded ROMs..."
    local current_dir=$(pwd)  # Store the current directory
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
    cd "$current_dir"  # Return to the original directory
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
