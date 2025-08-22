#!/bin/bash

#  ██████╗████████╗ ██████╗ ██████╗ 
# ██╔════╝╚══██╔══╝██╔═══██╗██╔══██╗
# ██║        ██║   ██║   ██║██████╔╝
# ██║        ██║   ██║   ██║██╔══██╗
# ╚██████╗   ██║   ╚██████╔╝██║  ██║
#  ╚═════╝   ╚═╝    ╚═════╝ ╚═╝  ╚═╝

# ███████╗ █████╗ ███████╗████████╗   ███████╗██╗██╗  ██╗
# ██╔════╝██╔══██╗██╔════╝╚══██╔══╝   ██╔════╝██║╚██╗██╔╝
# █████╗  ███████║███████╗   ██║█████╗█████╗  ██║ ╚███╔╝ 
# ██╔══╝  ██╔══██║╚════██║   ██║╚════╝██╔══╝  ██║ ██╔██╗ 
# ██║     ██║  ██║███████║   ██║      ██║     ██║██╔╝ ██╗
# ╚═╝     ╚═╝  ╚═╝╚══════╝   ╚═╝      ╚═╝     ╚═╝╚═╝  ╚═╝
                                                       
                                  
if tput setaf 1 >/dev/null 2>&1; then
    Color_Off="$(tput sgr0)"
    Black="$(tput setaf 0)"
    Red="$(tput setaf 1)"
    Green="$(tput setaf 2)"
    Yellow="$(tput setaf 3)"
    Blue="$(tput setaf 4)"
    Purple="$(tput setaf 5)"
    Cyan="$(tput setaf 6)"
    White="$(tput setaf 7)"

    BBlack="$(tput bold; tput setaf 0)"
    BRed="$(tput bold; tput setaf 1)"
    BGreen="$(tput bold; tput setaf 2)"
    BYellow="$(tput bold; tput setaf 3)"
    BBlue="$(tput bold; tput setaf 4)"
    BPurple="$(tput bold; tput setaf 5)"
    BCyan="$(tput bold; tput setaf 6)"
    BWhite="$(tput bold; tput setaf 7)"

    BIBlack="$(tput bold; tput setaf 8)"
    BIRed="$(tput bold; tput setaf 9)"
    BIGreen="$(tput bold; tput setaf 10)"
    BIYellow="$(tput bold; tput setaf 11)"
    BIBlue="$(tput bold; tput setaf 12)"
    BIPurple="$(tput bold; tput setaf 13)"
    BICyan="$(tput bold; tput setaf 14)"
    BIWhite="$(tput bold; tput setaf 15)"
else
    Color_Off="\033[0m"
    Black="\033[0;30m"
    Red="\033[0;31m"
    Green="\033[0;32m"
    Yellow="\033[0;33m"
    Blue="\033[0;34m"
    Purple="\033[0;35m"
    Cyan="\033[0;36m"
    White="\033[0;37m"

    BBlack="\033[1;30m"
    BRed="\033[1;31m"
    BGreen="\033[1;32m"
    BYellow="\033[1;33m"
    BBlue="\033[1;34m"
    BPurple="\033[1;35m"
    BCyan="\033[1;36m"
    BWhite="\033[1;37m"
    
    BIBlack="\033[1;90m"
    BIRed="\033[1;91m"
    BIGreen="\033[1;92m"
    BIYellow="\033[1;93m"
    BIBlue="\033[1;94m"
    BIPurple="\033[1;95m"
    BICyan="\033[1;96m"
    BIWhite="\033[1;97m"
fi

print_success() {
  echo -e "\n${BIGreen}$1${Color_Off}"
}

print_error() {
  echo -e "\n${BIRed}$1${Color_Off}"
}

check_dependencies() {
    echo -e "${BIWhite}Checking for required dependencies...${Color_Off}"
    local dependencies=("pacman-contrib" "reflector")
    local aur_helper_found=0
    local aur_helpers=("yay" "paru")

    for dep in "${dependencies[@]}"; do
        if ! pacman -Q "$dep" &>/dev/null; then
            print_error "Dependency '$dep' is not installed. Installing now..."
            pacman -S --noconfirm "$dep"
            if [ $? -ne 0 ]; then
                print_error "Failed to install '$dep'. Exiting."
                exit 1
            fi
        fi
    done

    for helper in "${aur_helpers[@]}"; do
        if command -v "$helper" &>/dev/null; then
            AUR_HELPER="$helper"
            aur_helper_found=1
            break
        fi
    done

    if [ "$aur_helper_found" -eq 0 ]; then
        print_error "No AUR helper (yay or paru) found. Installing 'yay' now."
        print_error "This may require manual intervention. Please follow the instructions."
        if ! pacman -S --noconfirm base-devel git; then
            print_error "Failed to install base-devel and git. Please install them manually."
            exit 1
        fi
        mkdir -p "$HOME/AUR_builds"
        cd "$HOME/AUR_builds" || { print_error "Failed to create/change to AUR build directory."; exit 1; }
        git clone https://aur.archlinux.org/yay.git
        cd yay || { print_error "Failed to clone/change to yay directory."; exit 1; }
        makepkg -si --noconfirm
        if [ $? -ne 0 ]; then
            print_error "Failed to install yay. Please install an AUR helper manually."
            exit 1
        fi
        cd - >/dev/null || exit
        AUR_HELPER="yay"
    fi
    print_success "All dependencies are installed."
}

update_system() {
    print_success "Starting system update..."
    pacman -Syu --noconfirm
    if [ $? -eq 0 ]; then
        print_success "System update complete."
    else
        print_error "System update failed."
    fi
}

update_aur() {
    if [ -z "$AUR_HELPER" ]; then
        print_error "No AUR helper detected. Cannot update AUR packages."
        return
    fi
    print_success "Starting AUR package update with $AUR_HELPER..."
    "$AUR_HELPER" -Syu --noconfirm
    if [ $? -eq 0 ]; then
        print_success "AUR package update complete."
    else
        print_error "AUR package update failed."
    fi
}

clean_cache_interactive() {
    print_success "Starting interactive package cache cleanup..."
    echo -e "${BIWhite}Enter the number of recent package versions you want to keep per package.${Color_Off}"
    echo -e "${BIWhite}A value of '1' is safe and recommended. '0' will remove all old versions.${Color_Off}"
    echo -n "Number of versions to keep: "
    read -r keep_num
    if ! [[ "$keep_num" =~ ^[0-9]+$ ]]; then
        print_error "Invalid input. Please enter a number."
        return
    fi
    echo -e "${BIWhite}Cleaning up package cache, keeping $keep_num versions...${Color_Off}"
    paccache -rk"$keep_num"
    paccache -ruk0
    if [ $? -eq 0 ]; then
        print_success "Package cache cleaned."
    else
        print_error "Failed to clean package cache."
    fi
}

remove_orphans() {
    local orphans
    orphans=$(pacman -Qtdq)
    if [ -n "$orphans" ]; then
        print_success "Found the following packages that are no longer needed (orphans):\n$orphans"
        echo -e "${BIWhite}These packages are safe to remove. This will free up disk space.${Color_Off}"
        read -p "Do you want to remove them? (y/n) " choice
        if [[ "$choice" =~ ^[Yy]$ ]]; then
            pacman -Rns "$orphans" --noconfirm
            if [ $? -eq 0 ]; then
                print_success "Orphan packages removed."
            else
                print_error "Failed to remove orphan packages."
            fi
        else
            echo "Skipping orphan package removal."
        fi
    else
        print_success "No orphan packages found."
    fi
}

clean_journal_logs() {
    print_success "Cleaning up old journal logs..."
    echo -e "${BIWhite}This will reduce journal size by keeping only the last 100MB of data.${Color_Off}"
    read -p "Proceed with cleaning journal logs? (y/n) " choice
    if [[ "$choice" =~ ^[Yy]$ ]]; then
        journalctl --vacuum-size=100M
        if [ $? -eq 0 ]; then
            print_success "Journal logs cleaned."
        else
            print_error "Failed to clean journal logs."
        fi
    else
        echo "Skipping journal log cleanup."
    fi
}

clean_thumbnails() {
    print_success "Cleaning up thumbnail cache..."
    echo -e "${BIWhite}This will remove all stored thumbnails, which can save a significant amount of disk space.${Color_Off}"
    read -p "Proceed with clearing thumbnail cache? (y/n) " choice
    if [[ "$choice" =~ ^[Yy]$ ]]; then
        rm -rf ~/.cache/thumbnails/*
        if [ $? -eq 0 ]; then
            print_success "Thumbnail cache cleared."
        else
            print_error "Failed to clear thumbnail cache."
        fi
    else
        echo "Skipping thumbnail cache cleanup."
    fi
}

check_pacdiff() {
    print_success "Checking for new .pacnew configuration files..."
    echo -e "${BIWhite}This will launch 'pacdiff' to help you merge configuration files.${Color_Off}"
    read -p "Proceed with checking for .pacnew files? (y/n) " choice
    if [[ "$choice" =~ ^[Yy]$ ]]; then
        if ! pacdiff -o &>/dev/null; then
            echo "No .pacnew files found. Everything is up to date."
        else
            pacdiff
            print_success ".pacnew check complete."
        fi
    else
        echo "Skipping .pacnew check."
    fi
}

check_failed_units() {
    print_success "Checking for failed systemd units..."
    if systemctl --failed --quiet; then
        print_success "No failed systemd units found. Your system is running smoothly."
    else
        print_error "The following systemd units have failed:"
        systemctl --failed
        echo -e "${BIWhite}You can use 'journalctl -xe' to get more information on a specific unit.${Color_Off}"
    fi
}

update_mirrors_interactive() {
    print_success "Starting interactive mirror list update..."
    echo -e "${BIWhite}This will use 'reflector' to find the 20 fastest mirrors and update your mirror list.${Color_Off}"
    echo -e "${BIWhite}This is a crucial step for getting the fastest update speeds.${Color_Off}"
    read -p "Proceed with updating the mirror list? (y/n) " choice
    if [[ "$choice" =~ ^[Yy]$ ]]; then
        reflector --verbose --latest 20 --sort rate --save /etc/pacman.d/mirrorlist
        if [ $? -eq 0 ]; then
            print_success "Mirror list updated. It is highly recommended to run a system update now."
        else
            print_error "Failed to update mirror list with reflector."
        fi
    else
        echo "Skipping mirror list update."
    fi
}

select_option() {
    local options=("$@")
    local num_options=${#options[@]}
    local selected=0
    
    local BCyan_BG_Black="$(tput setab 6; tput setaf 0)"
    echo -e "${BIWhite}Please select an option using the arrow keys and Enter:${Color_Off}"
    for i in "${!options[@]}"; do
        if [ "$i" -eq $selected ]; then
            echo -e "${BCyan_BG_Black} > ${options[$i]} ${Color_Off}"
        else
            echo -e "${BYellow}   ${options[$i]} ${Color_Off}"
        fi
    done
    while true; do
        tput cuu "${num_options}"
        for i in "${!options[@]}"; do
            tput el
            if [ "$i" -eq $selected ]; then
                echo -e "${BCyan_BG_Black} > ${options[$i]} ${Color_Off}"
            else
                echo -e "${BYellow}   ${options[$i]} ${Color_Off}"
            fi
        done
        read -rsn1 key
        case "$key" in
            $'\x1b') 
                read -rsn2 -t 0.1 key
                case "$key" in
                    '[A')
                        ((selected--))
                        if [ $selected -lt 0 ]; then
                            selected=$((num_options - 1))
                        fi
                        ;;
                    '[B')
                        ((selected++))
                        if [ $selected -ge $num_options ]; then
                            selected=0
                        fi
                        ;;
                esac
                ;;
            '')
                echo
                break
                ;;
        esac
    done
    return $selected
}

main() {
    if [ "$(id -u)" -ne 0 ]; then
        print_error "This script must be run as root. Please use 'sudo ./maintenance.sh'."
        exit 1
    fi
    check_dependencies
    
    options=(
        "Full System Upgrade (pacman & AUR)"
        "Update System (pacman only)"
        "Update AUR Packages (with yay/paru)"
        "Clean Package Cache (Interactive)"
        "Remove Orphan Packages"
        "Clean Journal Logs"
        "Clean Thumbnail Cache"
        "Check for .pacnew files (with pacdiff)"
        "Check for Failed Systemd Units"
        "Update Pacman Mirrors (Interactive)"
        "Exit"
    )
    
    while true; do
        select_option "${options[@]}"
        local choice_index=$?
        
        case "$choice_index" in
            0)
                update_system
                update_aur
                ;;
            1)
                update_system
                ;;
            2)
                update_aur
                ;;
            3)
                clean_cache_interactive
                ;;
            4)
                remove_orphans
                ;;
            5)
                clean_journal_logs
                ;;
            6)
                clean_thumbnails
                ;;
            7)
                check_pacdiff
                ;;
            8)
                check_failed_units
                ;;
            9)
                update_mirrors_interactive
                ;;
            10)
                print_success "Exiting script."
                exit 0
                ;;
        esac
        
        echo -e "${BYellow}Press Enter to return to the menu...${Color_Off}"
        read -r
    done
}

main
