#!/bin/bash
# Display ASCII Art Banner
cat << "EOF"

██████╗ ██╗███████╗██╗  ██╗    ████████╗ ██████╗  ██████╗ ██╗     
██╔══██╗██║██╔════╝██║ ██╔╝    ╚══██╔══╝██╔═══██╗██╔═══██╗██║     
██║  ██║██║███████╗█████╔╝        ██║   ██║   ██║██║   ██║██║     
██║  ██║██║╚════██║██╔═██╗        ██║   ██║   ██║██║   ██║██║     
██████╔╝██║███████║██║  ██╗       ██║   ╚██████╔╝╚██████╔╝███████╗
╚═════╝ ╚═╝╚══════╝╚═╝  ╚═╝       ╚═╝    ╚═════╝  ╚═════╝ ╚══════╝
EOF
# 1. IDENTIFY
echo "--- Scanning for Removable Disks ---"
lsblk -o NAME,SIZE,TYPE,TRAN,LABEL | grep 'usb'
echo "------------------------------------"

# 2. SELECT DISK
read -p "Enter the disk name to target (e.g., sda): " DISK_NAME
TARGET="/dev/$DISK_NAME"

if [ ! -b "$TARGET" ]; then
    echo "Error: Device $TARGET not found."
    exit 1
fi

# 3. SELECT ACTION
echo "Select Action for $TARGET:"
echo "1) Format as FAT32 (Universal)"
echo "2) Format as exFAT (Large Files)"
echo "3) Create Bootable Drive (Flash ISO)"
echo "4) Deep Wipe (Fix Stubborn Drive)"
read -p "Choice [1-4]: " ACTION

# --- SAFETY CONFIRMATION ---
read -p "WARNING: All data on $TARGET will be destroyed. Proceed? (y/N): " CONFIRM
if [[ ! "$CONFIRM" =~ ^[yY]$ ]]; then
    echo "Operation cancelled."
    exit 1
fi

# 4. EXECUTION
case $ACTION in
    1)
        read -p "Enter volume name (Label): " VOL_NAME
        echo "Formatting $TARGET as FAT32 with label: $VOL_NAME..."
        sudo umount ${TARGET}* 2>/dev/null
        sudo parted $TARGET mklabel msdos
        sudo parted -a optimal $TARGET mkpart primary fat32 0% 100%
        sudo mkfs.vfat -F 32 -n "$VOL_NAME" ${TARGET}1
        ;;
    2)
        read -p "Enter volume name (Label): " VOL_NAME
        echo "Formatting $TARGET as exFAT with label: $VOL_NAME..."
        sudo umount ${TARGET}* 2>/dev/null
        sudo parted $TARGET mklabel gpt
        sudo parted -a optimal $TARGET mkpart primary exfat 0% 100%
        sudo mkfs.exfat -n "$VOL_NAME" ${TARGET}1
        ;;
    3)
        read -p "Enter path to ISO file: " ISO_PATH
        echo "Flashing $ISO_PATH to $TARGET..."
        sudo dd if="$ISO_PATH" of="$TARGET" bs=4M status=progress conv=fsync
        ;;
    4)
        echo "Performing Deep Wipe on $TARGET..."
        sudo wipefs -a "$TARGET"
        sudo dd if=/dev/zero of="$TARGET" bs=1M count=100
        echo "Wipe complete. Unplug and replug the drive now."
        ;;
    *)
        echo "Invalid selection."
        exit 1
        ;;
esac

sync
echo "Operation completed successfully."
