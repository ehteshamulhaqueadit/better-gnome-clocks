#!/bin/bash
# Quick setup script for Better GNOME Clocks

set -e  # Exit on error

echo "========================================"
echo "Better GNOME Clocks - Quick Setup"
echo "========================================"
echo ""

# Check if running in project directory
if [ ! -f "meson.build" ]; then
    echo "Error: Please run this script from the better-gnome-clocks directory"
    exit 1
fi

# Function to check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Check dependencies
echo "Checking dependencies..."
MISSING_DEPS=0

check_dep() {
    if ! command_exists "$1"; then
        echo "  ✗ $1 not found"
        MISSING_DEPS=1
    else
        echo "  ✓ $1 found"
    fi
}

check_dep meson
check_dep ninja
check_dep valac
check_dep paplay

if [ $MISSING_DEPS -eq 1 ]; then
    echo ""
    echo "Missing dependencies detected!"
    echo "Please install them using your package manager:"
    echo ""
    
    if command_exists apt; then
        echo "  Ubuntu/Debian:"
        echo "  sudo apt install meson valac libgtk-4-dev libadwaita-1-dev \\"
        echo "      libgweather-4-dev libgnome-desktop-4-dev libgeoclue-2-dev \\"
        echo "      libgeocode-glib-dev gsound-dev pulseaudio"
    elif command_exists dnf; then
        echo "  Fedora:"
        echo "  sudo dnf install meson vala gtk4-devel libadwaita-devel \\"
        echo "      libgweather4-devel gnome-desktop4-devel geoclue2-devel \\"
        echo "      geocode-glib-devel gsound-devel pulseaudio"
    elif command_exists pacman; then
        echo "  Arch Linux:"
        echo "  sudo pacman -S meson vala gtk4 libadwaita libgweather-4 \\"
        echo "      gnome-desktop-4 geoclue geocode-glib gsound pulseaudio"
    fi
    echo ""
    echo "For more details, see INSTALL.md"
    exit 1
fi

echo ""
echo "All dependencies found!"
echo ""

# Ask what to do
echo "What would you like to do?"
echo "  1) Build and run (without installing)"
echo "  2) Build and install system-wide"
echo "  3) Just build"
echo ""
read -p "Enter choice [1-3]: " choice

case $choice in
    1)
        echo ""
        echo "Building Better GNOME Clocks..."
        if [ -d "build" ]; then
            echo "Removing old build directory..."
            rm -rf build/
        fi
        
        meson build
        ninja -C build
        
        echo ""
        echo "Build complete! Creating run script..."
        
        cat > run.sh << 'EOF'
#!/bin/bash
cd "$(dirname "$0")"
glib-compile-schemas build/data
env GSETTINGS_SCHEMA_DIR=build/data:/usr/share/glib-2.0/schemas \
    XDG_DATA_DIRS=build/share:/usr/share \
    ./build/src/gnome-clocks "$@"
EOF
        chmod +x run.sh
        
        echo ""
        echo "✓ Setup complete!"
        echo ""
        echo "To run Better GNOME Clocks:"
        echo "  ./run.sh"
        echo ""
        ;;
        
    2)
        echo ""
        echo "Building Better GNOME Clocks..."
        if [ -d "build" ]; then
            echo "Removing old build directory..."
            rm -rf build/
        fi
        
        meson build
        ninja -C build
        
        echo ""
        echo "Installing system-wide (requires sudo)..."
        sudo ninja -C build install
        sudo glib-compile-schemas /usr/local/share/glib-2.0/schemas/
        sudo update-desktop-database 2>/dev/null || true
        
        echo ""
        echo "✓ Installation complete!"
        echo ""
        echo "You can now run 'gnome-clocks' from your application menu"
        echo "or from terminal: gnome-clocks"
        echo ""
        ;;
        
    3)
        echo ""
        echo "Building Better GNOME Clocks..."
        if [ -d "build" ]; then
            echo "Removing old build directory..."
            rm -rf build/
        fi
        
        meson build
        ninja -C build
        
        echo ""
        echo "✓ Build complete!"
        echo ""
        echo "Binary location: ./build/src/gnome-clocks"
        echo ""
        echo "To run:"
        echo "  glib-compile-schemas build/data"
        echo "  env GSETTINGS_SCHEMA_DIR=build/data:/usr/share/glib-2.0/schemas \\"
        echo "      XDG_DATA_DIRS=build/share:/usr/share \\"
        echo "      ./build/src/gnome-clocks"
        echo ""
        ;;
        
    *)
        echo "Invalid choice. Exiting."
        exit 1
        ;;
esac

echo "For help and documentation, see:"
echo "  - README.md        - Overview and usage"
echo "  - INSTALL.md       - Detailed installation guide"
echo "  - RELEASE_NOTES.md - What's new in this version"
echo ""
echo "Enjoy Better GNOME Clocks!"
