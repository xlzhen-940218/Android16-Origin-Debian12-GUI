#!/bin/bash

# ====================================================================================
# Debian 12 (bookworm) to Debian 13 (trixie) upgrade script
#
# Notes:
# 1. This script assumes you are upgrading from Debian 12 to Debian 13. If you are on Debian 11, upgrade to Debian 12 first.
# 2. Make sure you have backed up important data before running this script.
# 3. During the upgrade you may be prompted to choose configuration options; typically choose “keep the current configuration” and “restart services”.
# 4. This script only handles the operating system itself; applications may require additional manual steps.
# ====================================================================================

# Check current Debian version
if ! grep -q "bookworm" /etc/os-release; then
    echo "Error: The current system is not Debian 12 (bookworm). This script is only for upgrading from Debian 12."
    exit 1
fi

echo "🚀 Starting upgrade from Debian 12 (bookworm) to Debian 13 (trixie)..."

# Step 1: Check disk space
echo "--- 1. Check available disk space ---"
df -h
echo "It is recommended to have at least 5GiB of free space. If space is insufficient, use 'sudo apt clean' and 'sudo apt autoremove' to clean up."
read -p "Press Enter to continue..."

# Step 2: Update current system
echo "--- 2. Update the current release ---"
sudo apt update && sudo apt full-upgrade -y

# Check whether a reboot is required (e.g., if the kernel was updated)
if [ -f /var/run/reboot-required ]; then
    echo "--- A reboot is required. The system will reboot in 10 seconds... ---"
    sudo reboot
    # The script will be restarted after reboot to continue
    # If it does not continue automatically after reboot, you will need to run it again manually
    exit 0
fi

# Step 3: Modify /etc/apt/sources.list
echo "--- 3. Switch main repositories to trixie ---"
sudo sed -i 's/bookworm/trixie/g' /etc/apt/sources.list
echo "Repositories have been changed from 'bookworm' to 'trixie'."

# Step 4: Check and modify third-party repositories
echo "--- 4. Check and modify third-party repositories ---"
if [ -d "/etc/apt/sources.list.d" ]; then
    echo "Replacing 'bookworm' with 'trixie' in all third-party repository files..."
    find /etc/apt/sources.list.d -type f -exec sed -i 's/bookworm/trixie/g' {} \;
    echo "Third-party repositories updated."
else
    echo "No third-party repository directory found: /etc/apt/sources.list.d."
fi

# Step 5: Refresh repository lists
echo "--- 5. Reload repository lists ---"
sudo apt update

# Check and handle 'non-free' and 'non-free-firmware'
if grep -q "non-free" /etc/apt/sources.list && ! grep -q "non-free-firmware" /etc/apt/sources.list; then
    echo "--- ❗ Warning: 'non-free' was detected but 'non-free-firmware' is missing. ---"
    echo "'non-free' has been split after Debian 12. It is recommended that you add 'non-free-firmware'."
    echo "You can manually edit /etc/apt/sources.list or handle it after the upgrade."
fi

# Step 6: Install screen (optional)
echo "--- 6. Install screen (optional, recommended when running over SSH) ---"
read -p "Install and use screen to prevent disconnect issues? (y/n) " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    sudo apt install -y screen
    echo "Please run the rest of this script inside screen, for example: 'screen -S upgrade_session ./upgrade.sh'"
    echo "Exiting now. Please re-run the script manually."
    exit 0
fi

# Step 7: Perform upgrade
echo "--- 7. Perform full distribution upgrade ---"
echo "Watch the prompts during the upgrade. It is recommended to choose 'keep the current configuration files'."
sudo apt full-upgrade -y

# Step 8: Clean old packages
echo "--- 8. Clean old packages ---"
sudo apt autoremove -y && sudo apt clean

# Step 9: Modernize sources.list (optional but recommended)
echo "--- 9. Modernize sources.list (optional but recommended) ---"
read -p "Convert sources.list to deb822 format? (y/n) " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    sudo apt modernize-sources
    echo "sources.list has been updated to deb822 format."
fi

# Step 10: Reboot to complete upgrade
echo "--- 10. Upgrade completed. The system will reboot in 10 seconds to apply all changes. ---"
sudo reboot
