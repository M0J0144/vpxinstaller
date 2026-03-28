#!/bin/bash

# Fetch latest release URLs dynamically
VPX_URL=$(curl -s https://api.github.com/repos/vpinball/vpinball/releases/latest | grep "browser_download_url.*linux-x64.zip" | cut -d '"' -f 4)
VPXTOOL_URL=$(curl -s https://api.github.com/repos/francisdb/vpxtool/releases/latest | grep "browser_download_url.*linux-x86_64.*\.tar\.gz" | cut -d '"' -f 4)

# Prompt user for installation directory or use default
default_dir="$HOME/VPinballX"
echo "Enter installation directory (Press enter to use default: $default_dir):"
read install_dir
INSTALL=${install_dir:-$default_dir}

# Prompt user for PinMAME directory
default_pinmame_dir="$HOME/.pinmame"
echo "Choose path for PinMAME: ($default_pinmame_dir) or local ($INSTALL/tables/pinmame)? (g/l, default: g):"
read pinmame_choice
if [[ "$pinmame_choice" == "l" ]]; then
    PINMAME="$INSTALL/tables/pinmame"
else
    PINMAME="$default_pinmame_dir"
fi

# Create the installation and PinMAME directory
mkdir -p "$INSTALL"
mkdir -p "$PINMAME/roms"
mkdir -p "$PINMAME/ini"

# Download and extract Visual Pinball X
echo "Downloading Visual Pinball X..."
wget -O /tmp/vpx.zip "$VPX_URL"
echo "Extracting zip file..."
unzip -o /tmp/vpx.zip -d /tmp/vpx_extracted

# Create directory for tar.gz extraction
mkdir -p /tmp/vpx_extracted_contents

echo "Extracting tar.gz file..."
tar -xzf /tmp/vpx_extracted/*.tar.gz -C /tmp/vpx_extracted_contents

echo "Moving extracted files..."
mv /tmp/vpx_extracted_contents/* "$INSTALL"
rm -r /tmp/vpx.zip /tmp/vpx_extracted /tmp/vpx_extracted_contents

echo "Visual Pinball X installed to $INSTALL"

# Run VPinballX_GL to configure VPX
echo "Configuring Visual Pinball X..."
cd "$INSTALL" && ./VPinballX_GL

# Download and extract vpxtool
echo "Downloading vpxtool..."
wget -O /tmp/vpxtool.tar.gz "$VPXTOOL_URL"
echo "Extracting..."
tar -xzf /tmp/vpxtool.tar.gz -C "$INSTALL"
rm /tmp/vpxtool.tar.gz

echo "Running vpxtool setup..."
cd "$INSTALL" && chmod +x ./vpxtool && ./vpxtool config setup

echo "vpxtool installed and configured."

# Create an uninstall script
echo "Creating uninstall script..."
cat <<EOL > "$INSTALL/uninstall.sh"
#!/bin/bash

echo "WARNING - The following paths will be removed:"
echo "$INSTALL"
echo "$PINMAME"
echo "$HOME/.config/vpxtool.cfg"
echo "$HOME/.vpinball"

read -p "Are you sure you want to uninstall Visual Pinball X and vpxtool? (y/n): " confirm
if [[ "\$confirm" != "y" ]]; then
    echo "Uninstallation cancelled."
    exit 1
fi

echo "Proceeding with uninstallation..."
rm -rf "$INSTALL" "$PINMAME" "$HOME/.config/vpxtool" "$HOME/.vpinball"
read -p "Uninstallation complete!"
EOL
chmod +x "$INSTALL/uninstall.sh"

# Create launch script for vpxtool
LAUNCH_SCRIPT="$INSTALL/launch.sh"
echo "Creating launch script..."
cat <<EOL > "$LAUNCH_SCRIPT"
#!/bin/bash
konsole -e "./vpxtool frontend"
EOL
chmod +x "$LAUNCH_SCRIPT"

echo "Launch script created at $LAUNCH_SCRIPT. This script can be added to Steam."

# Display completion message
read -p "Installation complete!"