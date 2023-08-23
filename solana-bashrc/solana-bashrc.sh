#!/bin/bash

# Define colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
NC='\033[0m' # No Color

# Function to show help message
show_help() {
    echo -e "${YELLOW}Usage: $0 [OPTION]${NC}"
    echo "Options:"
    echo "--help              Display help information."
    echo "--display-all       Display active .bashrc aliases."
    echo "--uninstall         Remove added configurations."
    echo "--reload-bash       Reload .bashrc."
}

# Validate if the pubkey is correctly formed (simplified to length check)
validate_pubkey() {
    if [[ ${#1} -ne 43 ]]; then
        echo -e "${RED}Invalid pubkey. Please enter a valid pubkey.${NC}"
        exit 1
    fi
}

# Main function to add configurations
add_config() {
    # Backup .bashrc
    cp ~/.bashrc ~/.bashrc-backup
    echo -e "${GREEN}.bashrc backed up to .bashrc-backup.${NC}"

    read -p "Enter the Solana validator pubkey: " validator_pubkey
    validate_pubkey $validator_pubkey
    read -p "Enter the Solana vote pubkey: " vote_pubkey
    validate_pubkey $vote_pubkey
    read -p "Enter the prefix for bashrc alias: " prefix
    echo "Select choices (comma separated or 'ALL'): ledger, catchup, watch, vote, stake, leader_schedule"
    read -p "Your choice: " selected_choices

    if [[ "$selected_choices" == "ALL" ]]; then
        selected_choices="ledger,catchup,watch,vote,stake,leader_schedule"
    fi

    IFS=',' read -ra choices <<< "$selected_choices"
    added_count=0

    for choice in "${choices[@]}"; do
        choice=$(echo $choice | tr -d ' ') # Remove potential spaces
        case $choice in
            ledger)
                read -p "Enter the ledger path: " ledger_path
                echo "alias ${prefix}_ledger='solana-validator --ledger $ledger_path monitor'" >> ~/.bashrc
                added_count=$((added_count+1))
                ;;
            catchup)
                echo "alias ${prefix}_catch='solana catchup $validator_pubkey --our-localhost'" >> ~/.bashrc
                added_count=$((added_count+1))
                ;;
            watch)
                echo "alias ${prefix}_watch='solana-watchtower --monitor-active-stake --validator-identity $validator_pubkey'" >> ~/.bashrc
                added_count=$((added_count+1))
                ;;
            vote)
                echo "alias ${prefix}_vote='solana vote-account $vote_pubkey'" >> ~/.bashrc
                added_count=$((added_count+1))
                ;;
            stake)
                echo "alias ${prefix}_stake='solana stakes $vote_pubkey'" >> ~/.bashrc
                added_count=$((added_count+1))
                ;;
            leader_schedule)
                echo "alias ${prefix}_leader_schedule='solana leader-schedule | grep $validator_pubkey | wc -l'" >> ~/.bashrc
                added_count=$((added_count+1))
                ;;
            *)
                echo -e "${RED}Invalid choice: $choice${NC}"
                ;;
        esac
    done

    # Ask for reload option
    read -p "Do you want to reload .bashrc now? (yes/no): " reload_choice
    if [[ "$reload_choice" == "yes" ]]; then
        source ~/.bashrc
        echo -e "${GREEN}.bashrc reloaded!${NC}"
    else
        echo -e "${YELLOW}To reload .bashrc manually later, execute: source ~/.bashrc${NC}"
    fi

    echo -e "${GREEN}Configurations added!${NC}"
    echo -e "Status: ${GREEN}$added_count of ${#choices[@]}${NC}"
}

# Function to remove added configurations
uninstall() {
    if [[ -f ~/.bashrc-backup ]]; then
        mv ~/.bashrc-backup ~/.bashrc
        echo -e "${GREEN}Removed custom configurations. .bashrc restored from backup.${NC}"
    else
        echo -e "${RED}.bashrc-backup not found!${NC}"
    fi
}

# Display all active aliases in .bashrc
display_all() {
    grep '^alias' ~/.bashrc
}

# Handle the script options
case "$1" in
    --help)
        show_help
        ;;
    --display-all)
        display_all
        ;;
    --uninstall)
        uninstall
        ;;
    --reload-bash)
        source ~/.bashrc
        echo -e "${GREEN}.bashrc reloaded!${NC}"
        ;;
    *)
        add_config
        ;;
esac
