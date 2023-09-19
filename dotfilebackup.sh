#!/bin/bash

# Define the backup directory path
backup_dir="$HOME/dotfile_backups"

# Create the backup directory if it doesn't exist
mkdir -p "$backup_dir"

# List of dotfiles to exclude from the backup
exclude_dotfiles=(
    ~/.ssh/authorized_keys
    ~/.bash_history
    ~/.gnupg/
    ~/.aws/config
    ~/.aws/credentials
    ~/.netrc
    ~/.docker/config.json
    ~/.kube/config
    ~/.npmrc
    ~/.yarnrc
    # Add more dotfiles to exclude here
)

# Function to copy dotfiles, including the original path
copy_dotfiles() {
    for dotfile in /home/*/*; do
        # Check if the file has a dot at the beginning of its name (a dotfile)
        if [[ "$dotfile" == "$HOME/.*" ]] && [ -f "$dotfile" ] && ! [[ "${exclude_dotfiles[@]}" =~ "$dotfile" ]]; then
            # Calculate the relative path from the user's home directory
            rel_path="${dotfile#"$HOME/"}"

            # Create the target directory structure in the backup directory
            target_dir="$backup_dir/$(dirname "$rel_path")"
            mkdir -p "$target_dir"

            # Copy the dotfile to the corresponding backup directory
            echo "Copying $dotfile to $target_dir/"
            cp "$dotfile" "$target_dir/"
        fi
    done
}

copy_dotfiles

echo "Dotfile backup complete. Dotfiles from the system are copied to $backup_dir."
