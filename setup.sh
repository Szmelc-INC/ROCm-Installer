#!/bin/bash

# This is an effortless ROCm / AMDGPU-DKMS script
# It comes pre-packaged with dependencies (mainly libpython3.10)
# Full installation will take 30GB+ on your root partition!
# https://rocm.docs.amd.com/projects/install-on-linux/en/latest/how-to/native-install/ubuntu.html

# In case some ubuntu servers fail again and .deb will be missing or unavailable, 
# user will be able to optionally download them from my repo i made for safekeeping
# https://github.com/GNU-Szmelc/ROCm-Installer

# List of URLs for .deb dependencies
DEB_URLS=(
    "http://security.ubuntu.com/ubuntu/pool/main/p/python3.10/libpython3.10_3.10.12-1~22.04.3_amd64.deb"
    "http://security.ubuntu.com/ubuntu/pool/main/p/python3.10/libpython3.10-stdlib_3.10.12-1~22.04.3_amd64.deb"
    "http://de.archive.ubuntu.com/ubuntu/pool/main/m/mpdecimal/libmpdec3_2.5.1-2build2_amd64.deb"
    "http://security.ubuntu.com/ubuntu/pool/main/p/python3.10/libpython3.10-minimal_3.10.12-1~22.04.3_amd64.deb"
)

clear && cat <<EOF

 /******************************************************************/
 /*                                                                */
 /*   mm   m    m mmmm          mmmmm   mmmm    mmm                */
 /*   ##   ##  ## #   "m        #   "# m"  "m m"   " mmmmm         */
 /*  #  #  # ## # #    #        #mmmm" #    # #      # # #         */
 /*  #mm#  # "" # #    #        #   "m #    # #      # # #         */
 /* #    # #    # #mmm"         #    "  #mm#   "mmm" # # #         */
 /*                                                                */
 /*  mmmmm                  m           ""#    ""#                 */
 /*   #    m mm    mmm   mm#mm   mmm     #      #     mmm    m mm  */
 /*   #    #"  #  #   "    #    "   #    #      #    #"  #   #"  " */
 /*   #    #   #   """m    #    m"""#    #      #    #""""   #     */
 /* mm#mm  #   #  "mmm"    "mm  "mm"#    "mm    "mm  "#mm"   #     */
 /*                                                                */
 /******************************************************************/
   By $x66
   
EOF

# Welcome screen and warning text
echo "Welcome to the ROCm / AMDGPU-DKMS installation script"
echo "This script will install ROCm and AMDGPU-DKMS on your system."
echo "The full installation will take 30GB+ on your root partition."
read -p "Do you want to continue? [Y/n] " response
response=${response,,} # tolower
if [[ "$response" == "n" ]]; then
    echo "Installation aborted by user."
    exit 0
fi

# Prompt for sudo password
sudo -v

# Check for free space on root partition
REQUIRED_SPACE_GB=30
AVAILABLE_SPACE_GB=$(df / --output=avail / | tail -n1 | awk '{print int($1/1024/1024)}')

if [[ $AVAILABLE_SPACE_GB -lt $REQUIRED_SPACE_GB ]]; then
    echo "Error: Not enough free space on root partition. Please free up some space."
    echo "Required: ${REQUIRED_SPACE_GB}GB, Available: ${AVAILABLE_SPACE_GB}GB"
    exit 1
fi

# Define log file
LOGFILE=~/Desktop/ROCm-log.txt

# Redirect all output to log file
exec > >(tee -i $LOGFILE)
exec 2>&1

# Start in user's home directory
cd ~

# Package signing keys
echo "Creating /etc/apt/keyrings directory and setting mode"
sudo mkdir --parents --mode=0755 /etc/apt/keyrings

echo "Downloading and installing ROCm GPG key"
wget https://repo.radeon.com/rocm/rocm.gpg.key -O - | gpg --dearmor | sudo tee /etc/apt/keyrings/rocm.gpg > /dev/null

# Register kernel-mode driver
echo "Registering kernel-mode driver"
echo "deb [arch=amd64 signed-by=/etc/apt/keyrings/rocm.gpg] https://repo.radeon.com/amdgpu/6.1.2/ubuntu jammy main" | sudo tee /etc/apt/sources.list.d/amdgpu.list
sudo apt update

# Register ROCm package
echo "Registering ROCm package"
echo "deb [arch=amd64 signed-by=/etc/apt/keyrings/rocm.gpg] https://repo.radeon.com/rocm/apt/6.1.2 jammy main" | sudo tee --append /etc/apt/sources.list.d/rocm.list
echo -e 'Package: *\nPin: release o=repo.radeon.com\nPin-Priority: 600' | sudo tee /etc/apt/preferences.d/rocm-pin-600
sudo apt update

# Download .deb dependencies
echo "Downloading .deb dependencies"
mkdir -p ~/ROCm-Installer
cd ~/ROCm-Installer
DOWNLOAD_FAILED=false

for url in "${DEB_URLS[@]}"; do
    wget "$url" || DOWNLOAD_FAILED=true
done

# Check if all .deb files are downloaded
for url in "${DEB_URLS[@]}"; do
    filename=$(basename "$url")
    if [[ ! -f "$filename" ]]; then
        DOWNLOAD_FAILED=true
        break
    fi
done

if $DOWNLOAD_FAILED; then
    read -p "Some Ubuntu mirrors for dependencies have failed us, do you wish to get them from my GitHub repo? [Y/n] " response
    response=${response,,} # tolower
    if [[ "$response" == "n" ]]; then
        read -p "Continue regardless? (It might, and probably will fail...) [N/y] " continue_response
        continue_response=${continue_response,,} # tolower
        if [[ "$continue_response" == "y" ]]; then
            echo "Continuing with the script..."
        else
            echo "Installation aborted by user."
            exit 0
        fi
    else
        echo "Cloning ROCm-Installer repository"
        git clone https://github.com/GNU-Szmelc/ROCm-Installer.git
        cd ROCm-Installer

        echo "Extracting libpython3.10 dependencies"
        tar -xvzf libpython3.10.tar.gz
    fi
fi

# Installing .deb dependencies
echo "Installing .deb dependencies"
sudo dpkg -i *.deb

# Install kernel driver & ROCm
echo "Installing amdgpu-dkms and ROCm"
sudo apt install -y amdgpu-dkms rocm

# Optional: Install PyTorch
read -p "Install PyTorch as well? (Another 5GB Required) [Y/n] " pytorch_response
pytorch_response=${pytorch_response,,} # tolower
if [[ "$pytorch_response" != "n" ]]; then
    REQUIRED_SPACE_GB=5
    AVAILABLE_SPACE_GB=$(df / --output=avail / | tail -n1 | awk '{print int($1/1024/1024)}')
    if [[ $AVAILABLE_SPACE_GB -lt $REQUIRED_SPACE_GB ]]; then
        echo "Error: Not enough free space on root partition for PyTorch. Please free up some space."
        echo "Required: ${REQUIRED_SPACE_GB}GB, Available: ${AVAILABLE_SPACE_GB}GB"
        exit 1
    else
        echo "Installing PyTorch"
        pip3 install torch torchvision torchaudio --index-url https://download.pytorch.org/whl/rocm6.0
    fi
fi

# Initialize modules
echo "Initializing modules"
sudo modprobe amdgpu

# Verify installation
echo "==========================="
rocm-smi --version
python3 -c "import torch; print(torch.__version__)"
echo "==========================="

# Clean & Reboot when complete
echo "Cleaning up and rebooting"
cd ~
rm -fr ~/ROCm-Installer
sudo reboot
